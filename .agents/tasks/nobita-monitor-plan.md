# Plano de implementação — nobita: monitor de backup (dummy HDMI) automático

Host: nobita (Desktop). Arquivo-alvo principal: `home/hyprland/nobita.lua`.
Regra do projeto: mudanças específicas do nobita ficam em `nobita.lua`; `common.lua`
só é tocado se inevitável. API Lua nativa do Hyprland (`hl.*`), parser Lua (NÃO
hyprlang, NÃO `hyprctl keyword`).

---

## 1. Resultado da investigação — CASO 1 (automático)

### Evidência de hardware/DRM

Estado coletado diretamente (antes de envolver o usuário):

- `cat /sys/class/drm/card1-DP-3/status` → `connected`
- `cat /sys/class/drm/card1-HDMI-A-1/status` → `connected`
- Conectores DRM presentes: `card1-DP-1 card1-DP-2 card1-DP-3 card1-HDMI-A-1 card1-Writeback-1`.
- `hyprctl version` → **Hyprland 0.56.2** (commit efb5099, Nix).

Estado de runtime com a config ATUAL (bugada), ambos monitores ligados:

```
Monitor HDMI-A-1 (ID 1): 3840x2160@59.98200 at 0x0     <- dummy virou o monitor da ESQUERDA
Monitor DP-3     (ID 0): 3440x1440@99.99700 at 2560x0  <- LG empurrado para a direita
```

- HDMI-A-1 estava com `active workspace: 11` e `disabled: false` — é exatamente o
  "dois workspaces lado a lado": o dummy em `0x0` recebendo o workspace de overflow
  (11) criado pelos binds de scroll `mainMod + mouse_down` (`e+1`) do common.lua.
- Observação: a config EM DISCO (`nobita.lua`) já difere da que está rodando
  (em disco o dummy está em `9999x9999`); a rodando é anterior. O baseline a
  corrigir é o comportamento, não o texto rodando.

### Teste físico do botão do DP-3 (realizado pelo usuário, conclusivo)

- Desligar o LG no **botão físico** → `card1-DP-3/status` passou `connected` →
  `disconnected` após ~8s; HDMI-A-1 permaneceu `connected`.
- Religar no botão → `card1-DP-3/status` voltou a `connected`. Transição limpa e
  reversível.

**Conclusão: CASO 1.** O LG derruba o link DP ao desligar no botão, o conector DRM
alterna `connected`/`disconnected`, e o Hyprland dispara eventos de hotplug de
monitor. Logo, dá para automatizar 100% via evento — exatamente o análogo
desktop do lid switch do doraemon. Mantemos também o atalho manual como fallback.

---

## 2. Nomes EXATOS dos eventos `hl.on()` suportados (CASO 1)

Fonte autoritativa: o stub gerado DESTA instalação 0.56.2,
`/nix/store/hky28da5xsknz0azmn3y89rj2sfg7psz-hyprland-0.56.2/share/hypr/stubs/hl.meta.lua`
(o mesmo referenciado por `~/.config/hypr/.luarc.json`). O alias `HL.EventName`
lista, entre outros:

- `"monitor.added"`      ← dispara quando um output volta (DP-3 religado)
- `"monitor.removed"`    ← dispara quando um output cai (DP-3 desligado)
- `"monitor.focused"`
- `"monitor.layout_changed"`

Assinatura: `hl.on(event: HL.EventName, cb: fun(...)): HL.EventSubscription`.

Decisão de design sobre o payload: NÃO dependemos do formato dos argumentos do
callback (o stub declara `cb: fun(...)`, sem tipar o payload). Em vez de inspecionar
o argumento, o callback CONSULTA o estado via `hl.get_monitors()` /
`hl.get_monitor("DP-3")` e decide — mesma filosofia robusta do doraemon, que no
lid switch nem usa payload. Fatos confirmados no stub, usados no design:

- `hl.get_monitors(): HL.Monitor[]` e `hl.get_monitor(selector): HL.Monitor|nil`.
- `HL.Monitor` tem os campos `.name` e `.description` (sem campo `.disabled`): um
  monitor **desabilitado some** de `get_monitors()`. Portanto "DP-3 presente e
  habilitado" = `hl.get_monitor("DP-3") ~= nil`.
- `hl.monitor(spec)` com `HL.MonitorSpec`: campos confirmados `output` (obrigatório),
  `disabled`, `mode`, `position`, `scale`. É a mesma API usada no lid switch do
  doraemon (`hl.monitor({ output = "eDP-1", disabled = true })`).

Nota: a página oficial https://wiki.hypr.land/configuring/core/advanced-configuration/events/
documenta `hl.on`, mas bloqueia fetch automatizado; o stub local da versão exata
(0.56.2) é a referência mais confiável e foi o usado aqui.

---

## 3. Conteúdo-alvo de `home/hyprland/nobita.lua` (prosa + pseudo-Lua)

Estrutura final do arquivo, espelhando o estilo do doraemon.lua (cabeçalho de
hardware, seção MONITORS, seção WORKSPACES, seção com `hl.on`/bind no fim).

### 3.1 Cabeçalho (comentário)

Manter o cabeçalho atual descrevendo o hardware. Atualizar a descrição do
HDMI-A-1 para o novo papel: "monitor de backup — fica DESABILITADO enquanto o
DP-3 estiver presente; é habilitado automaticamente quando o DP-3 cai (desligado
no botão), permitindo Steam Link remoto; serve também para manter a saída da GPU
ativa (ollama)". Documentar que DP-3 ligado = só LG, workspaces 1-10; DP-3
desligado = dummy assume.

### 3.2 Constantes

```lua
local real_monitor  = "DP-3"
local dummy_monitor = "HDMI-A-1"
```

### 3.3 Seção MONITORS — estado de boot (dummy desabilitado)

Por padrão, no boot com o DP-3 presente, o DP-3 fica em `0x0` sozinho e o dummy
nasce DESABILITADO (fora do layout, sem workspaces, sem foco). Isso elimina o bug
"dois lado a lado".

```lua
hl.monitor({ output = real_monitor, mode = "preferred", position = "0x0", scale = "1" })
hl.monitor({ output = dummy_monitor, disabled = true })
```

Notas de design:
- Usar `position = "0x0"` explícito no DP-3 (não `auto`) para garantir que o LG
  seja o monitor primário à esquerda, já que o bug atual é justamente o dummy
  roubar o `0x0`. Com o dummy desabilitado no boot, `auto` também funcionaria,
  mas `0x0` é determinístico.
- Scale do DP-3 = `1` (LG 3440x1440, como no estado de runtime observado).
- NÃO definir `position`/`mode` do dummy aqui — quando habilitado dinamicamente
  (ver 3.5) definimos tudo no momento; no boot ele só precisa de `disabled = true`.

### 3.4 Seção WORKSPACES — single monitor (1-10 no DP-3)

Nobita tem só um monitor usável por vez. Fixar 1-10 no DP-3 e dar binds simples
1..0 (sem a lógica de pares do doraemon, que é específica de dual-monitor).

```lua
for i = 1, 10 do
  hl.workspace_rule({ workspace = tostring(i), monitor = real_monitor })
end

for i = 1, 10 do
  local key = tostring(i % 10)  -- 1..9 e 0 = workspace 10
  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
```

Decisão: REMOVER o `hl.workspace_rule({ workspace = "special:dummy", ... })` da
versão atual. Com o dummy desabilitado no boot não há a quem fixar; quando o
dummy é habilitado dinamicamente ele simplesmente recebe os workspaces normais
(o usuário quer que o dummy "assuma a exibição como monitor real" quando o DP-3
cai), então NÃO queremos amarrar workspaces a um special nele. Fixar 1-10 ao DP-3
e, quando o DP-3 some, o Hyprland migra esses workspaces para o único monitor
restante (o dummy) automaticamente — mesmo comportamento do disable do eDP-1 no
doraemon.

### 3.5 Helpers + comutação de modo (local/remoto)

Duas funções auxiliares e uma função de modo. "Modo local" = DP-3 on + dummy off.
"Modo remoto" = DP-3 off (desabilitado no Hyprland) + dummy on.

```lua
local function dp3_present()
  return hl.get_monitor(real_monitor) ~= nil
end

-- Habilita o dummy como monitor "real" em 0x0 (assume a exibição).
local function enable_dummy()
  hl.monitor({
    output = dummy_monitor,
    disabled = false,
    mode = "preferred",   -- 3840x2160@59.98
    position = "0x0",
    scale = "1.5",         -- scale observado do dummy
  })
end

-- Desabilita o dummy (sai do layout).
local function disable_dummy()
  hl.monitor({ output = dummy_monitor, disabled = true })
end

-- Reabilita o DP-3 em 0x0 (quando volta).
local function enable_dp3()
  hl.monitor({ output = real_monitor, disabled = false, mode = "preferred", position = "0x0", scale = "1" })
end
```

Observações:
- `scale = "1.5"` para o dummy reproduz o scale que o usuário já usa (dado do
  `hyprctl monitors`: dummy scale 1.5). Steam Link renderiza na resolução lógica
  resultante; se o usuário preferir 1:1 depois, é trocar para "1".
- `mode = "preferred"` no dummy = 3840x2160@59.98 (modo preferido confirmado).

### 3.6 Reação automática aos eventos de hotplug (núcleo do CASO 1)

Espelha o lid switch do doraemon, mas disparado por `monitor.removed` /
`monitor.added` em vez de `switch:on/off:Lid Switch`. A cada evento, reconsulta o
estado e aplica o modo correto (idempotente — seguro mesmo se o evento repetir):

```lua
-- DP-3 caiu (desligado no botão): o dummy assume a exibição.
hl.on("monitor.removed", function()
  if not dp3_present() then
    enable_dummy()
  end
end)

-- DP-3 voltou (religado): volta tudo pro LG e desabilita o dummy.
hl.on("monitor.added", function()
  if dp3_present() then
    enable_dp3()
    disable_dummy()
  end
end)
```

Racional da guarda `dp3_present()`: `monitor.added`/`removed` também dispara para
o próprio dummy quando o habilitamos/desabilitamos. A guarda garante que a ação
só acontece em função da presença REAL do DP-3, evitando laço (habilitar o dummy
dispara `monitor.added`, mas como `dp3_present()` é false nesse momento, o ramo do
`added` não religa nada; quando o DP-3 volta de verdade, `dp3_present()` é true e
aí sim desabilitamos o dummy).

### 3.7 Atalho manual de fallback (SUPER+SHIFT+D — confirmado pelo usuário)

Alterna explicitamente entre modo local e remoto, independente de evento. Útil se
algum dia o link não cair (ex. outro monitor) ou para testar/forçar Steam Link
com o LG ainda ligado.

```lua
hl.bind(mainMod .. " + SHIFT + D", function()
  if hl.get_monitor(dummy_monitor) ~= nil then
    -- dummy está ativo -> volta pro modo local
    enable_dp3()
    disable_dummy()
  else
    -- dummy desabilitado -> entra no modo remoto
    enable_dummy()
    -- opcional: desabilitar o DP-3 para o dummy ficar sozinho
    hl.monitor({ output = real_monitor, disabled = true })
  end
end, { locked = true })
```

Notas:
- `{ locked = true }` para funcionar com a tela bloqueada (mesmo padrão do
  lid switch e do XF86PowerOff no common.lua).
- O toggle manual pode desabilitar o DP-3 (modo remoto forçado). Quando o usuário
  religa via toggle, `enable_dp3()` o traz de volta. Documentar no comentário que
  SUPER+SHIFT+D é o fallback e que o normal é o automático.
- SUPER+SHIFT+D não conflita: verifiquei `common.lua` — SUPER+D sozinho existe
  (maximize), mas a combinação com SHIFT está livre; demais SHIFT usados são
  V,B,T,Z,H,F,S,P,R.

---

## 4. Tecla do keybind manual

**SUPER+SHIFT+D** — confirmada e aprovada pelo usuário. Sem conflito em
`common.lua`/`nobita.lua` (checado via grep: nenhum bind para SUPER+SHIFT+D;
SUPER+D sozinho é `fullscreen maximized` e não colide com a combinação SHIFT).

---

## 5. Binds de scroll (`mainMod + mouse_down/up`) — sobrescrever no nobita.lua

Os binds `mainMod + mouse_down → focus workspace e+1` e `mouse_up → e-1` em
common.lua são a CAUSA do workspace "11": `e+1` a partir do workspace 10 CRIA um
workspace novo de overflow, que caía no dummy. Mesmo com o dummy desabilitado no
boot, o `e+1`/`e-1` ainda pode criar workspaces fora do intervalo 1-10.

**Decisão: sobrescrever esses dois binds em `nobita.lua`** (não tocar em
common.lua — doraemon continua com `e+1/e-1`, que lá faz sentido no esquema
1-5/6-10). Como `nobita.lua` é concatenado DEPOIS de common.lua, um novo
`hl.bind` com a mesma tecla redefine o anterior. Trocar `e±1` (expand: cria) por
`r±1` (relative: NÃO cria, só navega entre workspaces existentes), limitando o
scroll ao conjunto já existente:

```lua
-- Sobrescreve os binds de scroll do common.lua: no nobita não queremos criar
-- workspaces de overflow (o "11" que vazava pro dummy). r±1 navega só entre
-- workspaces existentes, sem criar novos.
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "r+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "r-1" }))
```

Impacto no doraemon: NENHUM. A mudança vive só em nobita.lua; common.lua fica
intacto, então doraemon mantém `e+1/e-1`. Validar na verificação que os dois
binds do nobita realmente sobrescrevem (último `hl.bind` com a mesma key vence).

Nota: se durante a implementação se constatar que `r±1` não é aceito pelo
dispatcher nesta versão, a alternativa é uma função que faz wrap manual entre 1 e
10 via `hl.get_active_workspace()`; mas `r±1` (relative) é a forma canônica e
deve bastar. Não deixar "e ou r" em aberto no código: usar `r±1`.

---

## 6. Passos de validação (ordenados)

Todos a partir de `/home/terabytes/Workspace/fagianijunior/nixos`.

1. **Stage dos arquivos** (o Nix só enxerga arquivos rastreados pelo git no flake):
   ```bash
   git add home/hyprland/nobita.lua
   ```
   (Se, e somente se, common.lua acabar sendo tocado — NÃO é o plano — incluir
   também `git add home/hyprland/common.lua`.)
   Esperado: `git status -sb` mostra nobita.lua staged.

2. **Avaliar o toplevel do nobita sem erro**:
   ```bash
   nix eval .#nixosConfigurations.nobita.config.system.build.toplevel
   ```
   Esperado: imprime um path `/nix/store/...-nixos-system-nobita-...` sem erro de
   avaliação (valida que o `concatText` e o módulo home-manager montam).

3. **Avaliar o toplevel do doraemon sem erro** (garante que nada quebrou o host
   que compartilha common.lua):
   ```bash
   nix eval .#nixosConfigurations.doraemon.config.system.build.toplevel
   ```
   Esperado: imprime o path do sistema do doraemon sem erro.

4. **Aplicar no nobita**:
   ```bash
   sudo nixos-rebuild switch --flake .#nobita
   ```
   Esperado: build + switch concluem; `~/.config/hypr/hyprland.lua` reaponta para
   um novo path do /nix/store.

5. **Recarregar o Hyprland**:
   ```bash
   hyprctl reload
   ```
   Esperado: reload sem erro (sem "non-legacy parsers", pois usamos `hl.*`).

6. **Verificação de runtime — DP-3 ligado (modo local)**:
   ```bash
   hyprctl monitors | grep -E "Monitor (DP-3|HDMI-A-1)|disabled|active workspace|at "
   hyprctl monitors all | grep -E "Monitor HDMI-A-1" -A2
   ```
   Esperado:
   - DP-3 presente, `at 0x0`, com os workspaces 1-10;
   - HDMI-A-1 AUSENTE de `hyprctl monitors` (está desabilitado) — e, em
     `hyprctl monitors all`, aparece como `disabled: true`;
   - NENHUM workspace (ex. 11) no dummy; nada "lado a lado".

7. **Verificação de runtime — DP-3 desligado no botão (modo remoto, automático)**:
   Desligar o LG no botão; aguardar ~10s; então:
   ```bash
   cat /sys/class/drm/card1-DP-3/status   # esperado: disconnected
   hyprctl monitors | grep -E "Monitor|at |active workspace"
   ```
   Esperado: DP-3 some de `hyprctl monitors`; HDMI-A-1 aparece habilitado em
   `0x0` com os workspaces migrados (dummy assumiu a exibição).
   Religar o LG; aguardar ~10s:
   ```bash
   cat /sys/class/drm/card1-DP-3/status   # esperado: connected
   hyprctl monitors | grep -E "Monitor|at |disabled"
   ```
   Esperado: DP-3 volta em `0x0` com 1-10; HDMI-A-1 volta a desabilitado/ausente.

8. **Verificação do fallback manual**: com o LG ligado, pressionar
   **SUPER+SHIFT+D** e repetir o `hyprctl monitors`: o dummy deve habilitar
   (modo remoto forçado); pressionar de novo deve voltar ao modo local (dummy
   desabilitado, DP-3 em 0x0).

9. **(Opcional) flake check** se houver tempo — o repo tem checks incluindo
   `hyprland`:
   ```bash
   nix build .#checks.x86_64-linux.hyprland
   ```
   Esperado: build do check passa. (Não substitui a verificação de runtime acima,
   que é a que valida o comportamento real do hotplug.)

---

## 7. Resumo da decisão de design

- **CASO 1 (automático)** confirmado empiricamente: o LG derruba o link DP ao
  desligar no botão → eventos `monitor.removed`/`monitor.added` (Hyprland 0.56.2).
- Núcleo: `hl.on("monitor.removed", ...)` habilita o dummy; `hl.on("monitor.added", ...)`
  reabilita o DP-3 e desabilita o dummy — guardado por `hl.get_monitor("DP-3")`
  para evitar laço de eventos. Espelha o lid switch do doraemon.
- **Fallback manual** SUPER+SHIFT+D (confirmado) alterna modo local/remoto.
- Boot: dummy `disabled = true`, DP-3 em `0x0`, workspaces 1-10 fixados ao DP-3 —
  elimina o bug "dois lado a lado".
- Binds de scroll sobrescritos em nobita.lua (`r±1` em vez de `e±1`) para não
  criar workspaces de overflow. common.lua intacto → zero impacto no doraemon.
- Tudo via API Lua `hl.*`; nenhum `hyprctl keyword`. Mudança isolada em
  `home/hyprland/nobita.lua`.
