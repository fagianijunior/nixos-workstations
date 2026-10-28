{ pkgs, ... }:

let
  # Caminho persistente, FORA do Nix store, para o token de autenticação
  # compartilhado entre o n8n (task broker) e os task runners. O módulo do
  # nixpkgs NÃO gera esse token -- ele apenas o carrega via systemd
  # LoadCredential a partir do caminho informado, e tem uma assertion que
  # exige N8N_RUNNERS_AUTH_TOKEN_FILE quando taskRunners.enable = true.
  # Como este repo ainda não usa agenix/sops-nix, geramos o token uma única
  # vez com um oneshot (openssl rand) e o persistimos aqui. Não vai para o
  # store nem para o git.
  runnersAuthTokenFile = "/var/lib/n8n-secrets/runners-auth-token";
in
{
  # n8n: plataforma de automação de workflows (fair-code).
  #
  # Caso de uso inicial: organizar o Gmail com IA. O fluxo fica:
  #   trigger Gmail (OAuth2) -> node Ollama (LLM local classifica) -> aplica
  #   label de volta no Gmail. Como o label é aplicado via Gmail API, a
  #   organização reflete no gmail.com e no celular -- não é só local.
  #
  # Por que n8n (e não uma CLI dedicada): é reaproveitável. Depois dá pra usar
  # o mesmo n8n para outros workflows, e migrar a instância para o OrangePi
  # Zero 3 mantendo o Ollama na Nobita via Tailscale -- basta trocar a base URL
  # do node de Ollama de http://localhost:11434 para http://nobita:11434.
  # Nenhuma mudança no Nix é necessária para essa migração.
  #
  # Privacidade: o conteúdo dos emails vai para o Ollama LOCAL (localhost ou
  # nobita via Tailscale), nunca para uma API de LLM na nuvem. Só o OAuth2 do
  # Gmail fala com o Google, que já é o dono da caixa.

  services.n8n = {
    enable = true;

    # Abre a porta do n8n (default 5678) no firewall. Enquanto a instância roda
    # na Nobita e você acessa do próprio desktop, dá para deixar false e usar
    # http://localhost:5678. Deixo true porque o acesso via Tailscale (de outra
    # máquina na tailnet) é o cenário provável -- a tailnet já é a fronteira de
    # confiança. Se quiser fechar para a LAN, volte para false e acesse só local.
    openFirewall = true;

    environment = {
      # Timezone da instância. Importa para os nós de schedule/cron dispararem
      # no horário certo (ex.: varrer a caixa a cada N minutos no horário local).
      GENERIC_TIMEZONE = "America/Fortaleza";

      # Desliga a telemetria anônima do n8n. Trade-off conhecido: com isto em
      # false, o recurso "Ask AI" do Code node fica indisponível -- não usamos
      # ele aqui (a IA do fluxo é o Ollama, não o assistente embutido do n8n).
      N8N_DIAGNOSTICS_ENABLED = false;

      # Não notificar sobre novas versões: o versionamento é feito pelo nixpkgs,
      # então o update vem pelo flake, não pelo aviso dentro da UI.
      N8N_VERSION_NOTIFICATIONS_ENABLED = false;
    };

    # Task runners: executam o Code node em processo separado e isolado. É o
    # modelo recomendado pelo n8n nas versões atuais (substitui a execução
    # in-process).
    #
    # IMPORTANTE: o módulo do nixpkgs NÃO gera o token de auth automaticamente.
    # Ele tem uma assertion exigindo N8N_RUNNERS_AUTH_TOKEN_FILE != null quando
    # taskRunners.enable = true, e carrega esse arquivo via systemd
    # LoadCredential. Geramos o token nós mesmos no oneshot abaixo e apontamos
    # o módulo para ele aqui.
    taskRunners.enable = true;

    environment.N8N_RUNNERS_AUTH_TOKEN_FILE = runnersAuthTokenFile;
  };

  # Gera o token de auth dos task runners uma única vez, se ainda não existir,
  # em /var/lib/n8n-secrets/runners-auth-token (persistente, fora do store).
  # Roda antes de n8n.service e n8n-task-runner.service para o LoadCredential
  # de ambos encontrar o arquivo. Permissões 0600 root -- o systemd copia o
  # conteúdo para a credential de cada serviço (DynamicUser), então não é
  # preciso afrouxar o dono do arquivo.
  systemd.services.n8n-runners-auth-token = {
    description = "Generate n8n task runners auth token";
    before = [ "n8n.service" "n8n-task-runner.service" ];
    requiredBy = [ "n8n.service" "n8n-task-runner.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      UMask = "0077";
    };
    script = ''
      set -euo pipefail
      mkdir -p "$(dirname ${runnersAuthTokenFile})"
      if [ ! -s ${runnersAuthTokenFile} ]; then
        ${pkgs.openssl}/bin/openssl rand -hex 32 > ${runnersAuthTokenFile}
        chmod 0600 ${runnersAuthTokenFile}
      fi
    '';
  };
}