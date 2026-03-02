{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    docker-compose
  ];

  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };
}
