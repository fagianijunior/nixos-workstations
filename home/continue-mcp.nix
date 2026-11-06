{ lib, pkgs, ... }:

let
  # Config canônico do Continue (extensão VS Code). Serializado com
  # builtins.toJSON — JSON é um subconjunto válido de YAML 1.2, então o parser
  # YAML do Continue aceita o arquivo sem problemas. Espelhamos o kiro-mcp.nix,
  # que já usa builtins.toJSON + echo + sed; manter o mesmo padrão deixa a
  # injeção do token (sed sobre o conteúdo inline) idêntica e evita um store
  # path read-only que precisaria de cp + chmod para a UI poder editar.
  #
  # mcpServers no formato do Continue é uma LISTA de objetos (name/command/
  # args/env). O Continue NÃO usa a chave `disabled` do Kiro: servers
  # indesejados são simplesmente omitidos. hypruse fica de fora por pedido do
  # usuário. Os valores de command/args/env são copiados verbatim do
  # kiro-mcp.nix (fonte da verdade).
  continueConfig = builtins.toJSON {
    name = "Main Config";
    version = "1.0.0";
    schema = "v1";
    # Bloco models preservado da config atual do usuário (Autodetect/ollama).
    models = [
      {
        name = "Autodetect";
        provider = "ollama";
        model = "AUTODETECT";
        apiBase = "http://localhost:11434";
        roles = [ "chat" "edit" "apply" ];
        capabilities = [ "tool_use" ];
        defaultCompletionOptions = {
          contextLength = 32768;
          temperature = 0.1;
        };
      }
    ];
    mcpServers = [
      {
        name = "fetch";
        command = "uvx";
        args = [ "--with" "mcp<2" "mcp-server-fetch" ];
      }
      {
        name = "nixos";
        command = "uvx";
        args = [ "mcp-nixos" ];
      }
      # Busca web via DuckDuckGo (sem API key). Alternativa ao provider @Web do
      # Continue (descontinuado).
      {
        name = "duckduckgo";
        command = "uvx";
        args = [ "duckduckgo-mcp-server" ];
      }
      {
        name = "qt-docs";
        command = "npx";
        args = [ "mcp-remote" "https://qt-docs-mcp.qt.io/mcp" ];
      }
      # taskwarrior: binário do overlay (overlays/mcp-server-taskwarrior.nix).
      # Caminho absoluto da store para não depender do PATH do processo que
      # lança o MCP.
      {
        name = "taskwarrior";
        command = "${pkgs.mcp-server-taskwarrior}/bin/mcp-server-taskwarrior";
        args = [ ];
      }
      {
        name = "github";
        command = "github-mcp-server";
        args = [ "stdio" ];
        env = {
          GITHUB_PERSONAL_ACCESS_TOKEN = "REPLACE_WITH_YOUR_TOKEN";
        };
      }
      {
        name = "terraform";
        command = "terraform-mcp-server";
        args = [ "stdio" ];
      }
      # make: servidor MCP remoto da Make via mcp-remote (mesmo padrão do
      # qt-docs). A zona e a API key são injetadas em tempo de activation a
      # partir de ~/.config/make-mcp/ (ver abaixo).
      {
        name = "make";
        command = "npx";
        args = [
          "mcp-remote"
          "https://MAKE_ZONE_PLACEHOLDER/mcp/u/REPLACE_WITH_MAKE_API_KEY/v2"
        ];
      }
      # aws-mcp: as chaves timeout/transport do kiro não existem no formato do
      # Continue e são descartadas; só name/command/args permanecem.
      {
        name = "aws-mcp";
        command = "uvx";
        args = [
          "mcp-proxy-for-aws@1.6.3"
          "https://aws-mcp.us-east-1.api.aws/mcp"
          "--metadata"
          "AWS_REGION=us-east-1"
        ];
      }
    ];
  };
in
{
  # Gera ~/.continue/config.yaml a cada activation.
  # O arquivo é REGULAR (não symlink) para que a UI do Continue ainda possa
  # editá-lo; o próximo `home-manager switch` regenera com a config canônica +
  # token novo. (Mesmo padrão do kiro-mcp.nix com o mcp.json.)
  #
  # O token do GitHub vem do `gh auth token` em tempo de activation: o template
  # avaliado pelo Nix carrega só o placeholder REPLACE_WITH_YOUR_TOKEN (nenhum
  # segredo na /nix/store) e o sed abaixo o substitui quando o gh está
  # autenticado na máquina.
  home.activation.continueMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.continue"
    echo '${continueConfig}' > "$HOME/.continue/config.yaml"

    # Inject GitHub token from gh CLI if authenticated
    GH_TOKEN=$(${pkgs.gh}/bin/gh auth token 2>/dev/null || true)
    if [ -n "$GH_TOKEN" ]; then
      sed -i "s/REPLACE_WITH_YOUR_TOKEN/$GH_TOKEN/" "$HOME/.continue/config.yaml"
    fi

    # Inject Make MCP credentials from local secret files (fora da /nix/store).
    #   ~/.config/make-mcp/api-key  -> API key da Make
    #   ~/.config/make-mcp/zone     -> zona (ex.: eu2.make.com); default us1.make.com
    if [ -f "$HOME/.config/make-mcp/api-key" ]; then
      MAKE_API_KEY=$(tr -d '[:space:]' < "$HOME/.config/make-mcp/api-key")
      MAKE_ZONE=$(tr -d '[:space:]' < "$HOME/.config/make-mcp/zone" 2>/dev/null || true)
      [ -n "$MAKE_ZONE" ] || MAKE_ZONE="us1.make.com"
      sed -i "s|MAKE_ZONE_PLACEHOLDER|$MAKE_ZONE|; s|REPLACE_WITH_MAKE_API_KEY|$MAKE_API_KEY|" "$HOME/.continue/config.yaml"
    fi
  '';
}
