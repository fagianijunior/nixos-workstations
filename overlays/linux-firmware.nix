# Overlay para pinar o linux-firmware numa versão específica.
#
# Motivo: o linux-firmware 20260910 (introduzido via flake update, nixpkgs ef34387)
# trouxe uma revisão do firmware do DMCUB (yellow_carp_dmcub.bin) que o PSP do APU
# Rembrandt (RADEON 680M) do doraemon REJEITA no arranque. Sintomas:
#
#   [drm] Loading DMUB firmware via PSP: version=0x0400004A
#   [drm] *ERROR* Error getting DMUB FW meta info: 4
#   failed to load ucode DMCUB(0x3F)
#   psp gfx command LOAD_IP_FW(0x6) failed and response status is (0xFFFF0008)
#   [drm] Wait for DMUB auto-load failed: 3
#
# Sem o DMCUB (microcontrolador de display), o amdgpu cai em modo degradado:
# HDMI não funciona, renderização lenta, controle de brilho travado.
#
# Comprovado por bisseção entre gerações NixOS:
#   - linux-firmware 20260810 -> DMCUB carrega OK (gen 72, funcional)
#   - linux-firmware 20260910 -> DMCUB falha  (gen 73/74, quebrado)
#
# O kernel NÃO é a causa: a falha ocorre tanto no zen 7.2.4 quanto no LTS 6.12
# quando pareados com o firmware 20260910.
#
# Solução: pinar o linux-firmware em 20260810 até uma revisão futura do
# yellow_carp_dmcub.bin voltar a ser aceita pelo PSP.
#
# IMPORTANTE: enquanto este overlay estiver ativo, `nix flake update` atualiza o
# nixpkgs e o kernel normalmente, mas o linux-firmware fica PRESO em 20260810. O
# kernel nunca foi o problema, então NÃO há relação entre "kernel novo" e este pin.
# O gatilho para reavaliar é FIRMWARE NOVO, não kernel novo.
#
# COMO RETESTAR (quando quiser verificar se a regressão do DMCUB já foi corrigida):
#   1. Descubra a versão de firmware que o nixpkgs travado oferece:
#        nix eval --raw .#nixosConfigurations.doraemon.pkgs.linux-firmware.version
#      Se for > 20260910, vale testar. (versões = datas YYYYMMDD)
#   2. Comente as linhas 'version' e 'src' abaixo (ou remova este overlay do flake.nix)
#      para usar o firmware do nixpkgs sem override.
#   3. Rebuild de teste SEM ativar no boot:
#        sudo nixos-rebuild test --flake .#doraemon
#   4. Cheque o DMCUB no boot atual:
#        journalctl -b -0 | grep -c "DMCUB error"   # 0 = corrigido; >0 = ainda quebrado
#      (com `test`, um reboot volta ao estado pinado sem risco)
#   5. Se 0: remova o overlay de vez. Se >0: mantenha o pin e siga em 20260810.
#
# Como obter o hash ao mudar a versão (se pinar em OUTRA data):
#   1. Atualize 'firmwareVersion' abaixo
#   2. Deixe 'srcHash' como "" (string vazia)
#   3. Rode um rebuild/eval; o Nix falha e informa o hash correto ("got: sha256-...")
#   4. Cole o hash em 'srcHash'
#
final: prev:
let
  firmwareVersion = "20260810";
  # Hash do tarball do source (archive da tag no GitLab do kernel-firmware).
  # Preencha após o primeiro eval falhar com o hash correto.
  srcHash = "sha256-P/fPpqaatp8Z2GV+I/OChiWGn6AhV+8w1RMFuX/LqHc=";
in
{
  linux-firmware = prev.linux-firmware.overrideAttrs (old: {
    version = firmwareVersion;
    src = prev.fetchFromGitLab {
      owner = "kernel-firmware";
      repo = "linux-firmware";
      rev = firmwareVersion;
      hash = srcHash;
    };
  });
}
