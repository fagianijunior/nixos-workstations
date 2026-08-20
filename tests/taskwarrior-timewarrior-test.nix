{ pkgs, self, ... }:

pkgs.testers.nixosTest {
  name = "taskwarrior-timewarrior-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [
      ../modules/common
    ];

    fileSystems."/" = {
      device = "/dev/vda1";
      fsType = "ext4";
    };
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  };

  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")

    # Verificar timewarrior instalado
    machine.succeed("which timew")
    machine.succeed("timew --version")

    # Verificar taskwarrior instalado
    machine.succeed("which task")

    # Verificar que python3 está disponível (para o timew-summary.py)
    machine.succeed("which python3")

    # Verificar que o hook foi instalado e é executável
    machine.succeed("test -f /root/.local/share/task/hooks/on-modify.timewarrior")
    machine.succeed("test -x /root/.local/share/task/hooks/on-modify.timewarrior")

    # Verificar que o script de métricas foi instalado
    machine.succeed("test -f /root/.config/task/timew-summary.py")
    machine.succeed("test -x /root/.config/task/timew-summary.py")

    # Verificar que o diretório de dados do Timewarrior existe
    machine.succeed("test -d /root/.local/share/timewarrior")

    # Verificar que o script Python retorna JSON válido (sem dados = estrutura vazia)
    machine.succeed("python3 /root/.config/task/timew-summary.py | python3 -c 'import sys,json; d=json.load(sys.stdin); assert \"today\" in d; assert \"week\" in d'")
  '';
}
