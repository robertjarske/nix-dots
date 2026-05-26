{
  config,
  pkgs,
  unstable,
  ...
}: let
  wayle-with-teams-icon = pkgs.symlinkJoin {
    name = "wayle";
    paths = [unstable.wayle];
    postBuild = ''
            mkdir -p $out/share/icons/hicolor/scalable/actions
            cat > $out/share/icons/hicolor/scalable/actions/tb-brand-teams-symbolic.svg << 'EOF'
      <svg width='16' height='16' viewBox='0 0 24 24'
           xmlns:gpa='https://www.gtk.org/grappa'
           gpa:version='1'>
        <path d='M3 7h10v10h-10l0 -10'
              stroke-width='2'
              stroke-linecap='round'
              stroke-linejoin='round'
              stroke='rgb(0,0,0)'
              fill='none'
              class='foreground-stroke transparent-fill'
              gpa:stroke='foreground'/>
        <path d='M6 10h4'
              stroke-width='2'
              stroke-linecap='round'
              stroke-linejoin='round'
              stroke='rgb(0,0,0)'
              fill='none'
              class='foreground-stroke transparent-fill'
              gpa:stroke='foreground'/>
        <path d='M8 10v4'
              stroke-width='2'
              stroke-linecap='round'
              stroke-linejoin='round'
              stroke='rgb(0,0,0)'
              fill='none'
              class='foreground-stroke transparent-fill'
              gpa:stroke='foreground'/>
        <path d='M8.104 17c.47 2.274 2.483 4 4.896 4a5 5 0 0 0 5 -5v-7h-5'
              stroke-width='2'
              stroke-linecap='round'
              stroke-linejoin='round'
              stroke='rgb(0,0,0)'
              fill='none'
              class='foreground-stroke transparent-fill'
              gpa:stroke='foreground'/>
        <path d='M18 18a4 4 0 0 0 4 -4v-5h-4'
              stroke-width='2'
              stroke-linecap='round'
              stroke-linejoin='round'
              stroke='rgb(0,0,0)'
              fill='none'
              class='foreground-stroke transparent-fill'
              gpa:stroke='foreground'/>
        <path d='M13.003 8.83a3 3 0 1 0 -1.833 -1.833'
              stroke-width='2'
              stroke-linecap='round'
              stroke-linejoin='round'
              stroke='rgb(0,0,0)'
              fill='none'
              class='foreground-stroke transparent-fill'
              gpa:stroke='foreground'/>
        <path d='M15.83 8.36a2.5 2.5 0 1 0 .594 -4.117'
              stroke-width='2'
              stroke-linecap='round'
              stroke-linejoin='round'
              stroke='rgb(0,0,0)'
              fill='none'
              class='foreground-stroke transparent-fill'
              gpa:stroke='foreground'/>
      </svg>
      EOF
    '';
  };
in {
  # awww is wayle's wallpaper rendering backend — wayle calls it internally.
  services.awww.enable = true;

  # Wayle daemon runs via systemd and gets a restricted PATH that omits the HM
  # profile bin. Inject it explicitly so wayle can exec `awww img` at runtime.
  systemd.user.services.wayle.environment = {
    PATH = "${config.home.profileDirectory}/bin:/run/current-system/sw/bin:/run/wrappers/bin";
  };

  services.wayle = {
    enable = true;
    package = wayle-with-teams-icon;
    settings = {
      bar = {
        scale = 0.75;
        background-opacity = 90;
        button-variant = "basic";
        button-gap = 1.2;
        button-label-padding = 1.1;
        button-label-weight = "bold";
        button-group-border-location = "all";
        button-group-border-width = 10;
        module-gap = 0.7;
        padding-ends = 0.7;
        layout = [
          {
            monitor = "*";
            show = true;
            left = ["dashboard" "separator" "hyprland-workspaces" "separator" "cpu" "ram" "storage"];
            center = ["weather"];
            right = ["idle-inhibit" "volume" "bluetooth" "battery" "systray" "clock" "notifications"];
          }
        ];
      };

      styling = {
        theme-provider = "matugen";
        theming-monitor = "eDP-1";
        matugen-scheme = "expressive";
        matugen-contrast = 1.0;
      };

      wallpaper = {
        cycling-enabled = true;
        cycling-directory = "${config.home.homeDirectory}/Pictures/wallpapers";
        cycling-mode = "shuffle";
        cycling-interval-mins = 30;
        cycling-same-image = true;
        transition-type = "center";
        transition-duration = 0.7;
        transition-fps = 120;
      };

      modules = {
        battery.border-show = true;
        bluetooth.border-show = true;
        cava.border-show = true;
        clock = {
          border-show = true;
          format = "%Y-%#m-%#d %H:%M";
          dropdown-show-seconds = true;
        };
        hyprland-workspaces = {
          app-icons-show = true;
          display-mode = "none";
          app-icon-map = {
            "title:*Microsoft Teams*" = "tb-brand-teams-symbolic";
            "title:Bruno" = "bruno";
          };
        };
        notification = {
          popup-monitor = "DP-5";
          popup-position = "bottom-right";
        };
        weather.border-show = true;
      };
    };
  };
}
