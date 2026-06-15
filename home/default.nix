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
  ];

  home.username = "terabytes";
  home.homeDirectory = "/home/terabytes";
  home.stateVersion = "26.05";

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";

    XDG_SESSION_TYPE = "wayland";
    NIXOS_OZONE_WL = "1";

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
      input-field = [
        {
          size = "200, 50";
          position = "0, -80";
          monitor = "";
          dots_center = true;
          fade_on_empty = false;
          outline_thickness = 2;
          placeholder_text = "Password...";
          shadow_passes = 2;
        }
      ];
    };
  };

  # Hyprland user-level configuration
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = false;
    settings = {
      "$terminal" = "wezterm";
      "$browser" = "firefox --ProfileManager";
      "$fileManager" = "$terminal -e yazi";
      "$menu" = "wofi --show drun";
      "$mainMod" = "SUPER";
      "$volume_sidemenu" = "match:class ^(org.pulseaudio.pavucontrol)$";

      monitor = [ ",preferred,auto,auto" ];

      general = {
        gaps_in = 3;
        gaps_out = 3;
        border_size = 2;
        "col.active_border" = "rgb(94e2d5)";
        "col.inactive_border" = "rgb(313244)";
        resize_on_border = true;
        allow_tearing = false;
        layout = "dwindle";
      };

      misc = {
        force_default_wallpaper = -1;
        disable_splash_rendering = true;
        disable_hyprland_logo = true;
        background_color = "0x1e1e2e";
      };

      input = {
        left_handed = false;
        follow_mouse = 1;
        sensitivity = 0;
        scroll_points = "-1 -1";
        scroll_factor = "0.5";
        touchpad = {
          natural_scroll = true;
          disable_while_typing = true;
          clickfinger_behavior = true;
          scroll_factor = "0.5";
        };
      };

      binds = {
        workspace_back_and_forth = true;
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
        smart_split = true;
      };

      device = {
        "keyboard-k380-keyboard" = {
          kb_layout = "us";
          kb_variant = "intl";
        };
        "at-translated-set-2-keyboard" = {
          kb_layout = "br";
          kb_variant = "";
        };
      };

      decoration = {
        rounding = 10;
        blur = {
          enabled = true;
          size = 8;
          passes = 3;
          new_optimizations = true;
          ignore_opacity = false;
        };
        active_opacity = "0.9";
        inactive_opacity = "0.7";
        fullscreen_opacity = "1.0";
      };

      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };

      master = {
        new_status = "master";
      };

      bind = [
        "$mainMod, TAB, overview:toggle,"
        "$mainMod CTRL, V, exec, pypr toggle volume"
        "$mainMod, Z, exec, pypr zoom"
        "$mainMod, ESCAPE, exec, pkill -x wlogout || wlogout"
        "$mainMod SHIFT, P, exec, fish -c screenshot_to_clipboard"
        "$mainMod CTRL, P, exec, fish -c screenshot_edit"
        "$mainMod SHIFT, R, exec, fish -c record_screen_gif"
        "$mainMod CTRL, R, exec, fish -c record_screen_mp4"
        ''$mainMod, V, exec, cliphist list | wofi --dmenu --pre-display-cmd "echo '%s' | cut -f 2" | cliphist decode | wl-copy''
        "$mainMod, X, exec, fish -c clipboard_delete_item"
        "$mainMod SHIFT, X, exec, fish -c clipboard_clear"
        "$mainMod, U, exec, fish -c bookmark_to_type"
        "$mainMod SHIFT, U, exec, fish -c bookmark_add"
        "$mainMod CTRL, U, exec, fish -c bookmark_delete"
        "$mainMod, D, fullscreen, 1"
        "$mainMod, F, fullscreen, 0"
        "$mainMod SHIFT, F, togglefloating,"
        "$mainMod, J, togglesplit,"
        "$mainMod, L, exec, hyprlock"
        "$mainMod ALT, M, exit,"
        "$mainMod, P, pseudo,"
        "$mainMod, Q, killactive"
        "$mainMod, R, exec, $menu"
        "$mainMod, SPACE, exec, $terminal"
        "$mainMod, O, exec, hyprctl setprop active opaque toggle "
        "$mainMod SHIFT, N, exec, fish -c notification_mode_toggle"
        "Alt, E, exec, $fileManager"
        "Alt, G, exec, gimp"
        "Alt, T, exec, telegram-desktop"
        "Alt, W, exec, firefox -P whatsapp -kiosk https://web.whatsapp.com"
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"
        "$mainMod, S, togglespecialworkspace, magic"
        "$mainMod SHIFT, S, movetoworkspace, special:magic"
        "$mainMod, G, togglespecialworkspace, game"
        "$mainMod SHIFT, G, movetoworkspace, special:game"
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"
        "$mainMod, M, exec, fish -c logitech-change-host"
      ] ++ (builtins.concatLists (builtins.genList (i:
        let ws = i + 1;
        in [
          "$mainMod, code:1${toString i}, workspace, ${toString ws}"
          "$mainMod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
        ]) 9));

      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      bindel = [
        ",XF86MonBrightnessUp, exec, lightctl up"
        ",XF86MonBrightnessDown, exec, lightctl down"
        ",XF86AudioRaiseVolume, exec, volumectl -u up"
        ",XF86AudioLowerVolume, exec, volumectl -u down"
        ",XF86AudioMute, exec, volumectl toggle-mute"
        "$mainMod, XF86AudioMute, exec, volumectl -m toggle-mute"
      ];

      bindl = [
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioPrev, exec, playerctl previous"
        ", XF86AudioNext, exec, playerctl next"
      ];

      windowrule = [
        "float on, match:title (Media viewer)"
        "opaque on, match:title (Media viewer)"
        "center on, match:title ^(Open File)(.*)$"
        "center on, match:title ^(Select a File)(.*)$"
        "center on, match:title ^(Choose wallpaper)(.*)$"
        "center on, match:title ^(Open Folder)(.*)$"
        "center on, match:title ^(Save As)(.*)$"
        "center on, match:title ^(Library)(.*)$"
        "center on, match:title ^(File Upload)(.*)$"
        "float on, $volume_sidemenu"
        "float on, match:title ^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$"
        "opaque on, match:title ^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$"
        "opaque on, match:title ^(Netflix)(.*)$"
        "opaque on, match:title ^(.*)(Youtube)(.*)$"
        "suppress_event fullscreen maximize, match:class .*"
        "pin on, match:title ^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$"
      ];

      exec-once = [
        "pypr"
        "hypridle"
        "poweralertd"
        "avizo-service"
        "systemctl --user start psi-notify"
        "systemctl --user start quickshell"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
        "fish -c autostart"
        "[workspace 1] $browser"
        "[workspace 3] clickup"
        "[workspace 3] slack"
        "[workspace 3] telegram-desktop"
        "systemctl --user start hyprpolkitagent"
      ];
    };
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
          command = "pavucontrol --class volume_sidemenu";
          animation = "fromLeft";
          class = "volume_sidemenu";
          size = "40% 70%";
          unfocus = "hide";
          excludes = "*";
          lazy = true;
          margin = 90;
          multi = false;
        };
      };
      shortcuts_menu.entries."Color picker" = {
        options = [{ name = "format"; options = [ "hex" "rgb" "hsv" "hsl" "cmyk" ]; }];
        command = "sleep 0.2; hyprpicker --format [format] -a";
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
    gimp
    telegram-desktop
    slack
    clickup

    # Dev tools
    nil
    nixpkgs-fmt
    terraform-ls
    rubyPackages.solargraph
    uv
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
