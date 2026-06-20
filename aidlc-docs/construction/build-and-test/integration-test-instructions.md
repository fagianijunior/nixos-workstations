# Integration Test Instructions — Devenv + Direnv Integration

## Purpose
Validar que devenv e direnv funcionam juntos em um projeto real após aplicar a configuração.

## Test Scenarios

### Scenario 1: devenv init + direnv allow
- **Description**: Criar um projeto devenv e verificar que direnv ativa automaticamente
- **Setup**: Aplicar configuração NixOS (`nixos-rebuild switch`)
- **Test Steps**:
  1. Criar diretório temporário: `mkdir /tmp/test-devenv && cd /tmp/test-devenv`
  2. Inicializar devenv: `devenv init`
  3. Permitir direnv: `direnv allow`
  4. Verificar que ambiente foi ativado (variáveis carregadas)
- **Expected Results**: direnv carrega o ambiente devenv automaticamente
- **Cleanup**: `rm -rf /tmp/test-devenv`

### Scenario 2: direnv silent mode
- **Description**: Verificar que direnv não emite logs excessivos
- **Setup**: Configuração aplicada com `programs.direnv.silent = true`
- **Test Steps**:
  1. Entrar em um diretório com `.envrc`
  2. Observar output do shell
- **Expected Results**: Nenhum log de direnv no prompt (modo silencioso)

### Scenario 3: nix-direnv caching
- **Description**: Verificar que nix-direnv cacheia environments corretamente
- **Setup**: Projeto com `use flake` no `.envrc`
- **Test Steps**:
  1. Criar `.envrc` com `use flake`
  2. Permitir: `direnv allow`
  3. Sair e entrar no diretório novamente
- **Expected Results**: Segunda entrada é instantânea (cached)

## Run Integration Tests

### Execução Manual (pós-deploy)
Estes testes são manuais e devem ser executados após `nixos-rebuild switch`:

```bash
# Verificar devenv está disponível
devenv version

# Verificar direnv está silencioso
cd /tmp && mkdir test-int && cd test-int
echo 'export TEST_VAR=hello' > .envrc
direnv allow
# Verificar: sem output de direnv, mas $TEST_VAR disponível
echo $TEST_VAR  # deve imprimir "hello"
rm -rf /tmp/test-int
```

## Nota
O teste automatizado em `tests/devenv-direnv-test.nix` cobre a validação de sistema (binários e nix.conf). Os cenários acima são complementares para validação pós-deploy.
