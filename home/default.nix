{ config, pkgs, catppuccin, ... }:

let
  lock-false = {
    Value = false;
    Status = "locked";
  };
  lock-true = {
    Value = true;
    Status = "locked";
  };
in
{
  imports = [
    catppuccin.homeModules.catppuccin
    ./kiro-mcp.nix
    ./neovim
    ./quickshell.nix
    ./taskwarrior
    ./taskwarrior-tui
  ];

  home.username = "terabytes";
  home.homeDirectory = "/home/terabytes";
  home.stateVersion = "26.05";

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";

    XDG_SESSION_TYPE = "wayland";
    NIXOS_OZONE_WL = "1";

    # Cursor theme for Hyprland/Wayland
    XCURSOR_THEME = "catppuccin-macchiato-blue-cursors";
    XCURSOR_SIZE = "24";

    # Force uv to use Nix-provided Python (NixOS can't run generic dynamic binaries)
    UV_PYTHON_PREFERENCE = "only-system";

    # Taskwarrior sync
    TASKCHAMPION_CLIENT_ID = "9dc04b7e-40dc-49f7-8a57-49fc7b9f6ea9";
    TASKCHAMPION_ENCRYPTION_SECRET = "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2";
    TASKCHAMPION_SERVER_URL = "http://orangepizero2:8080";
  };

  # Catppuccin Macchiato for Home Manager managed apps
  catppuccin = {
    enable = true;
    autoEnable = true;
    flavor = "macchiato";
    accent = "blue";
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  programs.delta = {
    enable = true;
    options = {
      navigate = true;
    };
  };

  # Git
  programs.git = {
    enable = true;

    ignores = [
      ".direnv"
      ".env"
      ".env.local"
      "result"
      "*.log"
      ".DS_Store"
    ];

    settings = {
      user = {
        name = "Carlos Fagiani Junior";
        email = "fagianijunior@gmail.com";
      };

      alias = {
        st = "status -sb";
        co = "checkout";
        br = "branch";
        ci = "commit";
        lg = "log --oneline --decorate --graph --all";
        amend = "commit --amend --no-edit";
        undo = "reset --soft HEAD~1";
      };

      init.defaultBranch = "main";

      core = {
        pager = "delta";
        editor = "nvim";
        autocrlf = "input";
        whitespace = "trailing-space,space-before-tab";
      };

      interactive = {
        diffFilter = "delta --color-only";
      };

      add = {
        interactive = {
          useBuiltin = false; # Required so git add -p uses delta
        };
      };
      
      delta = {
        navigate = true; # Use n and N to move between diff sections
        light = false;
        side-by-side = true;
        line-numbers = true;
        syntax-theme = "Catppuccin Macchiato"; # delta --show-syntax-themes
      };

      pull.rebase = true;

      push.autoSetupRemote = true;

      fetch = {
        prune = true;
        pruneTags = true;
      };

      rebase.autoStash = true;

      merge.conflictStyle = "zdiff3";

      diff = {
        algorithm = "histogram";
        colorMoved = "default";
      };

      rerere.enabled = true;

      status.branch = true;

      log.date = "iso";

      credential.helper = "";

      # Force SSH
      "url \"git@github.com:\"" = { insteadOf = "https://github.com/"; };
      "url \"git@gitlab.com:\"" = { insteadOf = "https://gitlab.com/"; };
    };
  };

  programs.bat.enable = true;

  # Development tools
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    silent = true;
    config = {
      global = {
        warn_timeout = "30s";
        hide_env_diff = true;
      };
    };
  };

  # Shell - Fish with starship prompt
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      # Disable greeting
      set fish_greeting

      # History tuning
      set -g fish_history_limit 10000

      # Better less
      set -gx LESS "-R --mouse"

      # AWS
      set -gx AWS_PAGER ""
      set -gx AWS_CLI_AUTO_PROMPT on-partial

      # Terraform
      set -gx TF_INPUT false
    '';

    functions = {
      nswitch = {
        description = "Rebuild NixOS usando o flake do host atual";
        body = ''
          sudo nixos-rebuild switch \
            --flake ~/Workspace/fagianijunior/dotfiles/#(hostname)
        '';
      };

      ngc = {
        body = "sudo nix-collect-garbage -d";
      };

      ngc7 = {
        body = "sudo nix-collect-garbage --delete-older-than 7d";
      };

      ngc14 = {
        body = "sudo nix-collect-garbage --delete-older-than 14d";
      };

      logitech-change-host = {
        description = "Troca o host dos dispositivos logitech entre nobita e doraemon";
        body = ''
          set normalized_hostname (echo $hostname | string lower)
          switch $normalized_hostname
            case "nobita"
              solaar config "LIFT" change-host "1"  # doraemon
              solaar config "Keyboard K380" change-host "1" # doraemon
            case "doraemon"
              solaar config "LIFT" change-host "3" # nobita
              solaar config "Keyboard K380" change-host "3" # nobita
            case "*"
              echo "Host desconhecido. Nenhuma alteração feita."
          end
        '';
      };

      aws-mfa = {
        description = "Gera credenciais temporárias AWS via MFA";
        body = ''
          if test (count $argv) -ne 1
            echo "Uso: aws-mfa <TOKEN_MFA>"
            return 1
          end

          set TOKEN_CODE $argv[1]

          set OUTPUT (aws sts get-session-token \
            --profile veezor \
            --duration-seconds 43200 \
            --serial-number arn:aws:iam::244589516718:mfa/carlos.fagiani \
            --token-code $TOKEN_CODE)

          if test $status -ne 0
            echo "Erro ao obter session token da AWS"
            return 1
          end

          set ACCESS_KEY_ID (echo $OUTPUT | jq -r '.Credentials.AccessKeyId')
          set SECRET_ACCESS_KEY (echo $OUTPUT | jq -r '.Credentials.SecretAccessKey')
          set SESSION_TOKEN (echo $OUTPUT | jq -r '.Credentials.SessionToken')

          aws configure set aws_access_key_id $ACCESS_KEY_ID --profile veezor-mfa
          aws configure set aws_secret_access_key $SECRET_ACCESS_KEY --profile veezor-mfa
          aws configure set aws_session_token $SESSION_TOKEN --profile veezor-mfa

          echo "Credenciais temporárias geradas para o perfil 'veezor-mfa' por 12 horas."
        '';
      };
    };

    plugins = [
      # fzf integration
      {
        name = "fzf-fish";
        src = pkgs.fishPlugins.fzf-fish.src;
      }

      # Notifications when done
      {
        name = "done";
        src = pkgs.fishPlugins.done.src;
      }

      # Colored output
      {
        name = "grc";
        src = pkgs.fishPlugins.grc.src;
      }

      # Better editing of pairs
      {
        name = "pisces";
        src = pkgs.fishPlugins.pisces.src;
      }
    ];
  };

  programs.starship = {
    enable = true;
  };

  # Terminal emulator
  programs.kitty = {
    enable = true;
  };

  programs.wezterm = {
    enable = true;
    extraConfig = ''
      local config = wezterm.config_builder()

      -- Shell
      config.default_prog = { "fish" }

      -- Fonte
      config.font = wezterm.font_with_fallback {
        "JetBrains Mono Nerd Font",
      }
      config.font_size = 11.0

      -- Tema
      config.color_scheme = "Catppuccin Macchiato"
      -- config.window_background_opacity = 0.60

      -- Tabs
      config.hide_tab_bar_if_only_one_tab = true
      config.use_fancy_tab_bar = false
      config.tab_bar_at_bottom = true

      -- Scroll
      config.scrollback_lines = 10000

      -- Layout
      config.enable_wayland = true
      config.window_padding = {
        left = 6,
        right = 6,
        top = 6,
        bottom = 6,
      }

      config.window_close_confirmation = "NeverPrompt"

      -- Keybindings
      config.keys = {
        { key = "d", mods = "CTRL|SHIFT", action = wezterm.action.SplitHorizontal },
        { key = "s", mods = "CTRL|SHIFT", action = wezterm.action.SplitVertical },

        { key = "h", mods = "ALT", action = wezterm.action.ActivatePaneDirection "Left" },
        { key = "l", mods = "ALT", action = wezterm.action.ActivatePaneDirection "Right" },
        { key = "k", mods = "ALT", action = wezterm.action.ActivatePaneDirection "Up" },
        { key = "j", mods = "ALT", action = wezterm.action.ActivatePaneDirection "Down" },

        { key = "q", mods = "CTRL|SHIFT", action = wezterm.action.CloseCurrentPane { confirm = true } },
      }

      return config
    '';
  };

  # File manager (terminal)
  programs.yazi = {
    enable = true;
  };

  services.dunst = {
    enable = true;
    settings = {
      global = {
        width = 300;
        height = 100;
        offset = "10x10";
        origin = "top-right";
        transparency = 0;
        frame_width = 2;
        corner_radius = 10;
        font = "FiraCode Nerd Font Mono 10";
        markup = "full";
        format = "<b>%s</b>\\n%b";
        alignment = "left";
        show_age_threshold = 60;
        word_wrap = true;
        icon_position = "left";
        max_icon_size = 64;
        mouse_left_click = "do_action, close_current";
        mouse_middle_click = "close_all";
        mouse_right_click = "close_current";
      };
      urgency_low = {
        timeout = 5;
      };
      urgency_normal = {
        timeout = 10;
      };
      urgency_critical = {
        timeout = 0;
      };
    };
  };

  services.hyprlauncher = {
    enable = true;
    settings = {
      cache = {
        enable = true;
      };
      finders = {
        desktop_icons = true;
        math_prefix = "=";
      };
      general = {
        grab_focus = true;
      };
      ui = {
        window_size = "400 260";
      };
    };
  };

  # Hyprland ecosystem services
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };
      listener = [
        {
          timeout = 300; # 5 min
          on-timeout = "brightnessctl -s set 10";
          on-resume = "brightnessctl -r";
        }
        {
          timeout = 600; # 10 min
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 900; # 15 min
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        {
          timeout = 1500;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };

  services.hyprpaper = {
    enable = true;
    settings = {
      wallpaper = [
        {
          monitor = "";
          path = "${config.home.homeDirectory}/.background";
        }
      ];
    };
  };

  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
        grace = 5;
      };
      background = [
        {
          path = "${config.home.homeDirectory}/.background";
          blur_passes = 0;
          blur_size = 0;
        }
      ];
      label = [ ];
      image = {
        monitor = "";
        path = "${config.home.homeDirectory}/.face";
        size = 350;
        border_color = "rgb(94e2d5)"; # teal
        rounding = -1;
        position = "0, 75";
        halign = "center";
        valign = "center";
        shadow_passes = 2;
      };
    };
  };

  # Hyprland user-level configuration
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    # systemd.enable creates hyprland-session.target and imports env vars to systemd/dbus.
    systemd.enable = true;
  };

  # Hyprland Lua config — managed by Nix (rebuild to apply changes)
  xdg.configFile."hypr/hyprland.lua" = {
    force = true;
    text = ''
    -- Hyprland Lua configuration for terabytes
    -- Managed by Nix — rebuild to apply changes
    -- https://wiki.hypr.land/Configuring/Start/


    ------------------
    ---- MONITORS ----
    ------------------

    -- See https://wiki.hypr.land/Configuring/Basics/Monitors/
    hl.monitor({
        output   = "eDP-1",
        mode     = "preferred",
        position = "auto",
        scale    = "1",
    })


    ---------------------
    ---- MY PROGRAMS ----
    ---------------------

    local terminal    = "wezterm"
    local fileManager = "$terminal -e yazi"
    local menu        = "hyprlauncher"
    local browser     = "firefox --ProfileManager"

    -------------------
    ---- AUTOSTART ----
    -------------------

    -- See https://wiki.hypr.land/Configuring/Basics/Autostart/
    hl.on("hyprland.start", function()
      -- Start hyprland-session.target which activates graphical-session.target
      -- This auto-starts all user services: hyprpaper, hypridle, hyprlauncher, quickshell
      hl.exec_cmd("systemctl --user start hyprland-session.target")

      -- Core services (not managed by systemd)
      hl.exec_cmd("pypr")
      hl.exec_cmd("poweralertd")
      hl.exec_cmd("avizo-service")
      hl.exec_cmd("systemctl --user start psi-notify")

      -- Clipboard history
      hl.exec_cmd("wl-paste --type text --watch cliphist store")
      hl.exec_cmd("wl-paste --type image --watch cliphist store")

      -- Apps on specific workspaces
      -- Workspace 3 layout (dwindle): clickup=left half, telegram=top-right, slack=bottom-right
      -- Order of mapping determines position in dwindle: 1st=full, 2nd=right split, 3rd=bottom-right split
      hl.exec_cmd("[workspace 1] " .. browser)
      hl.exec_cmd("[workspace 3] clickup")
      hl.exec_cmd("[workspace 3] Telegram")
      hl.exec_cmd("[workspace 3] whatsapp-electron")
      hl.exec_cmd("[workspace 3] slack")
    end)

    -- Clean shutdown: stop session target so systemd services stop gracefully
    hl.on("hyprland.shutdown", function()
      os.execute("systemctl --user stop hyprland-session.target && sleep 0.1")
    end)

    -------------------------------
    ---- ENVIRONMENT VARIABLES ----
    -------------------------------

    -- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

    hl.env("XCURSOR_SIZE", "24")
    hl.env("HYPRCURSOR_SIZE", "24")


    -----------------------
    ---- LOOK AND FEEL ----
    -----------------------

    -- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
    hl.config({
        general = {
            gaps_in  = 3,
            gaps_out = 3,

            border_size = 2,

            col = {
                active_border   = "rgb(94e2d5)",
                inactive_border = "rgb(313244)",
            },

            resize_on_border = true,
            allow_tearing = false,
            layout = "dwindle",
        },

        decoration = {
            rounding       = 10,
            rounding_power = 2,

            active_opacity   = 0.9,
            inactive_opacity = 0.7,
            fullscreen_opacity = 1.0,

            shadow = {
                enabled      = true,
                range        = 4,
                render_power = 3,
                color        = 0xee1a1a1a,
            },

            blur = {
                enabled   = true,
                size      = 8,
                passes    = 3,
                vibrancy  = 0.1696,
            },
        },

        animations = {
            enabled = true,
        },

        binds = {
            workspace_back_and_forth = true,
        },
    })

    -- Curves and animations
    hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
    hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
    hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
    hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
    hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

    -- Springs
    hl.curve("easy",           { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

    hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
    hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
    hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, spring = "easy" })
    hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  spring = "easy",         style = "popin 87%" })
    hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
    hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
    hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
    hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
    hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
    hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
    hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
    hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
    hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
    hl.animation({ leaf = "workspaces",    enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
    hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 1.21, bezier = "almostLinear", style = "fade" })
    hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
    hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick" })


    -----------------------
    ---- LAYOUT CONFIG ----
    -----------------------

    hl.config({
        dwindle = {
            preserve_split = true,
            smart_split = true
        },
    })

    hl.config({
        master = {
            new_status = "master",
        },
    })

    hl.config({
        scrolling = {
            fullscreen_on_one_column = true,
        },
    })


    ----------------
    ----  MISC  ----
    ----------------

    hl.config({
        misc = {
            force_default_wallpaper = 0,
            disable_splash_rendering = true,
            disable_hyprland_logo   = true,
            background_color = "0x1e1e2e"
        },
    })


    ---------------
    ---- INPUT ----
    ---------------

    hl.config({
        input = {
            kb_layout  = "br",
            kb_variant = "abnt2",
            kb_model   = "",
            kb_options = "",
            kb_rules   = "",

            follow_mouse = 1,

            sensitivity = 0,

            touchpad = {
                natural_scroll = true,
                disable_while_typing = true,
                clickfinger_behavior = true
            },
        },
    })

    hl.gesture({
        fingers = 3,
        direction = "horizontal",
        action = "workspace"
    })

    -- Per-device keyboard config
    hl.device({
        name        = "keyboard-k380-keyboard",
        kb_layout   = "us",
        kb_variant  = "intl",
    })

    hl.device({
        name        = "at-translated-set-2-keyboard",
        kb_layout   = "br",
        kb_variant  = "",
    })

    hl.config({
        binds = {
            workspace_back_and_forth = true,
        },
    })


    ---------------------
    ---- KEYBINDINGS ----
    ---------------------

    local mainMod = "SUPER"

    hl.bind(mainMod .. " + CTRL + V", hl.dsp.exec_cmd("pypr toggle volume"))
    hl.bind(mainMod .. " + CTRL + RETURN", hl.dsp.exec_cmd("pypr toggle term"))
    hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd("pypr zoom"))
    hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd("pkill -x wlogout || wlogout"))
    hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({action = "toggle"}))
    hl.bind(mainMod .. " + D", hl.dsp.window.fullscreen({mode = "maximized", action = "toggle"}))
    hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(terminal))
    hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | swappy -f -"))
    hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.float({action = "toggle"}))
    hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))


    hl.bind(mainMod .. " + Q", hl.dsp.window.close())
    hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("hyprshutdown"))
    hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("pypr menu"))
    hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
    hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
    hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

    -- Move focus with mainMod + arrow keys
    hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
    hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
    hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
    hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

    -- Switch workspaces with mainMod + [0-9]
    -- Move active window to a workspace with mainMod + SHIFT + [0-9]
    for i = 1, 10 do
        local key = i % 10
        hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
        hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
    end

    -- Special workspace (scratchpad)
    hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
    hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

    -- Scroll through existing workspaces with mainMod + scroll
    hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
    hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

    -- Move/resize windows with mainMod + LMB/RMB and dragging
    hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
    hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

    -- Brightness and volume via avizo (OSD notifications)
    hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("lightctl up"),            { locked = true, repeating = true })
    hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("lightctl down"),          { locked = true, repeating = true })
    hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("volumectl -u up"),        { locked = true, repeating = true })
    hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("volumectl -u down"),      { locked = true, repeating = true })
    hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("volumectl toggle-mute"),  { locked = true, repeating = true })
    hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("volumectl -m toggle-mute"), { locked = true, repeating = true })
    hl.bind(mainMod .. " + XF86AudioMute", hl.dsp.exec_cmd("volumectl -m toggle-mute"), { locked = true })

    -- Requires playerctl
    hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
    hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
    hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
    hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })


    --------------------------------
    ---- WINDOWS AND WORKSPACES ----
    --------------------------------

    -- Pyprland scratchpad window rules (required for pypr to manage these windows)
    hl.window_rule({
        name  = "pypr-term-scratchpad",
        match = { class = "wezterm_dropdown" },
        float = true,
        size  = "75% 60%",
    })

    hl.window_rule({
        name  = "pypr-volume-scratchpad",
        match = { class = "org.pulseaudio.pavucontrol" },
        float = true,
        size  = "40% 70%",
    })

    hl.window_rule({
        name  = "suppress-maximize-events",
        match = { class = ".*" },
        suppress_event = "maximize",
    })

    hl.window_rule({
        name  = "fix-xwayland-drags",
        match = {
            class      = "^$",
            title      = "^$",
            xwayland   = true,
            float      = true,
            fullscreen = false,
            pin        = false,
        },
        no_focus = true,
    })

    hl.window_rule({
        name  = "move-hyprland-run",
        match = { class = "hyprland-run" },
        move  = "20 monitor_h-120",
        float = true,
    })

    hl.window_rule({
        name = "Picture-in-Picture",
        match = { title = "Picture-in-Picture" },
        float = true,
        opacity = "1",
    })

    hl.window_rule({
        name = "Youtube",
        match = { title = "^(.*)(Youtube)(.*)$" },
        opacity = "1",
    })

    hl.window_rule({
        name = "Netflix",
        match = { title = "^(Netflix)(.*)$" },
        opacity = "1",
    })
  '';
  };

  # Hyprland Qt6 support style config
  xdg.configFile."hypr/application-style.conf".text = ''
    roundness = 3
    border_width = 2
    reduce_motion = false
  '';

  # Hyprtoolkit theme — Catppuccin Macchiato Blue
  xdg.configFile."hypr/hyprtoolkit.conf".text = ''
    background = 0xFF24273a
    base = 0xFF1e2030
    text = 0xFFcad3f5
    alternate_base = 0xFF363a4f
    bright_text = 0xFFf4dbd6
    accent = 0xFF8aadf4
    accent_secondary = 0xFF7dc4e4
    font_family = FiraCode Nerd Font Mono
    font_family_monospace = JetBrains Mono Nerd Font
    font_size = 11
    small_font_size = 10
    icon_theme = Papirus-Dark
    rounding_large = 10
    rounding_small = 5
  '';

  # Pyprland configuration
  xdg.configFile."pypr/config.toml".source =
    let
      toml = pkgs.formats.toml { };
    in
    toml.generate "config.toml" {
      pyprland.plugins = [
        "scratchpads"
        "magnify"
        "expose"
        "shortcuts_menu"
        "toggle_special"
        "lost_windows"
      ];
      scratchpads = {
        term = {
          command = "wezterm start --always-new-process --class wezterm_dropdown";
          animation = "fromTop";
          unfocus = "hide";
          excludes = "*";
          lazy = true;
          multi = false;
        };
        volume = {
          command = "env GDK_BACKEND=wayland pavucontrol";
          animation = "fromLeft";
          class = "org.pulseaudio.pavucontrol";
          size = "40% 70%";
          unfocus = "hide";
          excludes = "*";
          lazy = true;
          margin = 90;
          multi = false;
        };
      };
      shortcuts_menu.entries = {
        "Clipboard History" = [
          {
            name = "entry";
            command = "cliphist list";
            filter = "s/\t.*//";
          }
          "cliphist decode '[entry]' | wl-copy"
        ];
      };
    };

  # GTK configuration (theme handled by catppuccin autoEnable, font set here)
  gtk = {
    enable = true;
    font = {
      name = "FiraCode Nerd Font Mono";
      size = 10;
    };
    cursorTheme = {
      name = "catppuccin-macchiato-blue-cursors";
      package = pkgs.catppuccin-cursors.macchiatoBlue;
      size = 24;
    };
  };

  # Workaround: hyprlauncher (hyprtoolkit) looks for icons in ~/.icons instead of XDG_DATA_DIRS
  # See: https://github.com/hyprwm/hyprlauncher/issues/105
  home.file.".icons/default/index.theme".text = ''
    [Icon Theme]
    Inherits=Papirus-Dark
  '';
  home.file.".icons/Papirus-Dark".source = "${pkgs.catppuccin-papirus-folders.override {
    flavor = "macchiato";
    accent = "blue";
  }}/share/icons/Papirus-Dark";
  home.file.".icons/hicolor".source = "${pkgs.hicolor-icon-theme}/share/icons/hicolor";

  programs.wlogout = {
    enable = true;
    layout = [
      {
        label = "lock";
        action = "hyprlock";
        text = "Lock";
        keybind = "l";
      }
      {
        label = "logout";
        action = "hyprshutdown";
        text = "Logout";
        keybind = "e";
      }
      {
        label = "shutdown";
        action = "hyprshutdown -t 'Shutting down...' --post-cmd 'systemctl poweroff'";
        text = "Shutdown";
        keybind = "s";
      }
      {
        label = "reboot";
        action = "hyprshutdown -t 'Restarting...' --post-cmd 'systemctl reboot'";
        text = "Reboot";
        keybind = "r";
      }
      {
        label = "suspend";
        action = "systemctl suspend";
        text = "Suspend";
        keybind = "u";
      }
      {
        label = "hibernate";
        action = "systemctl hibernate";
        text = "Hibernate";
        keybind = "h";
      }
    ];
  };

  # XDG user directories
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "${config.home.homeDirectory}/Desktop";
      documents = "${config.home.homeDirectory}/Documents";
      download = "${config.home.homeDirectory}/Downloads";
      music = "${config.home.homeDirectory}/Music";
      pictures = "${config.home.homeDirectory}/Pictures";
      videos = "${config.home.homeDirectory}/Videos";
    };
  };

  # Additional packages managed by Home Manager
  home.packages = with pkgs; [
    fastfetch
    ripgrep
    fd
    eza
    fzf
    grc

    # Hyprland ecosystem
    pyprland
    avizo
    cliphist
    hyprpicker
    poweralertd
    psi-notify
    hyprpolkitagent
    hyprland-qt-support
    hyprland-qtutils
    hyprshutdown
    pavucontrol
    swappy
    gimp
    telegram-desktop
    whatsapp-electron
    slack
    clickup
    pavucontrol

    # Dev tools
    python3
    nodejs
    nixpkgs-fmt
    uv
    nixd
    kiro
    kiro-cli
    github-mcp-server
    awscli2
  ];

  # Firefox
  programs.firefox = {
    enable = true;
    package = pkgs.wrapFirefox (pkgs.firefox-unwrapped.override { pipewireSupport = true; }) { };

    languagePacks = [ "pt-BR" "en-US" ];

    profiles = {
      fagiani = {
        extensions.force = true;
        id = 0;
        name = "Fagiani";
        isDefault = true;
      };
      nubank = {
        extensions.force = true;
        id = 1;
        name = "nubank";
        isDefault = false;
      };
    };

    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
      DisablePocket = true;
      DisableFirefoxAccounts = true;
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";
      DontCheckDefaultBrowser = true;
      DisplayBookmarksToolbar = "newtab";
      DisplayMenuBar = "default-off";
      SearchBar = "unified";

      ExtensionSettings = {
        "*".installation_mode = "blocked";
        # Bitwarden
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4640726/latest.xpi";
          installation_mode = "normal_installed";
        };
        # AWS Extend Switch Role
        "aws-extend-switch-roles@toshi.tilfin.com" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4613250/latest.xpi";
          installation_mode = "force_installed";
        };
        # Theme: Catppuccin-macchiato
        "{030fcc87-b84d-4004-a7de-a6166cdf7333}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/3958203/latest.xpi";
          installation_mode = "force_installed";
        };
        "FirefoxColor@mozilla.com" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/3643624/latest.xpi";
          installation_mode = "force_installed";
        };
        # Corretor Português
        "pt-BR@dictionaries.addons.mozilla.org" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4223181/latest.xpi";
          installation_mode = "force_installed";
        };
      };

      Preferences = {
        "extensions.pocket.enabled" = lock-false;
        "extensions.update.enabled" = lock-true;
        "extensions.autoDisableScopes" = { Value = 15; Status = "locked"; };
        "browser.topsites.contile.enabled" = lock-false;
        "browser.formfill.enable" = lock-false;
        "browser.search.suggest.enabled" = lock-true;
        "browser.search.suggest.enabled.private" = lock-true;
        "browser.startup.page" = { Value = 3; Status = "locked"; };
        "browser.sessionstore.resume_session_once" = lock-true;
        "browser.urlbar.suggest.searches" = lock-false;
        "browser.urlbar.showSearchSuggestionsFirst" = lock-true;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = lock-false;
        "browser.newtabpage.activity-stream.feeds.snippets" = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includePocket" = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includeVisited" = lock-false;
        "browser.newtabpage.activity-stream.showSponsored" = lock-false;
        "browser.newtabpage.activity-stream.system.showSponsored" = lock-false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = lock-false;
      };
    };
  };
}
