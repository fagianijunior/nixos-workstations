#!/usr/bin/env bash
# Captura o estado do Hyprland antes/depois de desligar e religar o DP-3.
# Uso: rode este script e siga as instruções na tela. Ele grava tudo em
#   /tmp/hotplug-capture.txt
# Depois de terminar, mande o conteúdo desse arquivo.

OUT=/tmp/hotplug-capture.txt
: > "$OUT"

snap() {
  local label="$1"
  {
    echo "========================================"
    echo "=== $label  ($(date +%H:%M:%S)) ==="
    echo "========================================"
    echo "--- DRM status ---"
    for d in DP-3 HDMI-A-1; do
      printf '%s: %s\n' "$d" "$(cat /sys/class/drm/card1-${d}/status 2>/dev/null)"
    done
    echo "--- monitors (ativos) ---"
    hyprctl monitors | grep -E 'Monitor |^\s+[0-9]+x[0-9]+|active workspace|scale:|at [0-9]|disabled'
    echo "--- monitors all (inclui desabilitados) ---"
    hyprctl monitors all | grep -E 'Monitor |disabled|^\s+[0-9]+x[0-9]+'
    echo "--- workspaces (qual monitor) ---"
    hyprctl workspaces | grep -E 'workspace ID|monitorID|lastwindow'
    echo "--- active workspace + janela focada ---"
    hyprctl activeworkspace | grep -E 'workspace ID|monitor|windows|lastwindow'
    echo "--- clients (janela: workspace / monitor) ---"
    hyprctl clients | grep -E 'class:|workspace:|monitor:|title:' | sed 'N;N;N;s/\n/ | /g'
    echo
  } >> "$OUT"
}

echo ">>> 1/3: capturando estado INICIAL (DP-3 ligado, Steam aberto no ws 1)..."
snap "ANTES - DP-3 ligado"
echo ">>> Agora DESLIGUE o monitor LG no botao. Aguardando 20s..."
sleep 20
echo ">>> 2/3: capturando estado com DP-3 DESLIGADO..."
snap "DEPOIS - DP-3 desligado (dummy assumiu)"
echo ">>> Agora RELIGUE o monitor LG no botao. Aguardando 20s..."
sleep 20
echo ">>> 3/3: capturando estado FINAL (DP-3 religado)..."
snap "FINAL - DP-3 religado"
echo ">>> Pronto. Conteudo salvo em $OUT"
echo ">>> Mande o conteudo: cat $OUT"
