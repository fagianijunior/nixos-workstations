# Code Generation Plan — Devenv + Direnv Integration

## Context
- **Workspace Root**: /home/terabytes/Workspace/fagianijunior/nixos
- **Project Type**: Brownfield (NixOS flake com Home Manager)
- **Unit**: Single (devenv + direnv integration)
- **Files to Modify**: modules/common/default.nix, home/default.nix, flake.nix
- **Files to Create**: tests/devenv-direnv-test.nix

## Verified References
- **devenv package**: `devenv` (version 2.0.6 in nixpkgs-unstable)
- **devenv cachix URL**: `https://devenv.cachix.org`
- **devenv cachix public key**: `devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=`
- **Home Manager options**: `programs.direnv.config`, `programs.direnv.silent`
- **NixOS options**: `nix.settings.substituters`, `nix.settings.trusted-public-keys`

---

## Steps

### Step 1: Modify `modules/common/default.nix` — Add devenv system config
- [x] Add `devenv` to `environment.systemPackages`
- [x] Add `https://devenv.cachix.org` to `nix.settings.substituters`
- [x] Add `devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=` to `nix.settings.trusted-public-keys`
- [x] Ensure `nix.settings.trusted-users` keeps existing `[ "root" "@wheel" ]`

### Step 2: Modify `home/default.nix` — Enhance direnv configuration
- [x] Add `programs.direnv.silent = true`
- [x] Add `programs.direnv.config` with:
  - `global.warn_timeout = "30s"`
  - `global.hide_env_diff = true`
- [x] Keep existing `programs.direnv.enable = true` and `nix-direnv.enable = true`

### Step 3: Create `tests/devenv-direnv-test.nix` — Integration test
- [x] Use `pkgs.testers.nixosTest` pattern (consistent with existing tests)
- [x] Test that `devenv` binary exists in system PATH
- [x] Test that `direnv` binary exists in user PATH
- [x] Test that nix.conf contains the devenv cachix substituter
- [x] Test that nix.conf contains the devenv cachix trusted-public-key

### Step 4: Modify `flake.nix` — Register new test
- [x] Add `devenv-direnv` check entry pointing to `tests/devenv-direnv-test.nix`

### Step 5: Validate — Run `nix flake check`
- [x] Execute `nix flake check --no-build` to validate evaluation
- [x] Fix any errors that arise

---

## Summary
- **Total Steps**: 5
- **Files Modified**: 3 (modules/common/default.nix, home/default.nix, flake.nix)
- **Files Created**: 1 (tests/devenv-direnv-test.nix)
- **Estimated Scope**: ~50 lines of Nix code across all files
