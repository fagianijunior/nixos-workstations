# Perguntas de Esclarecimento — Integração Neovim

Por favor, responda as perguntas preenchendo a letra da opção após o tag [Answer]:

## Question 1
A configuração de referência em `to_implement/neovim/` tem LSPs para Lua, Nix, TypeScript/JavaScript e Python. Você mencionou foco em Terraform, Nix, Ruby, PHP e AWS. Quais LSPs (Language Servers) devem ser configurados?

A) Mínimo: Nix (nil/nixd), Terraform (terraform-ls), Ruby (solargraph), PHP (intelephense), Lua (lua-language-server)
B) Completo: Todos do item A + Python (pyright), TypeScript/JavaScript (ts_ls), Bash (bash-language-server)
C) Máximo: Todos do item B + Go (gopls), Rust (rust-analyzer), Docker (dockerfile-language-server), YAML (yaml-language-server)
D) Customizado: Nix (nixd — já em home.packages), Terraform (terraform-ls — já em home.packages), Ruby (solargraph — já em home.packages), PHP (intelephense), Python (pyright), Lua (lua-language-server), Bash (bash-language-server)
X) Other (please describe after [Answer]: tag below)

[Answer]: D. Adiciona o Docker tambem.

## Question 2
Para o LSP de Nix, qual servidor prefere? Você já tem tanto `nil` quanto `nixd` em `home.packages`.

A) nixd (mais moderno, suporta flakes nativamente, completion de opções NixOS/home-manager)
B) nil (mais estável, mais leve)
C) Ambos configurados (nixd como primário)
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 3
Quais formatadores (formatters) devem ser configurados no conform.nvim?

A) Essenciais: nixpkgs-fmt (Nix), terraform fmt (Terraform), prettier (JSON/YAML/Markdown), stylua (Lua)
B) Completo: Todos do item A + rubocop (Ruby), php-cs-fixer (PHP), black (Python), shfmt (Bash)
C) Máximo: Todos do item B + rustfmt (Rust), gofmt (Go)
X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 4
Sobre plugins adicionais além dos que estão na referência (telescope, neo-tree, gitsigns, which-key, lualine, conform, toggleterm, nvim-cmp, treesitter, luasnip, catppuccin):

A) Usar exatamente os mesmos plugins da referência (sem adições)
B) Adicionar: indent-blankline (guias de indentação), autopairs (auto-fechar parênteses/chaves), comment.nvim (comentar linhas/blocos), bufferline (tabs visuais)
C) Adicionar os do item B + trouble.nvim (lista de diagnósticos), todo-comments (highlight de TODO/FIXME), nvim-surround (manipular surroundings)
D) Mínimo: Remover toggleterm (já usa wezterm com splits) e manter o resto da referência
X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 5
Sobre Treesitter parsers — a referência tem: lua, nix, python, typescript, javascript, tsx, rust, go, bash, json, yaml, toml, markdown, html, css, vim, vimdoc, terraform, hcl. Deseja adicionar mais?

A) Manter os da referência + adicionar: ruby, php, dockerfile, sql, regex, diff, gitcommit
B) Manter exatamente os da referência
C) Manter os da referência + adicionar apenas: ruby, php, dockerfile
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 6
A referência usa `initLua` com `builtins.readFile` para inline toda a config Lua. Uma alternativa mais moderna é usar `xdg.configFile` para colocar os arquivos em `~/.config/nvim/` e deixar o Neovim carregá-los normalmente com `require()`. Qual abordagem prefere?

A) `xdg.configFile` — arquivos em ~/.config/nvim/ (mais fácil de debugar, editar e testar sem rebuild)
B) `initLua` com `builtins.readFile` — tudo inline (mais puro Nix, config 100% imutável)
C) Híbrido: usar `xdg.configFile` com symlink para o repositório (editável sem rebuild, versionado no git)
X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 7
Sobre o tema Catppuccin para Neovim — o sistema já usa `catppuccin.autoEnable = true` via Home Manager. Como quer integrar no Neovim?

A) Confiar no `autoEnable` do catppuccin home-manager module (automático, sem config manual no Lua)
B) Configurar explicitamente no Lua (como na referência) para ter controle total sobre integrations (telescope, cmp, treesitter, etc.)
C) Usar o autoEnable MAS com overrides no Lua para integrações específicas
X) Other (please describe after [Answer]: tag below)

[Answer]: C

## Question 8
Deseja que a configuração do Neovim fique em um arquivo separado (`home/neovim.nix` ou `home/neovim/default.nix`) importado pelo `home/default.nix`, ou diretamente no `home/default.nix`?

A) Arquivo separado `home/neovim/default.nix` com subpasta para configs Lua (organização clara)
B) Arquivo separado `home/neovim.nix` simples (sem subpasta)
C) Diretamente no `home/default.nix` (menos arquivos)
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 9
Sobre keybindings — a referência tem um conjunto completo (space como leader, window navigation, buffer nav, etc.). Deseja manter o mesmo esquema ou modificar algo?

A) Manter o mesmo esquema de keybindings da referência
B) Manter mas adicionar keybindings para Terraform (plan, apply, validate) via toggleterm ou custom commands
C) Reescrever completamente (se sim, descreva as preferências no [Answer]:)
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 10
Sobre testes — a configuração do projeto usa `runNixOSTest`. Deseja testes para o Neovim?

A) Sim — teste básico (Neovim inicia, plugins carregam, LSPs respondem)
B) Sim — teste completo (básico + verificação de cada LSP, formatadores funcionam, treesitter parsers instalados)
C) Não — sem testes para Neovim (confiar na avaliação do nix flake check)
X) Other (please describe after [Answer]: tag below)

[Answer]: B

