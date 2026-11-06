# Overlay para manter o ClickUp desktop disponível independente do nixpkgs.
#
# O ClickUp é distribuído como AppImage, mas o site oficial só publica a versão
# mais recente. Por isso usamos o archive.org para fixar uma versão específica
# e reproduzível.
#
# Como atualizar a versão:
#   O pacote expõe um updateScript (passthru.updateScript). Rode:
#     nix run .#nixosConfigurations.nobita.pkgs.clickup.updateScript
#   Ele consulta a versão upstream, arquiva o download no archive.org e atualiza
#   'version'/'hash'/'url' automaticamente.
#
# Como obter o hash manualmente ao mudar a versão:
#   1. Atualize 'version' (e a 'url' arquivada, se necessário)
#   2. Deixe 'hash' como string vazia: hash = "";
#   3. Rode um rebuild. O Nix vai falhar e informar o hash correto:
#        "hash mismatch ... got: sha256-XXXXXXX"
#   4. Cole o hash no campo 'hash'
#
final: prev:
let
  pname = "clickup";
  version = "3.5.402";

  src = final.fetchurl {
    # Using archive.org because the website doesn't store older versions of the software.
    url = "https://desktop.clickup.com/linux";
    hash = "sha256-uqH79o2lk9uhBWzxQCrduN4wkPryr4s+6wIBeFlBZ00=";
  };

  appimage = final.appimageTools.wrapType2 {
    inherit pname version src;
    extraPkgs = pkgs: [ pkgs.libxkbfile ];
  };

  appimageContents = final.appimageTools.extract { inherit pname version src; };
in
{
  clickup = prev.stdenvNoCC.mkDerivation {
    inherit pname version;

    src = appimage;

    nativeBuildInputs = [
      final.makeWrapper
      final.desktop-file-utils
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/
      cp -r bin $out/bin

      mkdir -p $out/share/${pname}
      cp -r ${appimageContents}/locales $out/share/${pname}
      cp -r ${appimageContents}/resources $out/share/${pname}
      cp -r --no-preserve=mode ${appimageContents}/usr/share/icons $out/share/
      find $out/share/icons -name desktop.png -execdir mv {} clickup.png \;

      install -m 444 -D ${appimageContents}/desktop.desktop $out/share/applications/clickup.desktop

      desktop-file-edit \
        --set-key=Exec --set-value=clickup \
        --set-key=Icon --set-value=clickup \
        "$out/share/applications/clickup.desktop"

      wrapProgram $out/bin/${pname} \
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations,WebRTCPipeWireCapturer}} --no-update"

      runHook postInstall
    '';

    passthru.updateScript = final.lib.getExe (final.writeShellApplication {
      name = "update-clickup";
      runtimeInputs = [
        final.curl
        final.common-updater-scripts
      ];
      text = ''
        upstream_version="$(curl --silent --location --range 0-0 --dump-header - --output /dev/null https://desktop.clickup.com/linux | grep --only-matching --extended-regexp '[0-9]+\.[0-9]+\.[0-9]+')"

        current_version="$(nix-instantiate --eval --strict -A clickup.version | tr -d '"')"

        if [[ "$current_version" = "$upstream_version" ]]; then
          echo "clickup is already up-to-date at $current_version"
          exit 0
        fi

        echo "Updating clickup from $current_version to $upstream_version"

        echo "Saving new version to archive.org..."
        archived_url="$(curl --silent --max-time 600 --output /dev/null --dump-header - "https://web.archive.org/save/https://desktop.clickup.com/linux" | grep --ignore-case '^location:' | tr -d '\r' | cut -d' ' -f2)"

        if [[ -z "$archived_url" || "$archived_url" != *"web.archive.org/web/"* ]]; then
          echo "error: failed to archive URL on archive.org" >&2
          exit 1
        fi

        update-source-version clickup "$upstream_version" "" "$archived_url" \
          --source-key=src.src
      '';
    });

    meta = {
      description = "All in one project management solution";
      homepage = "https://clickup.com";
      license = final.lib.licenses.unfree;
      mainProgram = "clickup";
      maintainers = with final.lib.maintainers; [ heisfer ];
      platforms = [ "x86_64-linux" ];
    };
  };
}
