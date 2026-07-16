{ lib, pkgs, ... }:

{
  # Generates ~/.config/nix/nix.conf on every activation.
  # Injects the GitHub token from gh CLI to allow Nix to fetch flake inputs
  # from GitHub without authentication errors (libgit2 "no callback set").
  # Next `home-manager switch` will regenerate it with a fresh gh token.
  home.activation.nixGithubToken = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/nix"

    # Rebuild nix.conf from scratch to avoid duplicate entries on re-runs
    : > "$HOME/.config/nix/nix.conf"

    GH_TOKEN=$(${pkgs.gh}/bin/gh auth token 2>/dev/null || true)
    if [ -n "$GH_TOKEN" ]; then
      echo "access-tokens = github.com=$GH_TOKEN" >> "$HOME/.config/nix/nix.conf"
    fi
  '';
}
