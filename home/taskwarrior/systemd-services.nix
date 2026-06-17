# Systemd services for task automation with AI
{ config, pkgs, ... }:

{
  systemd.user.services = {

    taskwarrior-ai-analyze = {
      Unit = {
        Description = "On-demand task analysis with AI";
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.python3}/bin/python3 ${config.home.homeDirectory}/.config/task/ai-assistant.py analyze";
        Environment = [
          "PATH=${pkgs.python3}/bin:${pkgs.taskwarrior3}/bin:$PATH"
        ];
      };
    };

    taskwarrior-cleanup-reports = {
      Unit = {
        Description = "Cleanup old task reports";
      };
      Service = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "cleanup-task-reports" ''
          #!/bin/bash
          REPORT_DIR="$HOME/.local/share/task-reports"

          if [[ -d "$REPORT_DIR" ]]; then
            # Remove reports older than 30 days
            find "$REPORT_DIR" -name "daily-report-*.md" -mtime +30 -delete
            echo "Report cleanup completed"
          fi
        '';
      };
    };
  };

  systemd.user.timers = {

    taskwarrior-cleanup-reports = {
      Unit = {
        Description = "Timer for report cleanup";
      };
      Timer = {
        OnCalendar = "Mon 06:00";
        Persistent = true;
      };
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
  };
}
