# Overlay para empacotar o AI-DLC (awslabs/aidlc-workflows), ausente do nixpkgs.
#
# POR QUE ESTE OVERLAY EXISTE
# ---------------------------
# O AI-DLC não tem pacote no nixpkgs. O instalador oficial
# (`curl -fsSL .../install.sh | sh`) baixa em TEMPO DE EXECUÇÃO vários artefatos
# para ~/.local/share/aidlc/... — não reproduzível e contra a convenção deste
# flake (ferramentas empacotadas via Nix, nunca via download/instalador em
# runtime). Aqui reproduzimos a instalação oficial DENTRO do build do Nix.
#
# ATENÇÃO 1: O BINÁRIO SOZINHO NÃO É O AIDLC
# ------------------------------------------
# `aidlc-linux-x64` é apenas o LAUNCHER/INSTALADOR (um executável Bun compilado).
# Chamado cru, ele age como o próprio Bun — p.ex. `aidlc-linux-x64 config`
# responde "bun config is a subcommand reserved for future use by Bun". O CLI de
# verdade só existe depois que o subcomando interno
#   aidlc-linux-x64 system lifecycle install-apply --from <dir> --version <ver>
# monta a árvore de runtime (plugins, agentes, etc.). É isso que o installPhase
# faz, apontando a instalação para dentro de $out/share/aidlc.
#
# O install-apply exige, no diretório --from, EXATAMENTE estes 5 arquivos da
# release (os nomes precisam bater com o que ele procura):
#   aidlc-linux-x64                (launcher/instalador; ELF x86-64 dinâmico)
#   aidlc-runtime-<ver>.tar.gz     (runtime do app: plugins/agentes)
#   version.json                   (metadados da versão)
#   checksums.txt                  (ele reverifica os sha256 internamente)
#   aidlc-release.intoto.jsonl     (provenance SLSA; exigida, mesmo offline)
#
# Ele cria em $out/share/aidlc:
#   versions/<ver>/{aidlc,runtime,plugins,...}
#   active-executable / active-version   (ponteiros)
# e um launcher shell em $out/bin/aidlc. NÓS DESCARTAMOS esse launcher (veja
# ATENÇÃO 2) e criamos o nosso.
#
# ATENÇÃO 2: NÃO USAR patchelf/autoPatchelfHook NESTE BINÁRIO
# -----------------------------------------------------------
# `aidlc-linux-x64` é ELF 64-bit x86-64 DINÂMICO com interpretador
# /lib64/ld-linux-x86-64.so.2 (inexistente no NixOS). O caminho natural seria
# autoPatchelfHook, MAS reescrever o interpretador/RPATH de um executável Bun
# compilado o QUEBRA: ele passa a dar Segmentation fault (verificado nesta
# release). Bun embute suposições sobre o loader que o patchelf invalida.
#
# Solução que FUNCIONA: deixar o ELF intacto e invocá-lo através do loader do
# glibc do Nix explicitamente:
#   ld-linux-x86-64.so.2 --library-path <glibc>/lib:<gcc-lib>/lib  <binário> "$@"
# Fazemos isso tanto no build (para rodar o install-apply) quanto no wrapper
# final que vira $out/bin/aidlc. O launcher shell que o próprio aidlc gera chama
# o binário DIRETAMENTE (segfault no NixOS), por isso o substituímos.
#
# COMO ATUALIZAR A VERSÃO
# -----------------------
#   1. Veja a última release:
#        gh release view --repo awslabs/aidlc-workflows --json tagName,name
#   2. Atualize 'version' abaixo (sem o 'v' do tag).
#   3. Zere os cinco hashes (todos mudam por release):  hash = "";
#   4. Rode repetidamente, colando cada hash que o Nix imprime ("got: sha256-"):
#        nix build '.#nixosConfigurations.nobita.pkgs.aidlc'
#      (Os sha256 hex oficiais estão em checksums.txt da release; converta com
#       nix hash convert --hash-algo sha256 --to sri <sha256hex>.)
#
# COMO RETESTAR
# -------------
#   nix build '.#nixosConfigurations.nobita.pkgs.aidlc'
#   ./result/bin/aidlc --version        # esperado: "aidlc <ver> (runtime <ver>)"
#   ./result/bin/aidlc config --help    # deve mostrar o comando real, não o Bun
#
# CONFIGURAÇÃO POR PROJETO (inalterada)
# -------------------------------------
# Na raiz do projeto:  aidlc config --harness kiro-ide   e depois  aidlc doctor.
# Como o binário agora vem pelo PATH do sistema (Nix), some o problema antigo de
# ~/.local/bin fora do PATH.
#
final: prev:
let
  version = "2.11.3";
  releaseUrl = "https://github.com/awslabs/aidlc-workflows/releases/download/v${version}";

  launcherBin = final.fetchurl {
    url = "${releaseUrl}/aidlc-linux-x64";
    hash = "sha256-lEibGxcTmrawir/7aE62gj5jKbZFyDp5qbHDm94eCDI=";
  };
  runtimeTar = final.fetchurl {
    url = "${releaseUrl}/aidlc-runtime-${version}.tar.gz";
    hash = "sha256-2ghZCD5HaOoEX12Ps5tsZrMaIDAOx9a57ZwZJgANHf8=";
  };
  versionJson = final.fetchurl {
    url = "${releaseUrl}/version.json";
    hash = "sha256-bvSbN57hU+UL0KzmwcAkbNYQZ2D6bGBvQDDpFL9d6b8=";
  };
  checksums = final.fetchurl {
    url = "${releaseUrl}/checksums.txt";
    hash = "sha256-YeYzFm9/nMvQITPxxqa2JWlxMQo805l5urXrWdYQhhw=";
  };
  intoto = final.fetchurl {
    url = "${releaseUrl}/aidlc-release.intoto.jsonl";
    hash = "sha256-UB++FIFZZvlmulcWq0N070ZdvLFkCNy/IWq8UMpay+k=";
  };

  # Loader e libs do glibc do Nix, usados para invocar o ELF Bun sem patchelf.
  libPath = final.lib.makeLibraryPath [ final.glibc final.stdenv.cc.cc.lib ];
  loader = "${final.glibc}/lib/ld-linux-x86-64.so.2";
in
{
  aidlc = prev.stdenv.mkDerivation {
    pname = "aidlc";
    inherit version;

    dontUnpack = true;
    dontConfigure = true;
    dontBuild = true;

    # SEM autoPatchelfHook de propósito (veja ATENÇÃO 2 no topo).
    nativeBuildInputs = [ final.makeWrapper ];

    installPhase = ''
      runHook preInstall

      # Monta o diretório --from com os nomes exatos que o install-apply procura.
      from=$(mktemp -d)
      install -m755 ${launcherBin} "$from/aidlc-linux-x64"
      cp ${runtimeTar} "$from/aidlc-runtime-${version}.tar.gz"
      cp ${versionJson} "$from/version.json"
      cp ${checksums}   "$from/checksums.txt"
      cp ${intoto}      "$from/aidlc-release.intoto.jsonl"

      mkdir -p $out/bin $out/share/aidlc
      export HOME=$(mktemp -d)

      # Roda o instalador através do loader do Nix (não dá para chamar o ELF
      # direto: interpretador /lib64/ld-linux não existe no NixOS).
      #
      # O install-apply, no FINAL, faz um "version probe": executa o launcher
      # shell que ele mesmo acabou de escrever em $out/bin/aidlc. Esse launcher
      # chama o binário versionado DIRETAMENTE e, sem /lib64/ld-linux no sandbox,
      # segfaulta — o probe retorna 127 e o apply sai com erro. A ÁRVORE
      # versions/<ver>/ (binário + runtime + manifestos installed-files.json e
      # runtime-integrity.json) JÁ foi escrita antes do probe, então toleramos a
      # falha do probe e validamos o resultado nós mesmos logo abaixo.
      AIDLC_INSTALL_ROOT="$out/share/aidlc" \
      AIDLC_BIN_DIR="$out/bin" \
        ${loader} --library-path "${libPath}" \
          "$from/aidlc-linux-x64" system lifecycle install-apply \
            --from "$from" --version "${version}" --quiet || \
        echo "install-apply retornou não-zero (provável falha do version probe no sandbox); validando a árvore manualmente"

      # A árvore precisa existir mesmo que o probe tenha falhado.
      test -x "$out/share/aidlc/versions/${version}/aidlc" \
        || (echo "ERRO: binário versionado não foi instalado" >&2; exit 1)

      # O launcher shell que o install-apply deixou (se deixou) chama o binário
      # versionado DIRETAMENTE (segfault no NixOS). Trocamos por um wrapper nosso
      # que invoca o binário pelo loader do glibc.
      rm -f $out/bin/aidlc
      makeWrapper ${loader} $out/bin/aidlc \
        --add-flags "--library-path ${libPath}" \
        --add-flags "$out/share/aidlc/versions/${version}/aidlc"

      runHook postInstall
    '';

    meta = {
      description = "AI-DLC - AI-Driven Development Lifecycle workflows (AWS Labs)";
      homepage = "https://github.com/awslabs/aidlc-workflows";
      platforms = [ "x86_64-linux" ];
      mainProgram = "aidlc";
    };
  };
}
