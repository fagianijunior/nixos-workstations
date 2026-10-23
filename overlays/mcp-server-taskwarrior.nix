# Overlay que empacota o mcp-server-taskwarrior (MCP server para o TaskWarrior).
#
# Motivo: o pacote NÃO existe no nixpkgs. A documentação upstream sugere
# `npm install -g mcp-server-taskwarrior`, o que em NixOS é um anti-padrão:
# escreve num prefixo global mutável fora da /nix/store, não é reprodutível e
# some a cada garbage collect. O `npx -y mcp-server-taskwarrior` tem o mesmo
# problema em menor escala (baixa do registry npm em runtime, precisa de rede).
#
# Solução: construir o pacote com buildNpmPackage a partir do fonte no GitHub,
# com as dependências node resolvidas de forma reprodutível (npmDepsHash fixo).
# O binário resultante fica na store e é referenciado por caminho absoluto no
# kiro-mcp.nix, sem npx nem npm global.
#
# IMPORTANTE: este server é só um wrapper que executa o binário `task` local.
# O TaskWarrior PRECISA estar instalado e no PATH (já vem via
# modules/common + o módulo taskwarrior do home). Sem `task`, o server inicia
# mas toda tool falha.
#
# Pin: o repo não publica tags git; a versão npm é 1.0.1. Pinado pelo commit
# HEAD (branch main) para reprodutibilidade.
#
# COMO ATUALIZAR (quando quiser subir de versão):
#   1. Atualize 'rev' para o novo commit (ou tag, se o upstream passar a taggear).
#   2. Zere 'srcHash' e 'npmDepsHash' (string "") e rode:
#        nix build '.#nixosConfigurations.nobita.pkgs.mcp-server-taskwarrior'
#   3. O Nix falha duas vezes informando os hashes corretos ("got: sha256-...").
#      Primeiro o do fetchFromGitHub (srcHash), depois o do npmDeps (npmDepsHash).
#      Cole cada hash no campo correspondente e rebuilde.
#
final: prev:
let
  rev = "29850c7a6991a35aea1402b6cba2cd01c7541205";
  # Hash do source (fetchFromGitHub). Preencha após o primeiro build falhar.
  srcHash = "sha256-pqXKVocSCk7ZZ6Q+SU/KVv5EYcZyGnbqPDwIGF3RjL8=";
  # Hash das dependências npm (derivado do package-lock.json). Preencha após o
  # segundo build falhar.
  npmDepsHash = "sha256-dShf5U8BaPjWV8AYbfgnigPC0HBgljurpANcghgDiZw=";
in
{
  mcp-server-taskwarrior = prev.buildNpmPackage {
    pname = "mcp-server-taskwarrior";
    version = "1.0.1";

    src = prev.fetchFromGitHub {
      owner = "awwaiid";
      repo = "mcp-server-taskwarrior";
      inherit rev;
      hash = srcHash;
    };

    inherit npmDepsHash;

    # O server chama o binário `task` em runtime; não é dependência de build,
    # mas deixamos registrado aqui para memória. A disponibilidade de `task` no
    # ambiente é garantida pelos módulos do sistema/home, não por este pacote.
    meta = {
      description = "MCP server for TaskWarrior";
      homepage = "https://github.com/awwaiid/mcp-server-taskwarrior";
      license = prev.lib.licenses.mit;
      mainProgram = "mcp-server-taskwarrior";
    };
  };
}
