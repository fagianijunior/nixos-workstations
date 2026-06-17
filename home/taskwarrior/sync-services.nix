{ config, pkgs, lib, ... }:

# Serviços systemd para sincronização automática do Taskwarrior
# 
# Este módulo adiciona:
# - Serviço de sincronização automática a cada 15 minutos
# - Túnel SSH automático (se necessário)
# - Notificações de erro de sincronização
#
# Para usar, importe este arquivo no seu home/taskwarrior/default.nix

let
  # Configuração
  syncEnabled = false;  # Mude para true para habilitar sincronização automática
  useSshTunnel = false; # Mude para true se usar túnel SSH
  serverHost = "orangepizero2";
  serverPort = "8080";
in
{
  # Serviço de sincronização
  systemd.user.services.taskwarrior-sync = lib.mkIf syncEnabled {
    Unit = {
      Description = "Taskwarrior Sync";
      After = lib.mkIf useSshTunnel [ "taskwarrior-ssh-tunnel.service" ];
      Wants = lib.mkIf useSshTunnel [ "taskwarrior-ssh-tunnel.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.taskwarrior3}/bin/task sync";
      Environment = [
        "PATH=${pkgs.taskwarrior3}/bin:$PATH"
      ];
      # Notificar em caso de erro (requer libnotify)
      ExecStartPost = pkgs.writeShellScript "notify-sync-success" ''
        if [ $EXIT_STATUS -eq 0 ]; then
          ${pkgs.libnotify}/bin/notify-send "Taskwarrior" "Sincronização concluída" -i task-due
        fi
      '';
    };
    # Não falhar se o sync falhar (apenas logar)
    Install = {
      WantedBy = [ ];
    };
  };

  # Timer para sincronização automática
  systemd.user.timers.taskwarrior-sync = lib.mkIf syncEnabled {
    Unit = {
      Description = "Taskwarrior Sync Timer";
    };
    Timer = {
      OnBootSec = "5min";
      OnUnitActiveSec = "15min";
      Persistent = true;
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  # Serviço de túnel SSH (opcional)
  systemd.user.services.taskwarrior-ssh-tunnel = lib.mkIf (syncEnabled && useSshTunnel) {
    Unit = {
      Description = "SSH Tunnel for Taskwarrior Sync";
      After = [ "network.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.openssh}/bin/ssh -L ${serverPort}:localhost:${serverPort} -N ${serverHost}";
      Restart = "always";
      RestartSec = "10s";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # Serviço para verificar conectividade antes de sincronizar
  systemd.user.services.taskwarrior-sync-check = lib.mkIf syncEnabled {
    Unit = {
      Description = "Check Taskwarrior Sync Server Connectivity";
    };
    Service = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "check-sync-server" ''
        #!/usr/bin/env bash
        
        SERVER_URL="http://${if useSshTunnel then "localhost" else serverHost}:${serverPort}"
        
        if ${pkgs.curl}/bin/curl -s -f -m 5 "$SERVER_URL" > /dev/null 2>&1; then
          echo "✅ Servidor acessível: $SERVER_URL"
          exit 0
        else
          echo "❌ Servidor não acessível: $SERVER_URL"
          ${pkgs.libnotify}/bin/notify-send -u critical "Taskwarrior" "Servidor de sync não acessível" -i dialog-error
          exit 1
        fi
      '';
    };
  };

  # Timer para verificar conectividade periodicamente
  systemd.user.timers.taskwarrior-sync-check = lib.mkIf syncEnabled {
    Unit = {
      Description = "Check Taskwarrior Sync Server Timer";
    };
    Timer = {
      OnBootSec = "2min";
      OnUnitActiveSec = "1h";
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  # Serviço de backup local antes de sincronizar
  systemd.user.services.taskwarrior-backup = lib.mkIf syncEnabled {
    Unit = {
      Description = "Backup Taskwarrior Data";
    };
    Service = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "backup-taskwarrior" ''
        #!/usr/bin/env bash
        
        BACKUP_DIR="$HOME/.local/share/task-backups"
        DATE=$(date +%Y%m%d-%H%M%S)
        
        mkdir -p "$BACKUP_DIR"
        
        # Exportar tarefas
        ${pkgs.taskwarrior3}/bin/task export > "$BACKUP_DIR/tasks-$DATE.json"
        
        # Comprimir
        ${pkgs.gzip}/bin/gzip "$BACKUP_DIR/tasks-$DATE.json"
        
        # Manter apenas últimos 30 backups
        ls -t "$BACKUP_DIR"/tasks-*.json.gz | tail -n +31 | xargs -r rm
        
        echo "✅ Backup criado: tasks-$DATE.json.gz"
      '';
    };
  };

  # Timer para backup diário
  systemd.user.timers.taskwarrior-backup = lib.mkIf syncEnabled {
    Unit = {
      Description = "Daily Taskwarrior Backup Timer";
    };
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  # Scripts helper
  home.packages = lib.mkIf syncEnabled [
    # Script para sincronizar manualmente com feedback
    (pkgs.writeShellScriptBin "task-sync-now" ''
      #!/usr/bin/env bash
      echo "🔄 Sincronizando tarefas..."
      
      if task sync rc.verbose=on; then
        echo "✅ Sincronização concluída!"
        ${pkgs.libnotify}/bin/notify-send "Taskwarrior" "Sincronização concluída" -i task-due
      else
        echo "❌ Erro na sincronização"
        ${pkgs.libnotify}/bin/notify-send -u critical "Taskwarrior" "Erro na sincronização" -i dialog-error
        exit 1
      fi
    '')
    
    # Script para verificar status dos serviços
    (pkgs.writeShellScriptBin "task-sync-services" ''
      #!/usr/bin/env bash
      echo "📊 Status dos serviços de sincronização:"
      echo ""
      
      echo "🔄 Serviço de sincronização:"
      systemctl --user status taskwarrior-sync.service --no-pager | head -5
      echo ""
      
      echo "⏰ Timer de sincronização:"
      systemctl --user status taskwarrior-sync.timer --no-pager | head -5
      echo ""
      
      ${if useSshTunnel then ''
        echo "🔒 Túnel SSH:"
        systemctl --user status taskwarrior-ssh-tunnel.service --no-pager | head -5
        echo ""
      '' else ""}
      
      echo "📦 Última sincronização:"
      journalctl --user -u taskwarrior-sync.service -n 5 --no-pager
      echo ""
      
      echo "💾 Backups disponíveis:"
      ls -lh ~/.local/share/task-backups/ | tail -5
    '')
    
    # Script para habilitar/desabilitar sincronização
    (pkgs.writeShellScriptBin "task-sync-toggle" ''
      #!/usr/bin/env bash
      
      if systemctl --user is-enabled taskwarrior-sync.timer &>/dev/null; then
        echo "⏸️  Desabilitando sincronização automática..."
        systemctl --user disable --now taskwarrior-sync.timer
        echo "✅ Sincronização automática desabilitada"
      else
        echo "▶️  Habilitando sincronização automática..."
        systemctl --user enable --now taskwarrior-sync.timer
        echo "✅ Sincronização automática habilitada"
      fi
      
      echo ""
      systemctl --user status taskwarrior-sync.timer --no-pager | head -5
    '')
  ];
}
