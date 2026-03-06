{pkgs, ...}: {
  # Authorization daemon — authorizes enrolled Thunderbolt devices at runtime
  # so keyboard, mouse, and other dock USB devices work after login.
  services.hardware.bolt.enable = true;
  environment.systemPackages = [pkgs.bolt];

  # Load Thunderbolt and USB HID early in initrd so the dock keyboard
  # is usable at the LUKS password prompt (before boltd starts in userspace).
  boot.initrd.kernelModules = ["thunderbolt" "usbhid" "hid_generic"];

  # Authorize the Thunderbolt dock in the initrd so USB devices (keyboard)
  # are available at the LUKS prompt. boltd is not running yet at this point.
  boot.initrd.systemd.services.thunderbolt-authorize = {
    description = "Authorize Thunderbolt dock for LUKS keyboard access";
    wantedBy = ["cryptsetup.target"];
    before = ["cryptsetup.target" "systemd-cryptsetup@cryptroot.service"];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      for i in $(seq 1 30); do
        found=0
        for dev in /sys/bus/thunderbolt/devices/*/authorized; do
          [ -f "$dev" ] || continue
          devname="''${dev%/authorized}"
          devname="''${devname##*/}"
          case "$devname" in
            *-0) continue ;;
          esac
          found=1
          break
        done
        if [ "$found" = "1" ]; then
          for dev in /sys/bus/thunderbolt/devices/*/authorized; do
            [ -f "$dev" ] && echo 1 > "$dev" 2>/dev/null || true
          done
          exit 0
        fi
        sleep 1
      done
      exit 0
    '';
  };
}
