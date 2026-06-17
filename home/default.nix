{ config, pkgs, lib, catppuccin, ... }:

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
  ];

  home.username = "terabytes";
  home.homeDirectory = "/home/terabytes";
  home.stateVersion = "26.05";

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";

    XDG_SESSION_TYPE = "wayland";
    NIXOS_OZONE_WL = "1";

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
      preload = [
        "${config.home.homeDirectory}/.background"
      ];
      wallpaper = [
        ",${config.home.homeDirectory}/.background"
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
  # NOTE: config is mutable (editable without rebuild) — pointed at repo file via symlink
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = false;
  };

  # Mutable Hyprland Lua config — edit directly, reload with `hyprctl reload`
  xdg.configFile."hypr/hyprland.lua" = {
    source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/Workspace/fagianijunior/nixos/home/hyprland.lua";
  };

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
  };

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
        action = "hyprctl dispatch exit";
        text = "Logout";
        keybind = "e";
      }
      {
        label = "shutdown";
        action = "systemctl poweroff";
        text = "Shutdown";
        keybind = "s";
      }
      {
        label = "reboot";
        action = "systemctl reboot";
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
    quickshell
    hyprpolkitagent
    pavucontrol
    swappy
    gimp
    telegram-desktop
    slack
    clickup
    pavucontrol

    # Dev tools
    python3
    nil
    nixpkgs-fmt
    terraform-ls
    rubyPackages.solargraph
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
