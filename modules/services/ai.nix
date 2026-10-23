{ pkgs, ... }:

{
  services.ollama = {
    package = pkgs.ollama-rocm;
    enable = true;
    rocmOverrideGfx = "10.3.0"; # Garante que o serviço do Ollama use a variável de override
    host = "0.0.0.0";
    port = 11434;

    # Agentes de código (Cline, etc.) injetam um system prompt enorme com as
    # definições de ferramentas. O default do Ollama (~2-4K tokens) TRUNCA esse
    # prompt, e o modelo nunca vê as instruções de tool-use -- sintoma clássico
    # de "o modelo não usa as tools, só responde em texto".
    #
    # OLLAMA_CONTEXT_LENGTH eleva o num_ctx padrão de TODOS os modelos servidos,
    # sem precisar de Modelfile por modelo. 32768 cobre o prompt do Cline com
    # folga. Custo: mais VRAM/RAM no KV cache (a RX 6600 tem 8GB; modelos 7B Q4
    # cabem com esse contexto). Se faltar VRAM, baixe para 16384.
    #
    # IMPORTANTE: isto resolve só o lado do Ollama. No Cline, ajuste também o
    # campo "Model Context Window" (settings do provider Ollama) para o MESMO
    # valor -- senão o Cline continua estimando pelo default dele.
    environmentVariables = {
      OLLAMA_CONTEXT_LENGTH = "32768";
    };

    # Modelo recomendado para agentic coding/tool-use com o Cline ATUAL.
    #
    # O Cline (>= v3.35) usa NATIVE TOOL CALLING: manda as tools como JSON Schema
    # na API e espera a resposta no campo estruturado `tool_calls`. NÃO usa mais
    # o formato XML-no-system-prompt antigo.
    #
    # Nesse modelo de uso, o que importa é o template de tool-calling do modelo
    # no Ollama emitir `tool_calls` de verdade. Teste nos modelos locais:
    #   - llama3.1:8b      -> emite tool_calls estruturado (content vazio)  [OK]
    #   - qwen2.5-coder:7b -> escreve a tool como TEXTO no content           [QUEBRA]
    # O Cline mostra o JSON do qwen como texto e nao executa a tool (bug conhecido
    # cline#14453). Por isso o llama3.1:8b e a melhor escolha local aqui, apesar de
    # o qwen ser melhor em geracao de codigo puro.
    #
    # Mantemos o qwen2.5-coder para uso NAO-agentico (autocomplete, chat de codigo).
    loadModels = [
      "llama3.1:8b"
      "qwen2.5-coder:7b"
    ];
  };
}
