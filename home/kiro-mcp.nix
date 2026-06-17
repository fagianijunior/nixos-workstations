{ lib, ... }:

let
  mcpConfig = builtins.toJSON {
    mcpServers = {
      fetch = {
        command = "uvx";
        args = [ "mcp-server-fetch" ];
      };
      nixos = {
        command = "uvx";
        args = [ "mcp-nixos" ];
      };
      "Hyperland MCP Server" = {
        command = "uv";
        args = [
          "run"
          "--with"
          "mcp[cli]"
          "mcp"
          "run"
          "/home/terabytes/Workspace/MCPs/hyprmcp/hyprmcp/server.py"
        ];
        env = {
          PYTHONPATH = "/home/terabytes/Workspace/MCPs/hyprmcp";
        };
      };
      qt-docs = {
        command = "npx";
        args = [ "mcp-remote" "https://qt-docs-mcp.qt.io/mcp" ];
      };
      taskwarrior = {
        command = "npx";
        args = [ "-y" "mcp-server-taskwarrior" ];
      };
      github = {
        command = "github-mcp-server";
        args = [ "stdio" ];
        env = {
          GITHUB_PERSONAL_ACCESS_TOKEN = "REPLACE_WITH_YOUR_TOKEN";
        };
      };
      terraform = {
        command = "terraform-mcp-server";
        args = [ "stdio" ];
      };
      "awslabs.aws-api-mcp-server" = {
        command = "uvx";
        args = [ "awslabs.aws-api-mcp-server@latest" ];
        env = {
          AWS_REGION = "us-east-1";
        };
      };
    };
  };
in
{
  # Creates ~/.kiro/settings/mcp.json only if it doesn't exist yet.
  # The file is NOT managed by Home Manager (no symlink) so you can edit it
  # freely without needing a rebuild — tokens, disabled flags, etc.
  home.activation.kiroMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.kiro/settings"
    if [ ! -f "$HOME/.kiro/settings/mcp.json" ]; then
      echo '${mcpConfig}' > "$HOME/.kiro/settings/mcp.json"
    fi
  '';
}