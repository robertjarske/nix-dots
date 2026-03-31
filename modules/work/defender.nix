{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.mdatp;
  mdatp = pkgs.callPackage ../../pkgs/mdatp.nix {};

  # wdavdaemon checks for /opt/microsoft/mdatp at runtime.
  # This script creates the expected symlink before the daemon starts.
  preStartScript = pkgs.writeShellScript "mdatp-prestart" ''
    set -euo pipefail
    INSTALL=/opt/microsoft/mdatp
    mkdir -p /opt/microsoft
    if [[ -L $INSTALL && $(readlink $INSTALL) == ${mdatp} ]]; then
      exit 0
    fi
    rm -f $INSTALL
    ln -s ${mdatp} $INSTALL
  '';

  # Wait for mdatp to report healthy before setting the tag.
  # Exits 0 regardless so activation is never blocked.
  setGroupTagScript = pkgs.writeShellScript "mdatp-set-group-tag" ''
    for i in $(seq 1 24); do
      if ${mdatp}/bin/mdatp health --field healthy 2>/dev/null | grep -q '^true$'; then
        ${mdatp}/bin/mdatp edr tag set --name GROUP --value ${cfg.groupTag}
        exit 0
      fi
      sleep 5
    done
    echo "mdatp not healthy after 2 minutes, skipping group tag" >&2
    exit 0
  '';
in {
  options.services.mdatp = {
    enable = lib.mkEnableOption "Microsoft Defender for Endpoint";

    onboardingFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to the onboarding JSON for this device.

        IT provides a file called MicrosoftDefenderATPOnboardingLinuxServer.py —
        open it in a text editor and extract the embedded JSON blob inside.
        Store that JSON as an agenix secret, then point this option at it:
          config.age.secrets.mdatp-onboarding.path

        The JSON will be placed at /etc/opt/microsoft/mdatp/mdatp_onboard.json
        so wdavdaemon can enroll the device on first start.
      '';
    };

    groupTag = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "Linux";
      description = ''
        EDR group tag applied after onboarding. Matches the GROUP tag required
        by IT (default: "Linux"). Set to null to skip.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # nix-ld is required — mdatp binaries use NIX_LD instead of patched ELF
    # to avoid tripping anti-tamper checks.
    programs.nix-ld.enable = lib.mkForce true;

    environment.systemPackages = [mdatp];

    users.users.mdatp = {
      group = "mdatp";
      isSystemUser = true;
    };
    users.groups.mdatp = {};

    # Place the onboarding JSON so wdavdaemon enrolls on first start.
    system.activationScripts.mdatp-onboarding = lib.mkIf (cfg.onboardingFile != null) {
      deps = ["agenix"];
      text = ''
        mkdir -p /etc/opt/microsoft/mdatp
        install -m 0640 -o root -g mdatp ${cfg.onboardingFile} \
          /etc/opt/microsoft/mdatp/mdatp_onboard.json
      '';
    };

    # wdavdaemon checks /boot/config-$(uname -r); generate it from /proc/config.gz.
    system.activationScripts.mdatp-kernel-config = {
      text = ''
        if [[ -f /proc/config.gz ]]; then
          mkdir -p /boot
          ${pkgs.gzip}/bin/zcat /proc/config.gz > /boot/config-$(${pkgs.coreutils}/bin/uname -r) || true
        fi
      '';
    };

    systemd = {
      services = {
        mdatp = {
          description = "Microsoft Defender for Endpoint";
          after = ["network.target"];
          wantedBy = ["multi-user.target"];
          serviceConfig = {
            Type = "simple";
            ExecStartPre = preStartScript;
            # stdenv moves sbin/* to bin/ during fixup — use bin throughout
            WorkingDirectory = "${mdatp}/bin";
            ExecStart = "${mdatp}/bin/wdavdaemon";
            NotifyAccess = "main";
            LimitNOFILE = 65536;
            Environment = ["MALLOC_ARENA_MAX=2" "ENABLE_CRASHPAD=1"];
            Restart = "always";
            Delegate = "yes";
          };
          unitConfig = {
            DefaultDependencies = false;
            StartLimitInterval = 120;
            StartLimitBurst = 3;
          };
        };

        # Apply the EDR group tag once the daemon is healthy.
        # The script polls for up to 2 minutes and always exits 0 so it
        # never blocks activation.
        mdatp-set-group-tag = lib.mkIf (cfg.groupTag != null) {
          description = "Set Microsoft Defender EDR group tag";
          after = ["mdatp.service"];
          wants = ["mdatp.service"];
          wantedBy = ["multi-user.target"];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = setGroupTagScript;
          };
        };

        # Update definitions daily at 05:00, matching IT policy.
        mdatp-definitions-update = {
          description = "Update Microsoft Defender definitions";
          after = ["network-online.target"];
          wants = ["network-online.target"];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${mdatp}/bin/wdavdaemonclient definitions update";
          };
        };
      };

      timers.mdatp-definitions-update = {
        description = "Update Microsoft Defender definitions every night";
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "*-*-* 05:00";
          Persistent = true;
          Unit = "mdatp-definitions-update.service";
        };
      };
    };
  };
}
