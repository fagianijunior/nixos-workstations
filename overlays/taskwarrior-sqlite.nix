# Overlay que corrige o build do taskwarrior3 3.5.0 (nixpkgs-unstable).
#
# Erro evitado (falha no link do crate Rust `taskchampion`):
#   ld.bfd: cannot find -lsqlite3: No such file or directory
#   error: could not compile `taskchampion` (lib) due to 1 previous error
#
# Motivo: o taskchampion 3.1.0 passou a linkar dinamicamente com a libsqlite3
# do sistema, mas a derivação do nixpkgs não tem `sqlite` em buildInputs.
#
# Por que é seguro: só adiciona uma dependência de build/runtime (sqlite) que o
# linker já pede; não altera fonte, versão nem comportamento do `task`.
#
# COMO RETESTAR (quando quiser ver se o nixpkgs já corrigiu):
#   1. Remova a linha deste overlay em flake.nix (lista `overlays`).
#   2. Rode: nix build '.#nixosConfigurations.nobita.pkgs.taskwarrior3'
#   3. Se compilar sem o overlay, apague este arquivo.
final: prev: {
  taskwarrior3 = prev.taskwarrior3.overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [ final.sqlite ];
    # O taskchampion-lib é uma .a que referencia sqlite3_*; os executáveis C++
    # (task, calc, lex) precisam de -lsqlite3 explícito no link final.
    env = (old.env or { }) // {
      NIX_LDFLAGS = "-lsqlite3";
    };
  });
}
