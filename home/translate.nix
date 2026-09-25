{ pkgs, ... }:

let
  # ---------------------------------------------------------------------------
  # Voz do Piper (TTS neural offline) — italiano, voz "paola" (medium).
  # Os dois arquivos (.onnx + .onnx.json) precisam ficar no MESMO diretório com
  # os nomes canônicos: o piper deriva o caminho do config a partir do modelo e
  # ignora um -c apontando para outro lugar. Por isso juntamos ambos num único
  # diretório do store.
  # ---------------------------------------------------------------------------
  voiceBase = "it_IT-paola-medium";
  voiceUrl = "https://huggingface.co/rhasspy/piper-voices/resolve/main/it/it_IT/paola/medium";

  voiceOnnx = pkgs.fetchurl {
    url = "${voiceUrl}/${voiceBase}.onnx";
    hash = "sha256-b8kYtaDqYTc4KDPd36Vnv/vmpQYMAgQ8hxku5ZwEIQw=";
  };
  voiceConfig = pkgs.fetchurl {
    url = "${voiceUrl}/${voiceBase}.onnx.json";
    hash = "sha256-rqGcCn/OKfvDWbk/EOeQKFRAHkyVri6jKK5RaxXSls8=";
  };

  piperVoice = pkgs.runCommand "piper-voice-${voiceBase}" { } ''
    mkdir -p "$out"
    cp ${voiceOnnx}   "$out/${voiceBase}.onnx"
    cp ${voiceConfig} "$out/${voiceBase}.onnx.json"
  '';
  voiceModel = "${piperVoice}/${voiceBase}.onnx";

  # ---------------------------------------------------------------------------
  # Modelos do Argos Translate (tradução neural OFFLINE). Não existe modelo
  # italiano->português direto, então usamos inglês como pivô: it->en e en->pb
  # (Português do Brasil). O Argos encadeia as duas etapas automaticamente
  # quando ambos os pacotes estão instalados.
  #
  # Cada .argosmodel é um zip contendo uma pasta raiz com metadata.json. O
  # ARGOS_PACKAGES_DIR precisa ter essas pastas como subdiretórios diretos, por
  # isso extraímos os dois zips no MESMO diretório do store.
  # ---------------------------------------------------------------------------
  argosItEn = pkgs.fetchurl {
    url = "https://argos-net.com/v1/translate-it_en-1_0.argosmodel";
    hash = "sha256-0t0juLcC9hK4En8Hx6A5H18qi5M0Tm3cndk8gYJOhcs=";
  };
  argosEnPb = pkgs.fetchurl {
    url = "https://argos-net.com/v1/translate-en_pb-1_9.argosmodel";
    hash = "sha256-HRzV6VQMazjCWL7QAqQtOzEbihiay3T+qjEe8w0XXFs=";
  };

  # Modelos MiniSBD (segmentação de frases) para as línguas de ORIGEM de cada
  # etapa do pivô: it (para it->en) e en (para en->pb). Necessários para manter
  # tudo offline — ver comentário abaixo.
  minisbdIt = pkgs.fetchurl {
    url = "https://github.com/LibreTranslate/MiniSBD/releases/download/v0.0.1/it.onnx";
    hash = "sha256-raRAtQl/IJmm6c8Gc2dIBfj5UjagKRBGbFT2r9jdIY8=";
  };
  minisbdEn = pkgs.fetchurl {
    url = "https://github.com/LibreTranslate/MiniSBD/releases/download/v0.0.1/en.onnx";
    hash = "sha256-b6nzo7IBaHvUPjKbKwc2eJ78l7N4g7W3WbMZiNyp81M=";
  };

  # Monta o diretório de pacotes do Argos, tornando-o auto-contido e offline:
  #
  #   - Os .argosmodel trazem um segmentador de frases baseado em stanza, mas o
  #     stanza 1.14 (nixpkgs) é INCOMPATÍVEL com o resources.json embutido e,
  #     pior, sempre tenta baixar recursos da rede. Então REMOVEMOS o diretório
  #     stanza/ de cada pacote.
  #   - Sem stanza, o Argos usa o MiniSBDSentencizer, que procura um modelo
  #     minisbd/<lang>.onnx dentro do pacote; se não achar, baixa da rede. Então
  #     INJETAMOS o modelo local (it.onnx no it_en, en.onnx no en_pb).
  #
  # Resultado: nenhuma etapa toca a rede, e como o MiniSBD não escreve no
  # diretório do pacote, podemos apontar ARGOS_PACKAGES_DIR direto para o store
  # (read-only) — sem precisar espelhar para um cache gravável.
  argosPackages = pkgs.runCommand "argos-packages-it-pb" { nativeBuildInputs = [ pkgs.unzip ]; } ''
    mkdir -p "$out"
    unzip -q ${argosItEn} -d "$out"
    unzip -q ${argosEnPb} -d "$out"

    # Remove o segmentador stanza (incompatível/online) de todos os pacotes.
    rm -rf "$out"/*/stanza

    # Injeta os modelos MiniSBD locais (língua de origem de cada etapa).
    mkdir -p "$out/it_en/minisbd"
    cp ${minisbdIt} "$out/it_en/minisbd/it.onnx"
    mkdir -p "$out/translate-en_pb-1_9/minisbd"
    cp ${minisbdEn} "$out/translate-en_pb-1_9/minisbd/en.onnx"
  '';

  argostranslate = pkgs.python3Packages.argostranslate;

  # Arquivo compartilhado entre o tradutor (escreve) e o viewer (lê).
  outFile = "\${XDG_RUNTIME_DIR:-/tmp}/translate-selection.txt";

  # ---------------------------------------------------------------------------
  # translate-selection — captura o texto selecionado (primary selection, com
  # fallback para o clipboard normal), traduz italiano -> português do Brasil
  # de forma 100% OFFLINE (Argos Translate, pivô it->en->pb) e escreve o
  # resultado no arquivo lido pelo scratchpad.
  #
  # Uso:
  #   translate-selection            -> só traduz (Argos, offline)
  #   translate-selection --speak    -> traduz e fala o texto ORIGINAL com o
  #                                     Piper (TTS neural offline, sem limite
  #                                     de caracteres, voz italiana).
  # ---------------------------------------------------------------------------
  translate-selection = pkgs.writeShellApplication {
    name = "translate-selection";
    runtimeInputs = [ pkgs.wl-clipboard argostranslate pkgs.piper-tts pkgs.mpv ];
    text = ''
      SPEAK=0
      if [ "''${1:-}" = "--speak" ]; then
        SPEAK=1
      fi

      OUT_FILE="${outFile}"

      # 1) Captura o texto: preferimos a seleção primária (texto apenas
      #    destacado, sem Ctrl+C). Se vazia, caímos para o clipboard normal.
      TEXT="$(wl-paste --primary --no-newline 2>/dev/null | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g' || true)"
      if [ -z "''${TEXT//[[:space:]]/}" ]; then
        TEXT="$(wl-paste --no-newline 2>/dev/null || true)"
      fi

      if [ -z "''${TEXT//[[:space:]]/}" ]; then
        {
          echo "Nenhum texto selecionado."
          echo
          echo "Selecione um texto (destaque com o mouse ou copie com Ctrl+C)"
          echo "e acione a tradução novamente."
        } >"$OUT_FILE"
        exit 0
      fi

      # 2) Traduz italiano -> português do Brasil, 100% offline (Argos, pivô
      #    it->en->pb). ARGOS_STANZA_AVAILABLE=False força o segmentador MiniSBD
      #    (que usa os modelos .onnx locais injetados no pacote). O Argos ainda
      #    precisa de um HOME gravável para cache/config, mas o diretório de
      #    pacotes (ARGOS_PACKAGES_DIR) pode ser o store read-only.
      ARGOS_HOME="''${XDG_RUNTIME_DIR:-/tmp}/argos-home"
      mkdir -p "$ARGOS_HOME"
      TRANSLATION="$(printf '%s' "$TEXT" \
        | HOME="$ARGOS_HOME" \
          ARGOS_PACKAGES_DIR="${argosPackages}" \
          ARGOS_STANZA_AVAILABLE=False \
          argos-translate -f it -t pb 2>/dev/null || true)"
      if [ -z "''${TRANSLATION//[[:space:]]/}" ]; then
        TRANSLATION="(falha ao traduzir)"
      fi

      # 3) Monta a saída exibida no scratchpad.
      {
        echo "──────────── ORIGINAL ────────────"
        echo
        echo "$TEXT"
        echo
        echo "──────────── PORTUGUÊS ───────────"
        echo
        echo "$TRANSLATION"
      } >"$OUT_FILE"

      # 4) TTS opcional: fala o texto ORIGINAL com o Piper (offline, italiano).
      #    Piper gera WAV em stdout (--output-raw seria PCM cru); usamos um
      #    arquivo temporário e tocamos com mpv. Roda em background para não
      #    travar a exibição da tradução.
      if [ "$SPEAK" -eq 1 ]; then
        (
          WAV="$(mktemp --suffix=.wav)"
          # shellcheck disable=SC2001
          if printf '%s' "$TEXT" | piper -m "${voiceModel}" --length_scale 2 -f "$WAV" >/dev/null 2>&1; then
            sleep 1
            mpv --no-terminal --really-quiet "$WAV" >/dev/null 2>&1 || true
          fi
          rm -f "$WAV"
        ) &
      fi
    '';
  };

  # ---------------------------------------------------------------------------
  # translate-viewer — roda DENTRO do scratchpad (wezterm). Exibe o conteúdo do
  # arquivo de tradução e re-renderiza sempre que ele muda, para que reabrir o
  # scratchpad após uma nova tradução mostre o texto atualizado sem recriar a
  # janela.
  # ---------------------------------------------------------------------------
  translate-viewer = pkgs.writeShellApplication {
    name = "translate-viewer";
    runtimeInputs = with pkgs; [ bat coreutils ];
    text = ''
      OUT_FILE="${outFile}"

      render() {
        clear
        bat --paging=never --style=plain --wrap=auto "$OUT_FILE" 2>/dev/null || cat "$OUT_FILE"
        echo
        echo "  [Super+T] traduzir seleção   ·   [Super+Shift+T] traduzir + falar"
        echo "  clique fora para esconder"
      }

      [ -f "$OUT_FILE" ] || echo "Aguardando tradução..." >"$OUT_FILE"

      render
      last="$(stat -c %Y "$OUT_FILE" 2>/dev/null || echo 0)"

      while true; do
        sleep 0.5
        now="$(stat -c %Y "$OUT_FILE" 2>/dev/null || echo 0)"
        if [ "$now" != "$last" ]; then
          last="$now"
          render
        fi
      done
    '';
  };
in
{
  home.packages = [
    translate-selection
    translate-viewer
  ];
}
