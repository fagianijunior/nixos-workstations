{ pkgs, ... }:

{
  services.ollama = {
    package = pkgs.ollama-rocm;
    enable = true;
    rocmOverrideGfx = "10.3.0"; # Garante que o serviço do Ollama use a variável de override
    host = "0.0.0.0";
    port = 11434;
  };
}
