# Overlay para manter o Kiro IDE atualizado independente do nixpkgs.
#
# Como obter o hash ao atualizar a versão:
#   1. Atualize 'version' abaixo para a nova versão
#   2. Substitua temporariamente 'hash' por uma string vazia: hash = "";
#   3. Rode: nix build .#nixosConfigurations.nobita.config.system.build.toplevel
#      (ou qualquer rebuild). O Nix vai falhar e informar o hash correto no erro:
#        "hash mismatch ... got: sha256-XXXXXXX"
#   4. Cole o hash correto no campo 'hash'
#
# Alternativa usando nix-prefetch-url:
#   nix-prefetch-url --unpack \
#     "https://prod.download.desktop.kiro.dev/releases/stable/linux-x64/signed/<VERSION>/tar/kiro-ide-<VERSION>-stable-linux-x64.tar.gz"
#   Converta o hash base32 para sri: nix hash to-sri --type sha256 <hash>
#
final: prev:
let
  version = "1.0.182";
in
{
  kiro = prev.stdenv.mkDerivation {
    pname = "kiro";
    inherit version;

    src = final.fetchurl {
      url = "https://prod.download.desktop.kiro.dev/releases/stable/linux-x64/signed/${version}/tar/kiro-ide-${version}-stable-linux-x64.tar.gz";
      # Para obter o hash: veja instruções no topo deste arquivo
      hash = "sha256-ya4UGQmXRxIbxSRvXIV8tSUMj6Pxqp0vgNPMz1hTHtc=";
    };

    nativeBuildInputs = [
      final.autoPatchelfHook
      final.makeWrapper
      final.wrapGAppsHook3
    ];

    buildInputs = [
      final.alsa-lib
      final.at-spi2-atk
      final.cairo
      final.cups
      final.dbus
      final.expat
      final.gdk-pixbuf
      final.glib
      final.gtk3
      final.libcap
      final.libdrm
      final.libGL
      final.libsecret
      final.libsoup_3
      final.libxkbcommon
      final.libxkbfile
      final.mesa
      final.nspr
      final.nss
      final.pango
      final.webkitgtk_4_1
      final.libx11
      final.libxcomposite
      final.libxdamage
      final.libxext
      final.libxfixes
      final.libxrandr
      final.libxcb
    ];

    runtimeDependencies = [
      final.systemd
    ];

    dontBuild = true;
    dontConfigure = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/opt/kiro $out/bin $out/share/applications $out/share/pixmaps

      cp -r . $out/opt/kiro/

      # Symlink do executável principal
      ln -s $out/opt/kiro/kiro $out/bin/kiro

      # Desktop entry
      cat > $out/share/applications/kiro.desktop <<EOF
      [Desktop Entry]
      Name=Kiro
      Comment=Kiro IDE
      Exec=$out/bin/kiro %U
      Icon=kiro
      Type=Application
      Categories=Development;IDE;
      StartupWMClass=kiro
      MimeType=x-scheme-handler/kiro;
      EOF

      # Ícone (o tar geralmente inclui um)
      if [ -f resources/app/resources/linux/code.png ]; then
        cp resources/app/resources/linux/code.png $out/share/pixmaps/kiro.png
      fi

      runHook postInstall
    '';

    meta = {
      description = "Kiro - AI-powered IDE by AWS";
      homepage = "https://kiro.dev";
      platforms = [ "x86_64-linux" ];
      mainProgram = "kiro";
    };
  };
}
