{ config, pkgs, ... }:

let
  # Python with AI dependencies for taskwarrior
  pythonWithAI = pkgs.python3.withPackages (
    ps: with ps; [
      requests
    ]
  );
in
{
  imports = [
    ./systemd-services.nix
    ./sync-config.nix
  ];

  # Dependências para IA
  home.packages = with pkgs; [
    taskwarrior3
    taskwarrior-tui
    python3
    python3Packages.requests
  ];

  # Create a symlink to python with AI packages for development
  home.file.".local/bin/python3-ai".source = "${pythonWithAI}/bin/python3";

  # Taskwarrior configuration
  xdg.configFile."task/taskrc".text = ''
    # Taskwarrior 3 Configuration

    # Data location
    data.location=~/.local/share/task

    # News version (to avoid write errors)
    news.version=3.4.2

    # Default command
    default.command=next

    # Date format
    dateformat=Y-M-D H:N:S
    dateformat.report=Y-M-D
    dateformat.holiday=YMD
    dateformat.annotation=Y-M-D

    # Week starts on Monday
    weekstart=monday

    # Display settings
    displayweeknumber=yes
    list.all.projects=yes
    list.all.tags=yes

    # Colors (Catppuccin Macchiato theme)
    color.active=color13
    color.alternate=on color233
    color.blocked=white on red
    color.blocking=black on bright white
    color.burndown.done=on green
    color.burndown.pending=on red
    color.burndown.started=on yellow
    color.calendar.due=color0 on color13
    color.calendar.due.today=color15 on color13
    color.calendar.holiday=color0 on bright blue
    color.calendar.overdue=color0 on bright red
    color.calendar.today=color15 on bright blue
    color.calendar.weekend=on bright black
    color.calendar.weeknumber=bright blue
    color.completed=green
    color.debug=yellow
    color.deleted=color13
    color.due=color13
    color.due.today=color13
    color.error=white on red
    color.footnote=yellow
    color.header=color13
    color.history.add=color0 on color13
    color.history.delete=color0 on color13
    color.history.done=color0 on green
    color.keyword=color13 on yellow
    color.label=
    color.label.sort=
    color.overdue=color255 on red
    color.pri.H=color255
    color.pri.L=color245
    color.pri.M=color250
    color.pri.none=
    color.project.none=
    color.recurring=color13
    color.scheduled=on color13
    color.summary.background=white on black
    color.summary.bar=black on color13
    color.sync.added=green
    color.sync.changed=yellow
    color.sync.rejected=red
    color.tag.next=color13
    color.tag.none=
    color.tagged=color10
    color.undo.after=green
    color.undo.before=red
    color.until=
    color.warning=bold red

    # User Defined Attributes (UDA)
    uda.client.type=string
    uda.client.label=Client
    uda.client.values=

    uda.totalactivetime.type=numeric
    uda.totalactivetime.label=Total Active Time

    # Urgency coefficients
    urgency.user.project.Inbox.coefficient=15.0
    urgency.user.project.Work.coefficient=10.0
    urgency.user.tag.next.coefficient=15.0
    urgency.user.tag.waiting.coefficient=-3.0
    urgency.due.coefficient=12.0
    urgency.blocking.coefficient=8.0
    urgency.priority.coefficient=6.0
    urgency.active.coefficient=4.0
    urgency.scheduled.coefficient=5.0
    urgency.age.coefficient=2.0
    urgency.annotations.coefficient=1.0
    urgency.tags.coefficient=1.0
    urgency.project.coefficient=1.0

    # Reports
    report.next.columns=id,start.age,entry.age,depends.indicator,priority,project,tags.count,recur.indicator,scheduled.countdown,due.relative,until.remaining,description.count,client,urgency
    report.next.labels=ID,Active,Age,D,P,Project,Tags,R,S,Due,Until,Description,Client,Urg
    report.next.sort=urgency-
    report.next.filter=status:pending
    
    report.all.columns=id,status.short,uuid.short,start.age,entry.age,end.age,depends.indicator,priority,project,tags.count,recur.indicator,due,description.count,client
    report.all.labels=ID,St,UUID,A,Age,Done,D,P,Project,Tags,R,Due,Description,Client
    report.all.description=All tasks
    report.all.sort=entry-

    # Custom reports
    report.inbox.description=Inbox tasks
    report.inbox.columns=id,description.count,client
    report.inbox.sort=entry+
    report.inbox.filter=status:pending project:Inbox

    report.waiting.description=Waiting tasks
    report.waiting.columns=id,description.count,project,tags.count,client
    report.waiting.sort=entry+
    report.waiting.filter=status:waiting

    # Aliases
    alias.burndown=burndown.weekly
    alias.ghistory=ghistory.monthly
    alias.history=history.monthly
    alias.rm=delete

    # Context definitions
    context.work=project:Work or +work
    context.personal=project:Personal or +personal
  '';

  # Create data directory
  home.file.".local/share/task/.keep".text = "";

  # Scripts de IA
  home.file.".config/task/ai-assistant.py".source = ./ai-assistant.py;
  home.file.".config/task/daily-ai-report.sh".source = ./daily-ai-report.sh;

  # Aliases para facilitar o uso
  home.file.".config/fish/conf.d/taskwarrior-ai.fish".text = ''
    # Aliases para Taskwarrior com IA
    alias tai="~/.local/bin/python3-ai ~/.config/task/ai-assistant.py"
    alias task-analyze="tai analyze"
    alias task-plan="tai plan"
    alias task-improve="tai improve"
    alias task-report="~/.config/task/daily-ai-report.sh"

    # Função para análise rápida
    function task-ai-quick
        echo "🤖 Análise rápida das tarefas:"
        tai analyze | head -20
    end
  '';
}
