# Integration Test Instructions — Neovim Integration

## Propósito

Verificar que o módulo Neovim integra corretamente com o restante do sistema:
- Home Manager activation inclui Neovim
- Catppuccin autoEnable aplica tema ao Neovim
- Pacotes de home.packages não conflitam com extraPackages
- nixos-rebuild switch funciona sem erros

## Cenário 1: Home Manager Integration

### Descrição
Verificar que o Neovim é corretamente ativado pelo Home Manager como parte da configuração do usuário terabytes.

### Comando
```bash
# O teste neovim-test.nix já cobre isso via runNixOSTest:
nix build .#checks.x86_64-linux.neovim -L
```

### Verificação Manual (pós-deploy)
```bash
# Verificar que Home Manager gerencia Neovim
home-manager generations | head -1

# Verificar que nvim é o EDITOR
echo $EDITOR  # Deve ser "nvim"
echo $VISUAL  # Deve ser "nvim"
```

## Cenário 2: Catppuccin Theme Integration

### Descrição
Verificar que o catppuccin autoEnable do Home Manager funciona em conjunto com os overrides Lua.

### Verificação
```bash
# Dentro do Neovim:
:echo g:colors_name
# Esperado: catppuccin-macchiato

# Verificar integração com telescope:
:Telescope colorscheme
# O tema deve estar listado e ativo
```

## Cenário 3: Não-Conflito com home.packages

### Descrição
Verificar que a remoção de `nil`, `terraform-ls`, `solargraph` do home.packages não quebra outros componentes.

### Verificação
```bash
# nixd (mantido em home.packages) deve estar disponível para Kiro MCP
which nixd

# terraform-ls (agora em extraPackages do neovim) ainda disponível globalmente
which terraform-ls

# LSPs só acessíveis dentro do wrapper do nvim?
# Não — extraPackages adiciona ao PATH do usuário via wrapper
```

## Cenário 4: Coexistência com Outros Módulos

### Descrição
Verificar que nenhum módulo existente (quickshell, taskwarrior, etc.) é afetado.

### Comando
```bash
# Executar todos os testes para verificar que nada quebrou:
nix flake check --no-build
# Esperado: all checks passed
```

## Status de Integração

| Cenário | Método de Teste | Status |
|---------|----------------|--------|
| Home Manager Integration | runNixOSTest | ✅ Coberto por neovim-test.nix |
| Catppuccin Theme | runNixOSTest (colorscheme check) | ✅ Coberto |
| Não-Conflito packages | nix flake check --no-build | ✅ Passa |
| Coexistência módulos | nix flake check --no-build | ✅ Passa |
