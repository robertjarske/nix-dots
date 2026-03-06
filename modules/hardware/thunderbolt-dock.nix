{pkgs, ...}: {
  # Authorization daemon — required for Thunderbolt dock USB devices to be
  # exposed to the system (keyboard, headset dongle, etc.).
  services.hardware.bolt.enable = true;
  environment.systemPackages = [pkgs.bolt];

  # Force-load Thunderbolt and USB HID early in initrd so the dock keyboard
  # is usable at the LUKS password prompt (before boltd starts in userspace).
  boot.initrd.kernelModules = ["thunderbolt" "usbhid" "hid_generic"];

  # boltd only runs in userspace after boot, so it can't authorize the
  # Thunderbolt dock at LUKS time. This initrd service writes directly to
  # sysfs to authorize the dock before the cryptsetup prompt appears.
  boot.initrd.systemd.services.thunderbolt-authorize = {
    description = "Authorize Thunderbolt dock for LUKS keyboard access";
    wantedBy = ["cryptsetup.target"];
    before = ["cryptsetup.target" "systemd-cryptsetup@cryptroot.service"];
    # DefaultDependencies adds implicit After=basic.target which in the initrd
    # is ordered after cryptsetup.target — creating a cycle that causes systemd
    # to delete cryptsetup.target from the job queue and start this service
    # after the LUKS prompt instead of before it.
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Wait up to 30 s for a Thunderbolt *peripheral* to appear in sysfs.
      # Host routers are named X-0 (e.g. 0-0, 1-0) and are always present —
      # only devices named X-N where N>0 are peripherals like the dock.
      # Uses only shell builtins; grep/find are not in the initrd PATH.
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

  # The initrd thunderbolt-authorize service pre-authorized the dock so the
  # USB keyboard works at the LUKS prompt. But boltd sees the dock as already
  # authorized on startup and skips its own auth flow — meaning the DP tunnel
  # was attempted before DRM drivers were loaded and silently failed. De-auth
  # then re-auth forces the kernel to set up a fresh DP tunnel with the display
  # driver now running. boltd will auto-re-auth via udev. This runs before login
  # so the brief USB disconnect is not user-visible.
  systemd.services.wait-for-thunderbolt-dock = {
    description = "Wait for Thunderbolt dock authorization before display manager";
    wantedBy = ["display-manager.service"];
    before = ["display-manager.service"];
    after = ["bolt.service" "systemd-udevd.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Collect Thunderbolt peripheral devices (skip host routers named X-0).
      periph_devs=""
      for dev in /sys/bus/thunderbolt/devices/*/authorized; do
        [ -f "$dev" ] || continue
        devname="''${dev%/authorized}"
        devname="''${devname##*/}"
        case "$devname" in
          *-0) continue ;;
        esac
        periph_devs="$periph_devs $dev"
      done

      # No dock connected — start display manager immediately.
      [ -z "$periph_devs" ] && exit 0

      for dev in $periph_devs; do
        echo 0 > "$dev" 2>/dev/null || true
      done
      sleep 2
      for dev in $periph_devs; do
        echo 1 > "$dev" 2>/dev/null || true
      done

      # Allow the DP tunnel and monitor hotplug events to settle.
      sleep 6

      exit 0
    '';
  };
}
