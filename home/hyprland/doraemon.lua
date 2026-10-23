---@diagnostic disable: undefined-global
-- Hyprland Lua configuration — HOST: doraemon (Notebook)
--
-- Concatenado após common.lua pelo Nix (ver home/default.nix). Reutiliza a
-- global `mainMod` definida em common.lua.
--
-- Hardware:
--   - eDP-1    : painel interno do notebook (monitor primário).
--   - HDMI-A-1 : monitor externo real (quando dockado).

------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
	output = "eDP-1",
	mode = "preferred",
	position = "auto",
	scale = "1",
}, {
	output = "HDMI-A-1",
	mode = "preferred",
	position = "auto",
	scale = "1",
})

--------------------------------
---- WORKSPACES (dual mon)  ----
--------------------------------

-- Paired workspaces: eDP-1 gets 1-5, HDMI-A-1 gets 6-10
-- When pressing mainMod+N, both monitors switch in sync (N and N+5)
-- When only one monitor is connected, all workspaces work on it normally

local primary_monitor = "eDP-1"
local secondary_monitor = "HDMI-A-1"

-- Bind workspaces to monitors (only effective when both monitors are connected)
for i = 1, 5 do
	hl.workspace_rule({ workspace = tostring(i), monitor = primary_monitor })
	hl.workspace_rule({ workspace = tostring(i + 5), monitor = secondary_monitor })
end

-- Helper: check if secondary monitor is connected
local function has_dual_monitors()
	local monitors = hl.get_monitors()
	return #monitors > 1
end

-- Helper: get paired workspace (1-5 pairs with 6-10)
local function get_pair(ws)
	if ws <= 5 then return ws + 5 end
	return ws - 5
end

-- Helper: focus a workspace on a specific monitor without triggering back_and_forth
local function focus_workspace_on_monitor(ws, monitor_name)
	local monitors = hl.get_monitors()
	for _, mon in ipairs(monitors) do
		if mon.name == monitor_name then
			-- Only dispatch if the workspace isn't already active on that monitor
			local active_workspace = mon.active_workspace
			if active_workspace == nil or active_workspace.id ~= ws then
				hl.dispatch(hl.dsp.focus({ workspace = ws }))
			end
			return
		end
	end
	-- Monitor not found, just focus the workspace
	hl.dispatch(hl.dsp.focus({ workspace = ws }))
end

-- Switch paired workspaces with mainMod + [1-5]
for i = 1, 5 do
	local key = tostring(i)
	hl.bind(mainMod .. " + " .. key, function()
		if has_dual_monitors() then
			focus_workspace_on_monitor(i + 5, secondary_monitor)
			focus_workspace_on_monitor(i, primary_monitor)
		else
			hl.dispatch(hl.dsp.focus({ workspace = i }))
		end
	end)
	hl.bind(mainMod .. " + SHIFT + " .. key, function()
		hl.dispatch(hl.dsp.window.move({ workspace = i }))
		if has_dual_monitors() then
			focus_workspace_on_monitor(i + 5, secondary_monitor)
			focus_workspace_on_monitor(i, primary_monitor)
		end
	end)
end

-- Switch paired workspaces with mainMod + [6-0] (6,7,8,9,0)
for i = 6, 10 do
	local key = tostring(i % 10)
	hl.bind(mainMod .. " + " .. key, function()
		if has_dual_monitors() then
			focus_workspace_on_monitor(i - 5, primary_monitor)
			focus_workspace_on_monitor(i, secondary_monitor)
		else
			hl.dispatch(hl.dsp.focus({ workspace = i }))
		end
	end)
	hl.bind(mainMod .. " + SHIFT + " .. key, function()
		hl.dispatch(hl.dsp.window.move({ workspace = i }))
		if has_dual_monitors() then
			focus_workspace_on_monitor(i - 5, primary_monitor)
			focus_workspace_on_monitor(i, secondary_monitor)
		end
	end)
end

--------------------
---- LID SWITCH ----
--------------------

-- Lid switch: desabilita o monitor interno (eDP-1) ao fechar a tampa e o
-- reabilita ao abrir. Isso evita que os workspaces 1-5 fiquem "presos" ao
-- painel interno quando o notebook está dockado (HDMI conectado) com a tampa
-- fechada. { locked = true } garante que funcione mesmo com a tela bloqueada.
-- Quando não há monitor externo, o logind hiberna (HandleLidSwitch=hibernate),
-- então o disable só tem efeito prático no cenário dockado.
--
-- IMPORTANTE: usamos hl.monitor() (API Lua nativa) e NÃO `hyprctl keyword`,
-- pois `keyword` não funciona com o parser Lua (retorna "can't work with
-- non-legacy parsers"). hl.monitor({ disabled = true }) remove o output do
-- layout, migrando workspaces/janelas para o(s) monitor(es) restante(s).
hl.bind("switch:on:Lid Switch", function()
	hl.monitor({ output = "eDP-1", disabled = true })
end, { locked = true })
hl.bind("switch:off:Lid Switch", function()
	hl.monitor({ output = "eDP-1", disabled = false, mode = "preferred", position = "auto", scale = "1" })
end, { locked = true })
