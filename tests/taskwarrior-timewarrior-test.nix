{ pkgs, self, ... }:

let
  catppuccin = self.inputs.catppuccin;
  home-manager = self.inputs.home-manager;
in
pkgs.testers.nixosTest {
  name = "taskwarrior-timewarrior-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [
      ../modules/common
      home-manager.nixosModules.home-manager
    ];

    fileSystems."/" = {
      device = "/dev/vda1";
      fsType = "ext4";
    };
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # taskwarrior/timewarrior e seus hooks/scripts são configurados via
    # home-manager (ver home/taskwarrior). Carregamos a config real do usuário
    # para testar a integração de verdade, e não uma simulação.
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.extraSpecialArgs = { inherit catppuccin; };
    home-manager.users.terabytes = import ../home/default.nix;

    # Required by home-manager xdg.portal assertion
    environment.pathsToLink = [ "/share/applications" "/share/xdg-desktop-portal" ];

    services.getty.autologinUser = "terabytes";
  };

  testScript = ''
    import json

    machine.start()
    machine.wait_for_unit("multi-user.target")
    machine.wait_until_succeeds("pgrep -u terabytes")

    # As verificações rodam como o usuário terabytes, pois o home-manager
    # instala pacotes e arquivos no ambiente dele (não em /root).

    # Verificar timewarrior instalado e funcional
    machine.succeed("su - terabytes -c 'which timew'")
    machine.succeed("su - terabytes -c 'timew --version'")

    # Verificar taskwarrior instalado
    machine.succeed("su - terabytes -c 'which task'")

    # Verificar que python3 está disponível (para o timew-summary.py)
    machine.succeed("su - terabytes -c 'which python3'")

    # Verificar que o hook foi instalado e é executável
    machine.succeed("test -f /home/terabytes/.local/share/task/hooks/on-modify.timewarrior")
    machine.succeed("test -x /home/terabytes/.local/share/task/hooks/on-modify.timewarrior")

    # Verificar que o script de métricas foi instalado
    machine.succeed("test -f /home/terabytes/.config/task/timew-summary.py")
    machine.succeed("test -x /home/terabytes/.config/task/timew-summary.py")

    # Verificar que o diretório de dados do Timewarrior existe
    machine.succeed("test -d /home/terabytes/.local/share/timewarrior")

    # Verificar que o script Python retorna JSON válido (sem dados = estrutura vazia).
    # Roda como terabytes (python3 vem do PATH do home-manager). Capturamos o JSON
    # e validamos a estrutura em Python no lado do driver, evitando aninhamento de aspas.
    output = machine.succeed("su - terabytes -c 'python3 ~/.config/task/timew-summary.py'")
    data = json.loads(output)
    assert "today" in data, f"JSON sem chave 'today': {output}"
    assert "week" in data, f"JSON sem chave 'week': {output}"
  '';
}
