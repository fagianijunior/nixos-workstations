# Unit Test Execution — Devenv + Direnv Integration

## Run Unit Tests

### 1. Execute All NixOS Tests (evaluation only)
```bash
cd ~/Workspace/fagianijunior/nixos
nix flake check --no-build
```

Este comando avalia todas as derivações de teste sem construí-las. Garante que a configuração é sintaticamente correta e avalia sem erros.

### 2. Execute Only the Devenv-Direnv Test (full build)
```bash
nix build .#checks.x86_64-linux.devenv-direnv
```

Este comando constrói e executa o teste NixOS VM completo para devenv-direnv.

### 3. Review Test Results
- **Expected**: Todos os assertions passam (devenv binary, nix.conf entries)
- **Test Report**: Output no terminal com status pass/fail
- **Cenários cobertos**:
  - devenv binary existe no PATH do sistema
  - devenv version executa com sucesso
  - nix.conf contém substituter do devenv cachix
  - nix.conf contém trusted-public-key do devenv cachix
  - nix.conf contém @wheel em trusted-users
  - nix.conf contém flakes em experimental-features

### 4. Fix Failing Tests
Se testes falharem:
1. Verificar output de erro do NixOS test
2. Verificar que `modules/common/default.nix` contém as entradas corretas
3. Verificar que `devenv` está em `environment.systemPackages`
4. Re-executar `nix flake check --no-build`
