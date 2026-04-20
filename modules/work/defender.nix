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
    UPPER=/var/lib/mdatp-overlay/upper
    WORK=/var/lib/mdatp-overlay/work

    # Replace any legacy symlink with a real directory (overlay mount target).
    if [[ -L $INSTALL ]]; then rm -f "$INSTALL"; fi
    mkdir -p /opt/microsoft "$INSTALL"

    # Use overlayfs (not a plain bind mount) so /proc/[pid]/exe resolves to
    # /opt/microsoft/mdatp/... paths AND the directory appears writable.
    # A plain bind mount of the nix store exposes a mode-555 directory;
    # wdavdaemon's permission_checker fails when it cannot create files there.
    # The overlay upper layer (on /var/lib) absorbs all writes.
    fstype=$(${pkgs.util-linux}/bin/findmnt -n -o FSTYPE "$INSTALL" 2>/dev/null || true)
    opts=$(${pkgs.util-linux}/bin/findmnt -n -o OPTIONS "$INSTALL" 2>/dev/null || true)
    # Extract lowerdir= value using bash only (no sed/awk in PATH here).
    lower=""
    for opt in ''${opts//,/ }; do
      [[ "$opt" == lowerdir=* ]] && lower="''${opt#lowerdir=}" && break
    done
    if [[ "$fstype" == "overlay" && "$lower" == "${mdatp}" ]]; then exit 0; fi

    ${pkgs.util-linux}/bin/mountpoint -q "$INSTALL" \
      && ${pkgs.util-linux}/bin/umount "$INSTALL" || true

    # Clear stale upper/work dirs so a derivation update takes full effect.
    rm -rf "$UPPER" "$WORK"
    mkdir -p "$UPPER" "$WORK"

    ${pkgs.util-linux}/bin/mount -t overlay overlay \
      -o "lowerdir=${mdatp},upperdir=$UPPER,workdir=$WORK" \
      "$INSTALL"
  '';

  # Managed configuration profile — deployed to the well-known path that
  # wdavdaemon reads on startup.
  managedConfig = pkgs.writeText "mdatp_managed.json" (builtins.toJSON {
    antivirusEngine = {
      enforcementLevel = "passive";
      behaviorMonitoring = "disabled";
      # Trigger a scan automatically after each definition update.
      # Combined with the daily definitions timer this gives one scan/day
      # without a separate scan service.
      scanAfterDefinitionUpdate = true;
      # Archive scanning is critical — npm/pip packages are tarballs and
      # supply-chain attacks (e.g. axios) are embedded inside them.
      scanArchives = true;
      scanHistoryMaximumItems = 10000;
      scanResultsRetentionDays = 90;
      maximumOnDemandScanThreads = 2;
      exclusionsMergePolicy = "merge";
      # Prevent users from accidentally un-quarantining detections.
      disallowedThreatActions = ["allow" "restore"];
      nonExecMountPolicy = "unmute";
      unmonitoredFilesystems = ["nfs" "fuse"];
      enableFileHashComputation = false;
      threatTypeSettingsMergePolicy = "merge";
      threatTypeSettings = [
        {key = "potentially_unwanted_application"; value = "block";}
        {key = "archive_bomb"; value = "audit";}
      ];
      scanFileModifyPermissions = true;
      scanFileModifyOwnership = false;
      scanNetworkSocketEvent = false;
    };
    cloudService = {
      enabled = true;
      diagnosticLevel = "optional";
      automaticSampleSubmissionConsent = "safe";
      automaticDefinitionUpdateEnabled = true;
      definitionUpdatesInterval = 28800;
    };
    features = {
      moduleLoad = "disabled";
      ebpfSupplementaryEventProvider = "enabled";
    };
    networkProtection = {
      enforcementLevel = "disabled";
      disableIcmpInspection = true;
    };
  });

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
    environment.etc."opt/microsoft/mdatp/mdatp_managed.json" = {
      source = managedConfig;
      mode = "0644";
    };

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
            # Use the stable symlink path as WorkingDirectory so wdavdaemon
            # resolves sibling binaries (sensecm, senseir …) relative to the
            # well-known /opt/microsoft/mdatp/sbin/ prefix, matching the
            # layout Microsoft hardcodes in the official service unit.
            # Use the nix store path as WorkingDirectory so ExecStartPre
            # (the bind-mount script) can chdir there before /opt/microsoft/mdatp
            # is mounted.  wdavdaemon resolves siblings via /proc/self/exe, not
            # CWD, so this has no effect on binary resolution.
            WorkingDirectory = "${mdatp}/sbin";
            ExecStart = "/opt/microsoft/mdatp/sbin/wdavdaemon";
            NotifyAccess = "main";
            LimitNOFILE = 65536;
            # No wrapProgram is used for any mdatp binary (see pkgs/mdatp.nix).
            # All binaries are real ELFs so that
            # anti-tamper checks on /proc/self/exe and /proc/[ppid]/exe succeed.
            # nix-ld handles library resolution for all of them via NIX_LD +
            # NIX_LD_LIBRARY_PATH, which wdavdaemon and every child process it
            # spawns inherit from the service environment below.
            Environment = [
              "MALLOC_ARENA_MAX=2"
              "ENABLE_CRASHPAD=1"
              "NIX_LD=${pkgs.stdenv.cc.bintools.dynamicLinker}"
              "NIX_LD_LIBRARY_PATH=${mdatp}/lib:${mdatp.passthru.libPath}"
              "LD_LIBRARY_PATH=/opt/microsoft/mdatp/lib/"
              "PATH=${lib.makeBinPath [pkgs.coreutils pkgs.gnugrep]}:$PATH"
              # Security hardening from official service — prevent injected libs.
              "LD_PRELOAD="
              "LD_AUDIT="
            ];
            Restart = "always";
            Delegate = "yes";
          };
          unitConfig = {
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

        # Full scan weekly on Sunday at 02:00. Full scan is required to cover
        # package caches (npm, pip, cargo) where supply-chain attacks land.
        mdatp-scan-full = {
          description = "Microsoft Defender full scan";
          after = ["mdatp.service"];
          wants = ["mdatp.service"];
          serviceConfig = {
            Type = "oneshot";
            # mdatp.service is Type=simple so systemd marks it started before
            # wdavdaemon is ready. Poll until healthy (same pattern as
            # mdatp-set-group-tag) so the scan never runs against a dead socket.
            ExecStartPre = pkgs.writeShellScript "wait-mdatp-healthy" ''
              for i in $(seq 1 24); do
                if ${mdatp}/bin/mdatp health --field healthy 2>/dev/null | grep -q '^true$'; then
                  exit 0
                fi
                sleep 5
              done
              echo "mdatp not healthy after 2 minutes, aborting scan" >&2
              exit 1
            '';
            ExecStart = "${mdatp}/bin/mdatp scan full";
            # Scans can take hours — no timeout.
            TimeoutSec = "infinity";
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

      timers.mdatp-scan-full = {
        description = "Run Microsoft Defender full scan weekly";
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "Sun *-*-* 02:00";
          Persistent = true;
          Unit = "mdatp-scan-full.service";
        };
      };
    };
  };
}
