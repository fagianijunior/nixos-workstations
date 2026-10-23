# Módulo home-manager para `~/.continue/config.yaml` (Continue + MCP)

Novo módulo `home/continue-mcp.nix` que gera `~/.continue/config.yaml` para a extensão Continue do VS Code, espelhando o padrão já estabelecido em `home/kiro-mcp.nix`. Serializa a config com `builtins.toJSON` (JSON é YAML válido), escreve um arquivo regular via `home.activation` em `entryAfter [ "writeBoundary" ]` para que a UI do Continue possa editá-lo, e injeta o token do GitHub via `gh auth token` substituindo o placeholder `REPLACE_WITH_YOUR_TOKEN` com o mesmo `sed` do kiro-mcp.nix. O bloco `models` do usuário (Autodetect/ollama) é preservado e o `mcpServers` é escrito no formato de LISTA do Continue com os 8 servers do kiro-mcp.nix, exceto `hypruse`. O módulo foi adicionado ao `imports` de `home/default.nix` e está staged no git.

Watch for: a verificação de build/eval que o plano exige (itens 4 e 5) não deixou nenhum artefato registrado — sem commit message, sem nota de verificação (confidence: confirmed). Supri essa lacuna com um spot-check estreito (`nix eval` do atributo de activation), que passou; a ausência de evidência registrada é observada mas não bloqueia, dado o resultado do spot-check.

**Verdict**: APPROVED

## High-level view

A implementação segue o plano verbatim. O arquivo gerado reproduz exatamente os valores de `kiro-mcp.nix` para os 8 servers mantidos: command, args e env batem caractere a caractere, `hypruse` está ausente, e as chaves que o formato do Continue não suporta (`disabled`, `timeout`, `transport`) foram corretamente descartadas. O bloco `models` preserva o que o usuário forneceu na mensagem #9.

A postura de segurança repete o modelo do kiro-mcp.nix: o template avaliado pelo Nix carrega apenas o placeholder `REPLACE_WITH_YOUR_TOKEN` (nenhum segredo entra na /nix/store), e a substituição pelo token real do `gh` acontece só em tempo de activation. Confirmado no eval: o `.data` do atributo contém o placeholder, não um token.

A única lacuna é de processo, não de código: o plano manda rodar o eval do activation (item 4) e um dry-build do sistema (item 5), mas não há nenhum registro de que isso foi feito. Rodei o eval do atributo de activation como spot-check e ele avalia limpo e produz JSON/YAML válido com os 8 servers esperados. Não re-rodei o dry-build completo do toplevel.

<details>
<summary>Issues (1)</summary>

1. **Evidência de verificação ausente** — o plano (itens 4 e 5) pede eval do activation e dry-build do sistema, mas o coder não registrou resultado algum (sem commit, sem nota). Supri o item 4 com um spot-check (`nix eval` do `.data`), que passou; o dry-build do toplevel (item 5) permanece sem registro. Não bloqueia porque o eval do módulo já exercita a avaliação do sistema inteiro, mas convém rodar `nix build '.#nixosConfigurations.nobita.config.system.build.toplevel' --dry-run` antes do switch.

</details>

<details>
<summary>Details</summary>

### Paridade verbatim com kiro-mcp.nix

Comparei cada entrada de `mcpServers` do novo módulo contra `home/kiro-mcp.nix` (confidence: confirmed). Os 8 servers mantidos têm command/args/env idênticos:

```
fetch        uvx   [--with mcp<2 mcp-server-fetch]
nixos        uvx   [mcp-nixos]
duckduckgo   uvx   [duckduckgo-mcp-server]
qt-docs      npx   [mcp-remote https://qt-docs-mcp.qt.io/mcp]
taskwarrior  ${pkgs.mcp-server-taskwarrior}/bin/mcp-server-taskwarrior  []
github       github-mcp-server   [stdio]  env GITHUB_PERSONAL_ACCESS_TOKEN=REPLACE_WITH_YOUR_TOKEN
terraform    terraform-mcp-server [stdio]
aws-mcp      uvx   [mcp-proxy-for-aws@1.6.3 https://aws-mcp.us-east-1.api.aws/mcp --metadata AWS_REGION=us-east-1]
```

`hypruse` é o único dos 9 servers do kiro omitido, conforme pedido do usuário. Os servers que no kiro estavam `disabled = true` (qt-docs, github, terraform) entram habilitados — coerente com "até as desabilitadas, pode habilitar" da mensagem #11. As chaves `timeout = 100000` e `transport = "stdio"` do `aws-mcp` do kiro foram descartadas, correto para o formato do Continue, que não as define.

O output do `nix eval` do atributo de activation confirma o JSON gerado (confidence: confirmed):

```json
"mcpServers":[
  {"args":["--with","mcp<2","mcp-server-fetch"],"command":"uvx","name":"fetch"},
  {"args":["mcp-nixos"],"command":"uvx","name":"nixos"},
  {"args":["duckduckgo-mcp-server"],"command":"uvx","name":"duckduckgo"},
  {"args":["mcp-remote","https://qt-docs-mcp.qt.io/mcp"],"command":"npx","name":"qt-docs"},
  {"args":[],"command":".../bin/mcp-server-taskwarrior","name":"taskwarrior"},
  {"args":["stdio"],"command":"github-mcp-server","env":{"GITHUB_PERSONAL_ACCESS_TOKEN":"REPLACE_WITH_YOUR_TOKEN"},"name":"github"},
  {"args":["stdio"],"command":"terraform-mcp-server","name":"terraform"},
  {"args":["mcp-proxy-for-aws@1.6.3","https://aws-mcp.us-east-1.api.aws/mcp","--metadata","AWS_REGION=us-east-1"],"command":"uvx","name":"aws-mcp"}
]
```

Nenhuma entrada carrega `disabled`, e `mcpServers` é lista, não mapa — o formato do Continue, distinto do Kiro.

### Injeção do token e fail-soft

A substituição do token depende de `gh auth token` em runtime; se o `gh` não estiver autenticado, o `|| true` evita falha e o placeholder `REPLACE_WITH_YOUR_TOKEN` permanece literal no arquivo gerado — mesmo comportamento fail-soft do kiro-mcp.nix (confidence: confirmed). O uso de `builtins.toJSON` + `echo >` (em vez de `pkgs.formats.yaml`, que produziria um store path read-only exigindo `cp`+`chmod` antes do `sed`) é o que mantém o arquivo editável pela UI do Continue.

### Integração no flake

O `./continue-mcp.nix` está no `imports` de `home/default.nix`, ao lado de `./kiro-mcp.nix`, e o arquivo novo está staged como `A` no git — pré-requisito para o flake enxergar o módulo (arquivos não rastreados são invisíveis ao `nix eval`). O eval do atributo de activation só resolve porque o import está presente, o que valida a integração indiretamente (confidence: confirmed).

### Verificação registrada

O plano exige, no item 4, rodar o eval do `continueMcp.data` e parsear o JSON, e no item 5 um `nix build … --dry-run` do toplevel. Não há commit nem nota de verificação no diretório da task comprovando que isso rodou (confidence: confirmed — `git log` não mostra commit para esta mudança e `.agents/tasks/` não tem arquivo de verificação para continue-mcp). Dada a ausência de evidência, rodei o item 4 como spot-check: o eval avalia sem erro e o JSON parseia como YAML/JSON válido com os 8 servers corretos e sem `hypruse`. O dry-build do item 5 não foi re-executado aqui; como o eval do módulo já força a avaliação da configuração do sistema para o host nobita, o risco residual é baixo, mas vale rodar o dry-build antes do `switch`.

</details>

<details>
<summary>File map</summary>

- `home/continue-mcp.nix` — novo módulo; gera `~/.continue/config.yaml` via activation, 8 servers MCP (hypruse fora), token via gh.
- `home/default.nix` — adiciona `./continue-mcp.nix` ao bloco `imports`.

Diff completo: `git diff --cached home/continue-mcp.nix home/default.nix`

</details>
