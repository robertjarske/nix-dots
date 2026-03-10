_: {
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;

      # Two-line prompt: info on line 1, ❯ on line 2
      # Right side: duration, battery, time
      format = "\${directory}\${git_branch}\${git_status}\${nix_shell}\${nodejs}\${php}\${python}\${rust}\${package}\n\${character}";
      right_format = "\${cmd_duration}\${battery}\${time}";

      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };

      directory = {
        truncation_length = 4;
        truncate_to_repo = true;
      };

      git_branch = {};

      git_status = {
        ahead = "⇡\${count}";
        behind = "⇣\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        modified = "!\${count}";
        untracked = "?\${count}";
        staged = "+\${count}";
        deleted = "✘\${count}";
      };

      nix_shell = {
        # symbol uses starship's default (❄️ or Nerd Font depending on version)
        format = "via [$symbol$state]($style) ";
      };

      package = {
        # Show version even when package.json has "private": true
        display_private = true;
      };

      cmd_duration = {
        min_time = 2000;
        format = "took [$duration]($style) ";
      };

      battery = {
        display = [
          {
            threshold = 20;
            style = "bold red";
          }
          {
            threshold = 50;
            style = "bold yellow";
          }
        ];
      };

      time = {
        disabled = false;
        format = "[$time]($style) ";
        time_format = "%H:%M";
        style = "dimmed white";
      };
    };
  };
}
