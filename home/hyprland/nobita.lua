---@diagnostic disable: undefined-global
-- Hyprland Lua configuration — HOST: nobita (Desktop)
--
-- Concatenado após common.lua pelo Nix (ver home/default.nix). Reutiliza a
-- global `mainMod` definida em common.lua.
--
-- Hardware:
--   - DP-3     : monitor real (LG ULTRAWIDE 3440x1440) — único monitor físico.
--   - HDMI-A-1 : HDMI dummy plug (BBC HDP-V104, serial demoset-1). É o
--                "monitor de backup". Fica DESABILITADO enquanto o DP-3
--                estiver presente; é habilitado automaticamente quando o DP-3
--                cai (desligado no botão físico, que derruba o link DP), de
--                modo que a saída da GPU continue ativa (para ollama remoto) e
--                a sessão permaneça renderizando (para Steam Link remoto).
--
-- Comportamento resumido:
--   - DP-3 ligado  (modo local)  = só o LG, com os workspaces 1-10; dummy OFF.
--   - DP-3 desligado (modo remoto) = o dummy assume a exibição como se fosse um
--     monitor real, herdando os workspaces migrados pelo Hyprland.
--
-- É o análogo desktop do lid switch do doraemon: lá, fechar a tampa desabilita
-- o eDP-1 e migra tudo pro HDMI; aqui, desligar o DP-3 habilita o dummy e migra
-- tudo pra ele.
--
-- IMPORTANTE: usamos a API Lua NATIVA (`hl.*`), NÃO `hyprctl keyword` (que falha
-- com "can't work with non-legacy parsers" no parser Lua).

local real_monitor = "DP-3"
local dummy_monitor = "HDMI-A-1"

------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
--
-- Estado de boot (DP-3 presente): o LG fica sozinho em 0x0 e o dummy nasce
-- DESABILITADO (fora do layout, sem workspaces, sem foco). Isso elimina o bug
-- "dois workspaces lado a lado" — antes o dummy roubava o 0x0 e recebia um
-- workspace de overflow.
--
-- position = "0x0" explícito (não "auto") garante que o LG seja o monitor da
-- esquerda de forma determinística. O dummy não precisa de mode/position aqui;
-- quando habilitado dinamicamente (ver enable_dummy abaixo) definimos tudo.
hl.monitor({
	output = real_monitor,
	mode = "preferred",
	position = "0x0",
	scale = "1",
})
hl.monitor({
	output = dummy_monitor,
	disabled = true,
})

------------------------------------
---- WORKSPACES (single monitor) ----
------------------------------------

-- Nobita usa só um monitor por vez. Fixamos os workspaces 1-10 no DP-3 e damos
-- binds simples 1..0 (SEM a lógica de pares do doraemon, que é específica de
-- dual-monitor). Quando o DP-3 cai e o dummy assume, o Hyprland migra esses
-- workspaces para o único monitor restante automaticamente — mesmo
-- comportamento do disable do eDP-1 no doraemon. Por isso NÃO amarramos nenhum
-- workspace especial ao dummy: queremos que ele receba os workspaces normais.
for i = 1, 10 do
	hl.workspace_rule({ workspace = tostring(i), monitor = real_monitor })
end

-- Switch workspaces com mainMod + [1-0] (1..9, e 0 = workspace 10).
for i = 1, 10 do
	local key = tostring(i % 10)
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Sobrescreve os binds de scroll do common.lua. No nobita NÃO queremos criar
-- workspaces de overflow (o "11" que vazava pro dummy): `e+1` (expand) a partir
-- do workspace 10 CRIA um workspace novo. `r±1` (relative) navega só entre os
-- workspaces já existentes, sem criar novos. Como nobita.lua é concatenado
-- DEPOIS de common.lua, estes binds redefinem os de lá. common.lua fica
-- intacto, então o doraemon mantém `e+1/e-1`, que lá faz sentido (1-5/6-10).
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "r+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "r-1" }))

-------------------------------------
---- MONITOR DE BACKUP (dummy)   ----
-------------------------------------

-- "DP-3 presente e habilitado" = hl.get_monitor("DP-3") ~= nil. Um monitor
-- desabilitado SOME de get_monitors()/get_monitor(), então a presença no
-- layout é a fonte de verdade (o HL.Monitor nem expõe campo .disabled).
local function dp3_present()
	return hl.get_monitor(real_monitor) ~= nil
end

-- Habilita o dummy como monitor "real" em 0x0 (assume a exibição). Usamos
-- 1920x1080@60 com scale 1 em vez do mode "preferred" (3840x2160 4K): como não
-- há tela física, 4K só pesa a renderização e o encode do Steam Link sem
-- nenhum ganho. 1080p é bem mais leve para o streaming remoto.
local function enable_dummy()
	hl.monitor({
		output = dummy_monitor,
		disabled = false,
		mode = "1920x1080@60",
		position = "0x0",
		scale = "1",
	})
	-- Força o foco no workspace 9 (fixo) assim que o dummy assume. Sem isso, o
	-- Hyprland cria e foca um workspace NOVO e VAZIO no dummy (observado o ws 12
	-- com 0 janelas): os workspaces existentes migram pro dummy, mas o ativo é o
	-- vazio, então o dummy exibe tela preta e o Steam Link captura nada útil. O
	-- workspace 9 é o "workspace do modo remoto/Steam Link" dedicado — o usuário
	-- deixa o Steam lá para que o dummy sempre exiba conteúdo ao assumir.
	hl.dispatch(hl.dsp.focus({ workspace = 9 }))
end

-- Desabilita o dummy (sai do layout).
local function disable_dummy()
	hl.monitor({ output = dummy_monitor, disabled = true })
end

-- Reabilita o DP-3 em 0x0 (quando volta).
local function enable_dp3()
	hl.monitor({
		output = real_monitor,
		disabled = false,
		mode = "preferred",
		position = "0x0",
		scale = "1",
	})
end

-- Reação automática ao hotplug (núcleo do mecanismo, análogo ao lid switch do
-- doraemon mas disparado por eventos de monitor em vez de switch de tampa).
-- A cada evento reconsultamos o estado via dp3_present() e aplicamos o modo
-- correto — idempotente, seguro mesmo se o evento repetir.
--
-- Guarda dp3_present(): monitor.added/removed também dispara para o PRÓPRIO
-- dummy quando o habilitamos/desabilitamos. A guarda garante que a ação só
-- acontece em função da presença REAL do DP-3, evitando laço: habilitar o dummy
-- dispara monitor.added, mas nesse momento dp3_present() é false, então o ramo
-- do added não religa nada; quando o DP-3 volta de verdade, dp3_present() é true
-- e aí sim desabilitamos o dummy.

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

-- Fallback manual (SUPER+SHIFT+D): alterna explicitamente entre modo local e
-- remoto, independente de evento. Útil para forçar o Steam Link com o LG ainda
-- ligado, ou caso algum dia o link DP não caia sozinho. O normal é o
-- automático acima; este atalho é a válvula de escape.
--
-- { locked = true } para funcionar com a tela bloqueada (mesmo padrão do lid
-- switch e do XF86PowerOff no common.lua). SUPER+SHIFT+D não conflita com
-- common.lua (SUPER+D sozinho é fullscreen maximized; a combinação com SHIFT
-- está livre).
hl.bind(mainMod .. " + SHIFT + D", function()
	if hl.get_monitor(dummy_monitor) ~= nil then
		-- dummy ativo -> volta pro modo local (LG assume, dummy sai)
		enable_dp3()
		disable_dummy()
	else
		-- dummy desabilitado -> entra no modo remoto forçado: habilita o dummy
		-- e desabilita o DP-3 para o dummy ficar sozinho exibindo a sessão.
		-- enable_dummy() já foca o workspace 9 (ver acima), então o modo remoto
		-- forçado também abre no 9 — não precisa duplicar o foco aqui.
		enable_dummy()
		hl.monitor({ output = real_monitor, disabled = true })
	end
end, { locked = true })
