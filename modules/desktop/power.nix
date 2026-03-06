_: {
  services.power-profiles-daemon.enable = true;
  # Required for HyprPanel's battery module — reads battery state via UPower D-Bus.
  services.upower.enable = true;
}
