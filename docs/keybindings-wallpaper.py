#!/usr/bin/env python3
"""Generate a Catppuccin Macchiato keybindings wallpaper (2560x1440)."""

from PIL import Image, ImageDraw, ImageFont
import os

# Catppuccin Macchiato palette
COLORS = {
    "base": "#24273a",
    "mantle": "#1e2030",
    "surface0": "#363a4f",
    "surface1": "#494d64",
    "text": "#cad3f5",
    "subtext0": "#a5adcb",
    "subtext1": "#b8c0e0",
    "blue": "#8aadf4",
    "green": "#a6da95",
    "teal": "#8bd5ca",
    "peach": "#f5a97f",
    "mauve": "#c6a0f6",
    "red": "#ed8796",
    "pink": "#f5bde6",
    "yellow": "#eed49f",
}

WIDTH = 3440
HEIGHT = 1440

# Keybindings organized by category
CATEGORIES = {
    "Aplicações": {
        "color": "blue",
        "binds": [
            ("SUPER + Space", "Terminal (WezTerm)"),
            ("SUPER + R", "Launcher"),
            ("SUPER + V", "Menu (Pypr)"),
            ("SUPER + Escape", "Logout (wlogout)"),
            ("SUPER + L", "Lock (hyprlock)"),
            ("SUPER + M", "Shutdown"),
        ],
    },
    "Janelas": {
        "color": "green",
        "binds": [
            ("SUPER + Q", "Fechar janela"),
            ("SUPER + F", "Fullscreen toggle"),
            ("SUPER + D", "Maximizar toggle"),
            ("SUPER + Shift + F", "Float toggle"),
            ("SUPER + P", "Pseudo-tile"),
            ("SUPER + J", "Toggle split"),
            ("SUPER + Z", "Zoom (Pypr)"),
        ],
    },
    "Foco / Navegação": {
        "color": "teal",
        "binds": [
            ("SUPER + ←↑→↓", "Mover foco"),
            ("SUPER + 1-0", "Workspace 1-10"),
            ("SUPER + Scroll", "Workspace ±1"),
            ("SUPER + S", "Scratchpad toggle"),
            ("SUPER + Shift + 1-0", "Mover p/ workspace"),
            ("SUPER + Shift + S", "Mover p/ scratchpad"),
            ("SUPER + LMB", "Arrastar janela"),
            ("SUPER + RMB", "Redimensionar"),
        ],
    },
    "Mídia / Screenshot": {
        "color": "mauve",
        "binds": [
            ("SUPER + Shift + P", "Screenshot (região)"),
            ("SUPER + Shift + R", "Gravar tela (toggle)"),
            ("XF86Audio ↑↓", "Volume ±"),
            ("XF86AudioMute", "Mute toggle"),
            ("SUPER + XF86Mute", "Mic mute"),
            ("XF86Audio Play/Pause", "Play/Pause"),
            ("XF86Audio Next/Prev", "Próx/Anterior"),
            ("XF86Brightness ↑↓", "Brilho ±"),
        ],
    },
    "Scratchpads (Pypr)": {
        "color": "yellow",
        "binds": [
            ("SUPER + Ctrl + V", "Volume mixer"),
            ("SUPER + Ctrl + Enter", "Dropdown terminal"),
        ],
    },
    "Neovim - Modos": {
        "color": "pink",
        "binds": [
            ("i / a", "INSERT antes/após cursor"),
            ("I / A", "INSERT início/fim linha"),
            ("o / O", "Nova linha abaixo/acima"),
            ("v", "VISUAL (seleção)"),
            ("V", "VISUAL LINE"),
            ("Ctrl + V", "VISUAL BLOCK (coluna)"),
            ("R", "Modo REPLACE"),
            ("Esc", "Volta ao NORMAL"),
        ],
    },
    "Neovim - Navegação": {
        "color": "red",
        "binds": [
            ("h/j/k/l", "← ↓ ↑ →"),
            ("w / b / e", "Palavra próx/ant/fim"),
            ("0 / $", "Início/fim da linha"),
            ("gg / G", "Início/fim do arquivo"),
            ("{ / }", "Parágrafo ant/próx"),
            ("Ctrl + D/U", "Scroll ½ página"),
            ("f{c} / F{c}", "Ir até char na linha"),
            ("%", "Ir ao par ()/[]/{}"),
            (":{n}", "Ir para linha n"),
        ],
    },
    "Neovim - Edição": {
        "color": "peach",
        "binds": [
            ("x", "Deletar char"),
            ("dd / D", "Deletar linha/até fim"),
            ("yy / Y", "Copiar linha"),
            ("p / P", "Colar após/antes"),
            ("u / Ctrl+R", "Undo / Redo"),
            ("c{motion}", "Change (delete+insert)"),
            ("ciw / ci\"", "Change inner word/quotes"),
            ("diw / di\"", "Delete inner word/quotes"),
            (".", "Repetir última ação"),
            (">> / <<", "Indentar / desindentar"),
        ],
    },
    "Neovim - Busca / g": {
        "color": "teal",
        "binds": [
            ("/{texto}", "Buscar forward"),
            ("?{texto}", "Buscar backward"),
            ("n / N", "Próximo/anterior resultado"),
            ("* / #", "Buscar palavra sob cursor"),
            (":%s/old/new/g", "Substituir tudo"),
            ("gd / gD", "Go to definition"),
            ("gf", "Go to file sob cursor"),
            ("gu / gU", "Minúscula / maiúscula"),
            ("gv", "Re-selecionar última visual"),
            ("g;/ g,", "Ir a edição anterior/próx"),
        ],
    },
    "Neovim - Custom (Leader)": {
        "color": "blue",
        "binds": [
            ("Ctrl + S", "Salvar arquivo"),
            ("<leader> q / Q", "Sair / Sair todos"),
            ("Ctrl + H/J/K/L", "Navegar janelas"),
            ("Ctrl + ←↑→↓", "Redimensionar janelas"),
            ("Shift + L / H", "Próx/anterior buffer"),
            ("< / > (visual)", "Indentar (mantém sel)"),
            ("J / K (visual)", "Mover linhas ↑↓"),
            ("p (visual)", "Colar sem yankar"),
            (":w / :q / :wq", "Salvar / Sair"),
            (":sp / :vsp", "Split horiz/vertical"),
        ],
    },
}


def hex_to_rgb(hex_color):
    h = hex_color.lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


def find_font():
    """Find a suitable monospace font."""
    font_paths = [
        "/run/current-system/sw/share/X11/fonts/JetBrainsMonoNerdFont-Regular.ttf",
        "/run/current-system/sw/share/X11/fonts/JetBrainsMono-Regular.ttf",
    ]
    # Search in nix store for JetBrains Mono
    import glob

    nix_fonts = glob.glob(
        "/nix/store/*nerd-fonts*/share/fonts/truetype/NerdFonts/JetBrainsMono/JetBrainsMonoNerdFont-Regular.ttf"
    )
    font_paths.extend(nix_fonts)

    nix_fonts2 = glob.glob(
        "/nix/store/*JetBrainsMono*/share/fonts/truetype/*.ttf"
    )
    font_paths.extend(nix_fonts2)

    # Also check common paths
    font_paths.extend([
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
        "/usr/share/fonts/TTF/DejaVuSansMono.ttf",
    ])

    for path in font_paths:
        if os.path.exists(path):
            return path
    return None


def main():
    img = Image.new("RGB", (WIDTH, HEIGHT), hex_to_rgb(COLORS["base"]))
    draw = ImageDraw.Draw(img)

    font_path = find_font()
    if font_path:
        print(f"Using font: {font_path}")
        font_title = ImageFont.truetype(font_path, 42)
        font_category = ImageFont.truetype(font_path, 24)
        font_key = ImageFont.truetype(font_path, 18)
        font_desc = ImageFont.truetype(font_path, 17)
    else:
        print("WARNING: No custom font found, using default")
        font_title = ImageFont.load_default()
        font_category = font_title
        font_key = font_title
        font_desc = font_title

    # Title
    title = "⌨  Keybindings - Hyprland"
    draw.text((WIDTH // 2, 60), title, fill=hex_to_rgb(COLORS["text"]),
              font=font_title, anchor="mt")

    # Subtitle
    draw.text((WIDTH // 2, 110), "SUPER = Mod Key (Windows/Meta)",
              fill=hex_to_rgb(COLORS["subtext0"]), font=font_desc, anchor="mt")

    # Layout: 5 columns x 2 rows
    cols = 5
    rows = 2
    margin_x = 200
    margin_y = 160
    col_width = (WIDTH - 2 * margin_x) // cols
    row_height = (HEIGHT - margin_y - 60) // rows

    categories = list(CATEGORIES.items())

    for idx, (cat_name, cat_data) in enumerate(categories):
        col = idx % cols
        row = idx // cols

        x = margin_x + col * col_width + 20
        y = margin_y + row * row_height + 20

        # Category background
        box_w = col_width - 40
        box_h = row_height - 40
        draw.rounded_rectangle(
            [x, y, x + box_w, y + box_h],
            radius=12,
            fill=hex_to_rgb(COLORS["mantle"]),
            outline=hex_to_rgb(COLORS["surface1"]),
            width=1,
        )

        # Category title
        cat_color = hex_to_rgb(COLORS[cat_data["color"]])
        draw.text((x + 20, y + 15), cat_name, fill=cat_color, font=font_category)

        # Separator line
        draw.line(
            [(x + 20, y + 50), (x + box_w - 20, y + 50)],
            fill=hex_to_rgb(COLORS["surface0"]),
            width=1,
        )

        # Keybindings
        line_y = y + 65
        for key, desc in cat_data["binds"]:
            if line_y + 35 > y + box_h - 10:
                break

            # Key badge
            draw.text((x + 25, line_y), key, fill=hex_to_rgb(COLORS["subtext1"]),
                      font=font_key)

            # Description
            draw.text((x + 25, line_y + 20), desc, fill=hex_to_rgb(COLORS["subtext0"]),
                      font=font_desc)

            line_y += 42

    # Footer
    draw.text(
        (WIDTH // 2.5, HEIGHT - 30),
        "NixOS + Hyprland │ Catppuccin Macchiato",
        fill=hex_to_rgb(COLORS["surface1"]),
        font=font_desc,
        anchor="mb",
    )

    output_path = os.path.expanduser("~/Pictures/keybindings-wallpaper.png")
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.save(output_path, "PNG")
    print(f"Wallpaper saved to: {output_path}")


if __name__ == "__main__":
    main()
