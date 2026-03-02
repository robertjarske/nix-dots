{config, ...}: {
  services.snapper.configs.home = {
    SUBVOLUME = "/home";
    ALLOW_USERS = [config.host.username];
    TIMELINE_CREATE = true;
    TIMELINE_CLEANUP = true;
    TIMELINE_LIMIT_HOURLY = "10";
    TIMELINE_LIMIT_DAILY = "7";
    TIMELINE_LIMIT_WEEKLY = "4";
    TIMELINE_LIMIT_MONTHLY = "0";
    TIMELINE_LIMIT_YEARLY = "0";
  };
}
