{ lib, pkgs, ... }:

let
  mcpConfig = builtins.toJSON {
    mcpServers = {
<<<<<<< Updated upstream
||||||| Stash base
      fetch = {
        command = "uvx";
        args = [ "--with" "mcp<2" "mcp-server-fetch" ];
        disabled = "false";
      };
      nixos = {
        command = "uvx";
        args = [ "mcp-nixos" ];
        disabled = "true";
      };
=======
      fetch = {
        command = "uvx";
        args = [ "--with" "mcp<2" "mcp-server-fetch" ];
        disabled = false;
      };
      nixos = {
        command = "uvx";
        args = [ "mcp-nixos" ];
        disabled = true;
      };
>>>>>>> Stashed changes
      "Hyperland MCP Server" = {
        command = "uv";
        args = [
          "run"
          "--with"
          "mcp[cli]<2"
          "mcp"
          "run"
          "/home/terabytes/Workspace/MCPs/hyprmcp/hyprmcp/server.py"
        ];
        env = {
          PYTHONPATH = "/home/terabytes/Workspace/MCPs/hyprmcp";
        };
<<<<<<< Updated upstream
        disabled = false;
||||||| Stash base
        disabled = "true";
      };
      qt-docs = {
        command = "npx";
        args = [ "mcp-remote" "https://qt-docs-mcp.qt.io/mcp" ];
        disabled = "true";
      };
      taskwarrior = {
        command = "npx";
        args = [ "-y" "mcp-server-taskwarrior" ];
        disabled = "true";
      };
      github = {
        command = "github-mcp-server";
        args = [ "stdio" ];
        env = {
          GITHUB_PERSONAL_ACCESS_TOKEN = "REPLACE_WITH_YOUR_TOKEN";
        };
        disabled = "true";
      };
      terraform = {
        command = "terraform-mcp-server";
        args = [ "stdio" ];
        disabled = "true";
=======
        disabled = true;
      };
      qt-docs = {
        command = "npx";
        args = [ "mcp-remote" "https://qt-docs-mcp.qt.io/mcp" ];
        disabled = true;
      };
      taskwarrior = {
        command = "npx";
        args = [ "-y" "mcp-server-taskwarrior" ];
        disabled = true;
      };
      github = {
        command = "github-mcp-server";
        args = [ "stdio" ];
        env = {
          GITHUB_PERSONAL_ACCESS_TOKEN = "REPLACE_WITH_YOUR_TOKEN";
        };
        disabled = true;
      };
      terraform = {
        command = "terraform-mcp-server";
        args = [ "stdio" ];
        disabled = true;
>>>>>>> Stashed changes
      };
      "aws-mcp" = {
        command = "uvx";
<<<<<<< Updated upstream
        args = [ "awslabs.aws-api-mcp-server@latest" ];
        env = {
          AWS_REGION = "us-east-1";
        };
        disabled = true;
      };
      fetch = {
        command = "uvx";
        args = [ "--with" "mcp<2" "mcp-server-fetch" ];
        disabled = false;
      };
      github = {
        command = "github-mcp-server";
        args = [ "stdio" ];
        env = {
          GITHUB_PERSONAL_ACCESS_TOKEN = "REPLACE_WITH_YOUR_TOKEN";
        };
        disabled = true;
      };
      nixos = {
        command = "uvx";
        args = [ "mcp-nixos" ];
        disabled = true;
      };
      qt-docs = {
        command = "npx";
        args = [ "mcp-remote" "https://qt-docs-mcp.qt.io/mcp" ];
        disabled = true;
      };
      taskwarrior = {
        command = "npx";
        args = [ "-y" "mcp-server-taskwarrior" ];
        disabled = true;
      };
      terraform = {
        command = "terraform-mcp-server";
        args = [ "stdio" ];
||||||| Stash base
        args = [ "awslabs.aws-api-mcp-server@latest" ];
        env = {
          AWS_REGION = "us-east-1";
        };
        disabled = "true";
=======
        args = [
          "mcp-proxy-for-aws@1.6.4"
          "https://aws-mcp.us-east-1.api.aws/mcp"
          "--metadata"
          "AWS_REGION=us-east-1"
        ];
        timeout = 100000;
        transport = "stdio";
>>>>>>> Stashed changes
        disabled = true;
      };
    };
  };
in
{
  # Generates ~/.kiro/settings/mcp.json on every activation.
  # The file is a regular file (NOT a symlink) so the IDE can toggle
  # individual MCP servers via its UI. Next `home-manager switch` will
  # regenerate it with the canonical config + fresh gh token.
  home.activation.kiroMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.kiro/settings"
    echo '${mcpConfig}' > "$HOME/.kiro/settings/mcp.json"

    # Inject GitHub token from gh CLI if authenticated
    GH_TOKEN=$(${pkgs.gh}/bin/gh auth token 2>/dev/null || true)
    if [ -n "$GH_TOKEN" ]; then
      sed -i "s/REPLACE_WITH_YOUR_TOKEN/$GH_TOKEN/" "$HOME/.kiro/settings/mcp.json"
    fi
  '';
}
