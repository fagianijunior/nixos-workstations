{ pkgs, ... }:

{
  # tomat — Pomodoro timer com daemon via socket Unix
  home.packages = [ pkgs.tomat ];

  # Daemon persistente: inicia com a sessão do usuário
  systemd.user.services.tomat = {
    Unit = {
      Description = "Tomat Pomodoro Timer Daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      # tomat daemon start daemonizes itself — use forking type
      Type = "forking";
      ExecStart = "${pkgs.tomat}/bin/tomat daemon start";
      ExecStop = "${pkgs.tomat}/bin/tomat daemon stop";
      Restart = "on-failure";
      RestartSec = "3s";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
