{ config, pkgs, ... }:

{
  # Taskwarrior TUI configuration
  xdg.configFile."taskwarrior-tui/config.toml".text = ''
    # Taskwarrior TUI Configuration
    
    [general]
    # Task command (use taskwarrior3)
    task_bin = "task"
    
    # Default view
    default_view = "tasks"
    
    # Auto-refresh interval in seconds
    auto_refresh = 30
    
    # Show task details in bottom pane
    show_task_details = true
    
    # Task report to use
    task_report = "next"
    
    # Maximum number of tasks to show
    task_limit = 100
    
    [keybindings]
    # Navigation
    quit = "q"
    refresh = "r"
    help = "?"
    
    # Task management
    add_task = "a"
    edit_task = "e"
    delete_task = "d"
    complete_task = "c"
    start_task = "s"
    stop_task = "S"
    
    # Views
    next_view = "Tab"
    previous_view = "BackTab"
    
    # Movement
    up = "k"
    down = "j"
    page_up = "K"
    page_down = "J"
    home = "g"
    end = "G"
    
    [colors]
    # Catppuccin Macchiato theme
    background = "#24273a"
    foreground = "#cad3f5"
    
    # Task states
    pending = "#8aadf4"
    completed = "#a6da95"
    deleted = "#ed8796"
    
    # Priority colors
    priority_high = "#ed8796"
    priority_medium = "#eed49f"
    priority_low = "#a5adcb"
    
    # UI elements
    selected = "#94e2d5"
    border = "#5b6078"
    header = "#f4dbd6"
    
    [ui]
    # Show borders
    show_borders = true
    
    # Show help text
    show_help = true
    
    # Task list format
    task_format = "{id} {priority} {project} {description}"
    
    # Date format
    date_format = "%Y-%m-%d"
    
    # Time format
    time_format = "%H:%M"
    
    [filters]
    # Default filters
    default_filter = "status:pending"
    
    # Quick filters
    inbox = "project:Inbox"
    work = "project:Work"
    personal = "project:Personal"
    next = "+next"
    waiting = "status:waiting"
  '';
}
