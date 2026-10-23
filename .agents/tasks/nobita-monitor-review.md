# Review — nobita: monitor de backup (dummy HDMI-A-1)

Veredito: **APPROVED** (sem blockers).

Alvo revisado: diff staged no repo `nixos` — principalmente
`home/hyprland/nobita.lua` (novo), com `home/hyprland.lua` renomeado para
`home/hyprland/common.lua`, `home/hyprland/doraemon.lua` (novo) e a fiação de
seleção por hostname em `home/default.nix`. Referência: `.agents/tasks/nobita-monitor-plan.md`.

## O que foi verificado

### 1. Fidelidade ao CASO/mecanismo do plano (automático + fallback manual)
O plano decidiu **CASO 1 (automático via evento) + fallback manual SUPER+SHIFT+D**.
A implementação entrega exatamente isso:

- Automático: `hl.on("monitor.removed", ...)` → `enable_dummy()` quando
  `not dp3_present()`; `hl.on("monitor.added", ...)` → `enable_dp3()` +
  `disable_dummy()` quando `dp3_present()`
  (`nobita.lua`, seção "MONITOR DE BACKUP"). A guarda `dp3_present()`
  (`hl.get_monitor("DP-3") ~= nil`) está presente nos dois ramos e previne o laço
  de eventos descrito no plano (§3.6). Idempotente.
- Fallback manual: `hl.bind(mainMod .. " + SHIFT + D", function() ... end,
  { locked = true })` alterna local/remoto, forçando `disabled = true` no DP-3 no
  modo remoto — igual ao §3.7 do plano.

### 2. Estado de boot (dummy desabilitado, DP-3 1-10, bug prevenido)
- `hl.monitor({ output = "HDMI-A-1", disabled = true })` no boot
  (`nobita.lua`). Dummy nasce fora do layout.
- `hl.monitor({ output = "DP-3", mode = "preferred", position = "0x0",
  scale = "1" })` — LG determinístico em 0x0.
- `for i = 1, 10 do hl.workspace_rule({ workspace = tostring(i),
  monitor = "DP-3" }) end` — workspaces 1-10 fixados ao DP-3. O
  `workspace_rule` do special:dummy da versão antiga foi removido, conforme §3.4.
- Bug "dois workspaces lado a lado": tratado na raiz. Os binds de scroll de
  overflow do common.lua (`mainMod + mouse_down → e+1` / `mouse_up → e-1`,
  common.lua linhas ~ "Scroll through existing workspaces") são
  **sobrescritos** em `nobita.lua` por `r+1`/`r-1` (relative, não cria overflow).
  Como `nobita.lua` é concatenado DEPOIS de `common.lua` e o último `hl.bind`
  com a mesma tecla vence, o override é efetivo. Confirmado na evidência do coder
  (verification §4b: common nas linhas 296-297, nobita nas 477-478 do Lua gerado).

### 3. API Lua nativa `hl.*` (sem `hyprctl keyword`, estilo doraemon)
- `nobita.lua` usa só `hl.monitor`, `hl.workspace_rule`, `hl.bind`,
  `hl.dsp.focus`, `hl.dsp.window.move`, `hl.get_monitor` e `hl.on`. Nenhum
  `hyprctl keyword`.
- Os estilos de chamada batem com os arquivos existentes: `hl.bind(key,
  hl.dsp.focus({...}))` é o mesmo padrão dos binds de scroll de `common.lua`;
  `hl.bind(key, function() ... end, { locked = true })` é o mesmo padrão do lid
  switch de `doraemon.lua`; `hl.monitor({ output, disabled, mode, position,
  scale })` é a mesma API do lid switch do doraemon.

### 4. Eventos `hl.on()` existem (não inventados)
Spot-check no stub autoritativo desta instalação
(`/nix/store/1knx0f2fj12573rgyzxgb9vnhrccw38a-hyprland-0.56.2/share/hypr/stubs/hl.meta.lua`):
- `HL.EventName` lista `"monitor.added"` (linha 14) e `"monitor.removed"` (17).
- `on fun(event: HL.EventName, cb: fun(...))` (857), `get_monitor` (844),
  `get_monitors` (847) confirmados.
- `HL.MonitorSpec` confirma os campos usados: `output` (obrigatório),
  `disabled`, `mode`, `position`, `scale`.
Nenhum evento ou campo inventado.

### 5. Impacto do common.lua no doraemon
`home/hyprland.lua` foi renomeado para `home/hyprland/common.lua`; o diff é uma
extração (12 inserções / 120 deleções), movendo as seções de monitor/workspace/
lid-switch para os arquivos de host. Os binds de scroll `e+1`/`e-1` PERMANECEM em
`common.lua`, logo o doraemon mantém o comportamento esperado (esquema 1-5/6-10).
A lógica específica do nobita (dummy, override de scroll `r±1`) vive só em
`nobita.lua`. Impacto no doraemon: nenhum — e confirmado pela evidência de que o
toplevel do doraemon ainda avalia (ver Verificação).

### 6. Seleção por hostname e staging
- `home/default.nix` monta `~/.config/hypr/hyprland.lua` via
  `pkgs.concatText "hyprland.lua" [ ./hyprland/common.lua ./hyprland/${hostName}.lua ]`,
  com `hostName = osConfig.networking.hostName`.
  `hosts/nobita/default.nix` define `networking.hostName = "nobita"` e
  `hosts/doraemon/default.nix` define `"doraemon"` — a seleção do fragmento está
  correta e sem `if/else` de hostname dentro do Lua.
- `git status`: `common.lua` (renomeado), `doraemon.lua` e `nobita.lua` estão
  STAGED (não há arquivos novos não rastreados além dos docs de task). O flake
  enxergará os arquivos.

## Verificação (lida das evidências do coder — NÃO re-executada)
Fonte: `.agents/tasks/nobita-monitor-verification.md`. Itens exigidos presentes:
- `nix eval` toplevel **nobita** → exit 0, store path (§1). Presente.
- `nix eval` toplevel **doraemon** → exit 0, store path — doraemon NÃO quebrou
  (§2). Presente (requisito obrigatório do step).
- `nix build` do toplevel do nobita → exit 0 (§3).
- `sudo nixos-rebuild switch --flake .#nobita` → sucesso, store path bate com o
  build (§6.1). Presente.
- `hyprctl reload` → `ok`, sem erro de parser (§6.2). Presente.
- `hyprctl monitors` com DP-3 ligado → HDMI-A-1 **ausente/disabled**, DP-3 em
  0x0 (§6.3); `hyprctl workspaces` → todos (inclusive o 11) no DP-3, nada no
  dummy (§6.4). Presente (requisito obrigatório do step).

Item em aberto declarado pelo coder (§6.5): teste FÍSICO do hotplug
(desligar/religar o LG no botão). Depende de ação física do usuário e está
corretamente marcado como não bloqueador; a lógica do evento está provada
estaticamente e os eventos foram confirmados no stub. Não é um blocker.

## Findings
Nenhum blocker.

Observação não bloqueante (não é finding, registrada só por transparência): o
seletor de workspace `r+1`/`r-1` é opaco ao type-check do Lua
(`HL.WorkspaceSelector = string|integer|HL.Workspace`) e sua aceitação pelo
dispatcher é comportamento de runtime. O plano escolheu `r±1` como a forma
relativa canônica e previu a validação por runtime; o prefixo `r` (relative) é
um conceito real do Hyprland (cf. `gestures.workspace_swipe_use_r` no stub). Não
há caminho de falha estabelecido que o torne um blocker.
