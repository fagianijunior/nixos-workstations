# Overlay para destravar o build do pyopenjtalk-plus (dependência do piper-tts).
#
# Motivo: na transição do nixpkgs para o Python 3.14, a mensagem de erro do
# interpretador ao receber um tipo errado mudou de "must be str" para
# "Expected str, got int". A suíte de testes do pyopenjtalk-plus 0.4.1-post9
# ainda espera a mensagem ANTIGA, então um teste falha e derruba o build:
#
#   FAILED tests/test_frontend.py::test_run_njd_from_mecab_invalid_input_should_not_break_next_call
#     Expected regex: 'must be str'
#     Actual message: 'Expected str, got int'
#
# Isso NÃO é um bug do pacote nem da nossa config: é um teste frágil que casa
# com texto exato de mensagem de erro do CPython. O pacote em si compila e
# funciona; só a verificação de testes no build é que quebra. O piper-tts
# depende do pyopenjtalk-plus, então ele cai junto (e com ele o translate-selection).
#
# Solução: desabilitar a fase de testes (doCheck = false) apenas deste pacote.
# Pulamos só a verificação; o wheel é construído normalmente.
#
# COMO RETESTAR (quando o nixpkgs corrigir o teste upstream):
#   1. Comente a linha 'nixpkgs.overlays' deste overlay no flake.nix (ou remova
#      este arquivo da lista 'overlays').
#   2. Rebuild de teste:
#        sudo nixos-rebuild build --flake .#nobita
#   3. Se o build passar sem o override, o teste foi corrigido upstream: remova
#      este overlay de vez. Se ainda falhar com o mesmo erro, mantenha o override.
#
final: prev:
{
  python3Packages = prev.python3Packages.overrideScope (pyFinal: pyPrev: {
    pyopenjtalk-plus = pyPrev.pyopenjtalk-plus.overridePythonAttrs (old: {
      doCheck = false;
    });
  });
}
