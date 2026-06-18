# Documento de Requisitos — Integração Neovim

## Análise de Intenção

| Campo | Valor |
|-------|-------|
| **Requisição do Usuário** | Instalar e configurar Neovim com plugins e LSPs para desenvolvimento (Terraform, Nix, Ruby, PHP, AWS, etc.) |
| **Tipo de Requisição** | Nova Feature (módulo Home Manager para Neovim) |
| **Estimativa de Escopo** | Componente Único (home/neovim/ com múltiplos arquivos Lua) |
| **Estimativa de Complexidade** | Moderada (múltiplos LSPs, plugins, formatadores, integração com ecossistema existente) |
| **Referência** | to_implement/neovim/ (potencialmente desatualizada, usar apenas como base) |

---

## Requisitos Funcionais

### RF-01: Estrutura do Módulo

**Descrição**: Configuração do Neovim organizada como módulo Home Manager separado.

**Estrutura esperada**:
```
home/neovim/
├── default.nix           # Módulo principal (programs.neovim)
└── config/               # Arquivos de configuração Lua
    ├── options.lua       # Opções gerais do Neovim
    ├── keymaps.lua       # Keybindings globais
    └── plugins/          # Configuração por plugin
        ├── catppuccin.lua
        ├── telescope.lua
        ├── lsp.lua
        ├── cmp.lua
        ├── luasnip.lua
        ├── treesitter.lua
        ├── gitsigns.lua
        ├── neo-tree.lua
        ├── which-key.lua
        ├── lualine.lua
        ├── conform.lua
        ├── toggleterm.lua
        ├── indent-blankline.lua
        ├── autopairs.lua
        ├── comment.lua
        └── bufferline.lua
```

**Integração**: Importado via `./neovim` em `home/default.nix`.

### RF-02: Language Servers (LSP)

| LSP | Linguagem | Pacote Nix | Notas |
|-----|-----------|------------|-------|
| **nixd** | Nix | pkgs.nixd | Primário para Nix (suporte a flakes, opções NixOS/HM) |
| **terraform-ls** | Terraform/HCL | pkgs.terraform-ls | Já em home.packages |
| **solargraph** | Ruby | pkgs.rubyPackages.solargraph | Já em home.packages |
| **intelephense** | PHP | pkgs.nodePackages.intelephense | LSP premium para PHP |
| **pyright** | Python | pkgs.pyright | Type checking estático |
| **lua-language-server** | Lua | pkgs.lua-language-server | Com suporte a API do Neovim (vim global) |
| **bash-language-server** | Bash/Shell | pkgs.nodePackages.bash-language-server | Para scripts shell |
| **dockerfile-language-server** | Dockerfile | pkgs.nodePackages.dockerfile-language-server-nodejs | Para Dockerfiles |

**Funcionalidades LSP obrigatórias**:
- Go to definition (`gd`)
- Hover documentation (`K`)
- Go to references (`gr`)
- Rename symbol (`<leader>rn`)
- Code actions (`<leader>ca`)
- Diagnósticos inline com sinais e virtual text
- Integração com nvim-cmp para autocompletion

### RF-03: Formatadores (conform.nvim)

| Linguagem | Formatador | Pacote Nix |
|-----------|-----------|------------|
| Nix | nixpkgs-fmt | pkgs.nixpkgs-fmt |
| Terraform | terraform fmt | pkgs.terraform (built-in) |
| JSON/YAML/Markdown/HTML/CSS | prettier | pkgs.nodePackages.prettier |
| Lua | stylua | pkgs.stylua |
| Ruby | rubocop | pkgs.rubyPackages.rubocop |
| PHP | php-cs-fixer | pkgs.phpPackages.php-cs-fixer |
| Python | black | pkgs.black |
| Bash/Shell | shfmt | pkgs.shfmt |

**Comportamento**:
- Format on save habilitado (timeout 500ms, lsp_fallback)
- Keybinding manual: `<leader>cf`

### RF-04: Plugins

#### Plugins Base (da referência)
| Plugin | Função |
|--------|--------|
| catppuccin-nvim | Tema (Catppuccin Macchiato) |
| telescope-nvim | Fuzzy finder (arquivos, grep, buffers, comandos) |
| plenary-nvim | Biblioteca de funções (dep. telescope) |
| telescope-fzf-native-nvim | Sorting nativo para telescope |
| nvim-lspconfig | Configuração de Language Servers |
| nvim-cmp | Engine de autocompletion |
| cmp-nvim-lsp | Fonte: LSP |
| cmp-buffer | Fonte: Buffer atual |
| cmp-path | Fonte: Caminhos de arquivo |
| cmp_luasnip | Fonte: Snippets |
| cmp-cmdline | Fonte: Command-line |
| luasnip | Engine de snippets |
| friendly-snippets | Coleção de snippets pré-feitos |
| nvim-treesitter | Syntax highlighting avançado |
| nvim-treesitter-textobjects | Text objects baseados em treesitter |
| gitsigns-nvim | Integração Git inline |
| neo-tree-nvim | File explorer |
| nvim-web-devicons | Ícones de arquivo |
| nui-nvim | Biblioteca UI (dep. neo-tree) |
| which-key-nvim | Descoberta de keybindings |
| lualine-nvim | Statusline |
| conform-nvim | Formatação de código |
| toggleterm-nvim | Terminal integrado |

#### Plugins Adicionais (novos)
| Plugin | Função |
|--------|--------|
| indent-blankline-nvim | Guias visuais de indentação |
| nvim-autopairs | Auto-fechar parênteses, chaves, colchetes, aspas |
| comment-nvim | Comentar/descomentar linhas e blocos (gc, gcc) |
| bufferline-nvim | Tabs visuais para buffers abertos |

### RF-05: Treesitter Parsers

**Parsers instalados** (gerenciados via Nix, sem auto_install):
- **Programação**: lua, nix, python, typescript, javascript, tsx, rust, go, bash, ruby, php
- **Infra/Config**: terraform, hcl, dockerfile, json, yaml, toml, sql
- **Documentação**: markdown, html, css, vim, vimdoc
- **Utilities**: regex, diff, gitcommit

**Features habilitadas**:
- Highlight (syntax highlighting avançado)
- Indent (indentação inteligente, exceto Python)
- Incremental selection (C-space)
- Text objects (af/if para funções, ac/ic para classes, aa/ia para parâmetros)
- Folding baseado em treesitter (desabilitado por padrão)

### RF-06: Arquitetura de Configuração

- **Método**: `initLua` com `builtins.readFile` (config imutável via Nix)
- **Organização**: Arquivos Lua separados por responsabilidade em `home/neovim/config/`
- **Loading order**: options → keymaps → plugins (catppuccin primeiro, depois resto)
- **Imutabilidade**: Toda configuração inline no derivation Nix (sem runtime require())

### RF-07: Tema Catppuccin

- **Integração**: `catppuccin.autoEnable = true` do Home Manager (automático)
- **Overrides Lua**: Configuração explícita no Lua para integrações específicas:
  - telescope
  - nvim-cmp
  - treesitter
  - gitsigns
  - neo-tree
  - indent-blankline
  - bufferline
  - lualine
- **Flavor**: macchiato (consistente com sistema)

### RF-08: Keybindings

**Leader key**: Space

**Esquema (baseado na referência)**:
- `<leader>f*` — Find/Search (Telescope)
- `<leader>h*` — Git Hunks (gitsigns)
- `<leader>c*` — Code Actions (LSP + format)
- `<leader>r*` — Refactoring (rename)
- `<leader>d*` — Diagnostics
- `<leader>w*` — Workspace
- `<leader>e` — Explorer (neo-tree toggle)
- `<leader>t*` — Terminal (toggleterm)
- `<leader>q/Q` — Quit
- LSP buffer-local: gd, gD, gr, gi, K, [d, ]d
- Window nav: C-h/j/k/l
- Buffer nav: S-h/S-l
- Resize: C-Up/Down/Left/Right

### RF-09: Opções do Neovim

- **programs.neovim.enable** = true
- **programs.neovim.defaultEditor** = true
- **programs.neovim.viAlias** = true
- **programs.neovim.vimAlias** = true
- **programs.neovim.vimdiffAlias** = true
- **withRuby** = false (gerenciamento manual via solargraph)
- **withPython3** = false (gerenciamento manual via pyright)
- Line numbers relativos
- Tab = 2 espaços
- Clipboard sistema (unnamedplus)
- Mouse habilitado
- Undo persistente (undofile)
- Sem backup/swap files

### RF-10: Integração com Projeto Existente

- **Importação**: Adicionar `./neovim` ao `imports` de `home/default.nix`
- **Limpeza de redundâncias**: Remover `nil` e `nixpkgs-fmt` de `home.packages` se já providos por `programs.neovim.extraPackages`
- **Variáveis de ambiente**: `EDITOR=nvim` e `VISUAL=nvim` já definidos em `home/default.nix`
- **Consistência**: Manter padrão existente do projeto (comentários, formatação Nix)

---

## Requisitos Não-Funcionais

### RNF-01: Compatibilidade

- NixOS Unstable (nixos-unstable channel)
- Home Manager master (follows nixpkgs)
- Neovim versão do nixpkgs (atualmente ~0.10.x)
- Todos os plugins via pkgs.vimPlugins (nixpkgs)
- Todos os LSPs/formatadores via pkgs (nixpkgs)

### RNF-02: Reprodutibilidade

- Toda configuração declarativa via Nix
- Plugins pinados pelo flake.lock
- Sem instalação runtime (sem :TSInstall, sem Mason, sem lazy.nvim)
- Treesitter parsers pré-compilados pelo Nix

### RNF-03: Performance

- Startup < 100ms (plugins pré-compilados, sem lazy loading necessário)
- LSPs iniciam on-demand por filetype
- Treesitter disable para arquivos > 100KB
- Sem plugins bloqueantes no startup

### RNF-04: Manutenibilidade

- Arquivos Lua separados por plugin (fácil localizar e modificar)
- Comentários explicativos em cada arquivo de configuração
- Documentação inline de keybindings
- pcall() para plugins opcionais (graceful degradation)

### RNF-05: Testabilidade

- Testes completos com `runNixOSTest`:
  - Neovim inicia sem erros
  - Cada LSP responde (health check)
  - Formatadores disponíveis no PATH
  - Treesitter parsers carregam
  - Plugins carregam sem erros
  - Colorscheme aplicado (catppuccin)
- Testes executáveis via `nix flake check`

### RNF-06: Segurança (Extension: Security Baseline)

- Sem credenciais hardcoded (SECURITY-12)
- Pacotes pinados via flake.lock (SECURITY-10)
- Nenhum download runtime de plugins/LSPs (SECURITY-13: integridade via Nix store)

---

## Decisões Técnicas

| Decisão | Escolha | Justificativa |
|---------|---------|---------------|
| LSP Nix | nixd | Mais moderno, suporte nativo a flakes e opções NixOS/HM |
| Config method | initLua + builtins.readFile | 100% imutável, consistente com filosofia Nix |
| Plugin manager | Nix (pkgs.vimPlugins) | Reprodutível, sem runtime installs |
| Formatador Nix | nixpkgs-fmt | Já usado no projeto, bem suportado |
| Theme | Catppuccin Macchiato (autoEnable + overrides) | Consistência com sistema |
| File structure | home/neovim/default.nix + config/ | Organização clara, separação de responsabilidades |
| Testes | runNixOSTest completo | Verificação de LSPs, formatadores, parsers |
| Toggleterm | Manter | Diferente de wezterm splits — útil para workflows dentro do editor |

---

## Regras de Segurança Aplicáveis

| Rule ID | Aplicabilidade | Notas |
|---------|---------------|-------|
| SECURITY-10 | ✅ Aplicável | Plugins e LSPs pinados via flake.lock |
| SECURITY-12 | ✅ Aplicável | Sem credenciais nos arquivos de config |
| SECURITY-13 | ✅ Aplicável | Integridade via Nix store (hashes) |
| Outros | N/A | Não aplicáveis a configuração de editor |

---

## Regras PBT Aplicáveis

| Rule ID | Aplicabilidade | Notas |
|---------|---------------|-------|
| PBT-02 | ✅ Enforced | Round-trip: módulo Nix produz config Neovim válida |
| PBT-03 | ✅ Enforced | Invariantes: LSPs configurados estão ativos |
| PBT-08 | ✅ Enforced | Reprodutibilidade: testes determinísticos |
| PBT-09 | ✅ Enforced | Framework: runNixOSTest |
| Outros | N/A | Não aplicáveis a configuração de editor |
