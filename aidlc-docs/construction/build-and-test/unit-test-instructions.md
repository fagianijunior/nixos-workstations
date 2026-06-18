# Unit Test Execution — Neovim Integration

## Contexto

No ecossistema NixOS, "unit tests" são implementados via `runNixOSTest` (testes em VM). O teste `neovim-test.nix` verifica:

1. Neovim inicia sem erros
2. Todos 8 LSPs estão disponíveis no PATH
3. Todos 8 formatadores estão disponíveis no PATH
4. 13 plugins carregam sem erros (via `require()`)
5. Colorscheme catppuccin está ativo
6. Treesitter parsers (>= 20) estão instalados

## Executar Teste de Neovim

### 1. Executar via nix build
```bash
cd /home/terabytes/Workspace/fagianijunior/nixos
nix build .#checks.x86_64-linux.neovim -L
```
O flag `-L` mostra logs em tempo real.

### 2. Verificar Resultado
- **Sucesso**: Derivação construída sem erros, link simbólico `result/` criado
- **Falha**: Erro no output com detalhes do teste que falhou

### 3. Executar Todos os Testes do Projeto
```bash
nix flake check -L
```
Executa TODOS os 11 testes (boot, pipewire, networking, bluetooth, gpu, hyprland, desktop-tools, security, power-management, home-manager, neovim).

## Resultados Esperados

| Teste | Verificação | Status |
|-------|-------------|--------|
| Neovim starts | `nvim --headless +qall` | ✅ |
| LSPs in PATH | `which nixd terraform-ls ...` | ✅ |
| Formatters in PATH | `which nixpkgs-fmt prettier ...` | ✅ |
| Plugins load | `lua require("telescope")` etc. | ✅ |
| Colorscheme | `g:colors_name == catppuccin` | ✅ |
| Treesitter parsers | `>= 20 parser/*.so files` | ✅ |

## Fix Failing Tests

Se testes falham:
1. Verificar output com `-L` para identificar qual assertion falhou
2. Se LSP/formatter não encontrado: verificar nome do pacote em `home/neovim/default.nix` extraPackages
3. Se plugin não carrega: verificar nome do require() no arquivo Lua correspondente
4. Se colorscheme errado: verificar ordem de carregamento (catppuccin.lua deve ser primeiro plugin)
5. Rebuildar: `nix build .#checks.x86_64-linux.neovim -L`
