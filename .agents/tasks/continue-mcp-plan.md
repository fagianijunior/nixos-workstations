# Implementation Plan — Módulo home-manager para `~/.continue/config.yaml` (Continue + MCP)

## Objetivo

Criar um módulo home-manager (`home/continue-mcp.nix`) que gera `~/.continue/config.yaml`
da extensão Continue (VS Code), no MESMO estilo de `home/kiro-mcp.nix`:

- Escreve um **arquivo regular** (não symlink) via `home.activation` em
  `entryAfter [ "writeBoundary" ]`, para que a UI do Continue ainda possa editar o arquivo.
- Preserva o bloco `models` atual do usuário (Autodetect / ollama / AUTODETECT).
- Adiciona um bloco `mcpServers` no formato do Continue (LISTA de objetos).
- Injeta o token do GitHub via `${pkgs.gh}/bin/gh auth token`, substituindo o placeholder
  `REPLACE_WITH_YOUR_TOKEN` com o mesmo padrão de `sed` de `kiro-mcp.nix`.
- Inclui TODOS os servers de `kiro-mcp.nix` EXCETO `hypruse`.

## Decisões de design (grounded no código lido)

**D1 — Serialização do YAML: usar `builtins.toJSON`.**
JSON é um subconjunto válido de YAML 1.2, então `builtins.toJSON` produz um arquivo que o
Continue parseia sem problemas. Escolhido por três razões concretas:
1. Espelha exatamente `kiro-mcp.nix`, que já usa `builtins.toJSON` + `echo '...' > arquivo` +
   `sed`. Manter o mesmo padrão reduz superfície de erro e mantém a consistência do repo.
2. A substituição do token por `sed` opera sobre o conteúdo inline no script de activation.
   Com `builtins.toJSON` o conteúdo é uma string no Nix (interpolável direto no heredoc/echo),
   igual ao kiro-mcp. Já `(pkgs.formats.yaml {}).generate` produz um **store path** (arquivo
   read-only na /nix/store), o que forçaria `cp $storePath dest && chmod +w dest && sed -i dest`
   — mais passos e um `chmod` extra para tornar o arquivo editável pela UI.
3. O Continue aceita JSON-como-YAML; a chave `env.GITHUB_PERSONAL_ACCESS_TOKEN` com o token
   injetado continua sendo string JSON válida após o `sed`.
   Nota: a desvantagem é legibilidade (fica JSON, não YAML indentado). É aceitável porque o
   objetivo primário é um arquivo válido e editável pela UI; a UI do Continue reescreve o
   arquivo quando o usuário edita pela interface.

**D2 — Formato do `mcpServers`: LISTA de objetos (confirmado na doc oficial).**
A referência oficial do Continue (https://docs.continue.dev/reference, seção `mcpServers`)
define `mcpServers` como uma lista cujos itens têm: `name` (required), `command` (required),
`args` (array opcional), `env` (map opcional), além de `cwd`/`requestOptions`/`connectionTimeout`
opcionais. **NÃO existe a chave `disabled`** (ao contrário do formato do Kiro). Servers
indesejados são simplesmente omitidos da lista. Conteúdo foi reescrito para conformidade com
restrições de licenciamento.

**D3 — Chaves do Kiro que NÃO existem no Continue são descartadas.**
No `aws-mcp` do kiro-mcp.nix existem `timeout = 100000` e `transport = "stdio"`. O formato do
Continue não tem `timeout`/`transport`/`disabled`. Descartamos essas chaves e mantemos apenas
`name`/`command`/`args`/`env`. (O `connectionTimeout` do Continue existe mas tem semântica
diferente; não mapeamos automaticamente — manter simples.)

**D4 — `hypruse` fica de fora.** Pedido explícito do usuário. Não entra na lista.

### Divergências encontradas entre o enunciado e `kiro-mcp.nix` (fonte da verdade = kiro-mcp.nix)

Li `home/kiro-mcp.nix` inteiro e confirmei os valores verbatim. As divergências abaixo foram
resolvidas a favor do `kiro-mcp.nix`:

- **`github`**: em `kiro-mcp.nix` está `disabled = true`. No Continue não há `disabled`, então
  o server é **incluído habilitado** (o enunciado pede "até as desabilitadas, pode habilitar").
  `command = "github-mcp-server"`, `args = [ "stdio" ]`,
  `env.GITHUB_PERSONAL_ACCESS_TOKEN = "REPLACE_WITH_YOUR_TOKEN"`. ✔ bate com o enunciado.
- **`terraform`**: em `kiro-mcp.nix` está `disabled = true`. Incluído habilitado no Continue.
  `command = "terraform-mcp-server"`, `args = [ "stdio" ]`. ✔
- **`qt-docs`**: em `kiro-mcp.nix` está `disabled = true`. Incluído habilitado no Continue.
  `command = "npx"`, `args = [ "mcp-remote" "https://qt-docs-mcp.qt.io/mcp" ]`. ✔
- **`aws-mcp`**: além de `command`/`args`, `kiro-mcp.nix` tem `timeout = 100000` e
  `transport = "stdio"` (ver D3). Essas duas chaves são **descartadas** no Continue.
  `command = "uvx"`, `args = [ "mcp-proxy-for-aws@1.6.3"
  "https://aws-mcp.us-east-1.api.aws/mcp" "--metadata" "AWS_REGION=us-east-1" ]`. ✔
- **`fetch`, `nixos`, `duckduckgo`, `taskwarrior`**: valores idênticos ao enunciado. ✔
- Todos os demais servers do kiro têm `disabled = false` e entram normalmente.

### Lista final de servers no `mcpServers` do Continue (7 servers, hypruse excluído)

1. `fetch` — command `uvx`, args `[ "--with" "mcp<2" "mcp-server-fetch" ]`
2. `nixos` — command `uvx`, args `[ "mcp-nixos" ]`
3. `duckduckgo` — command `uvx`, args `[ "duckduckgo-mcp-server" ]`
4. `qt-docs` — command `npx`, args `[ "mcp-remote" "https://qt-docs-mcp.qt.io/mcp" ]`
5. `taskwarrior` — command `${pkgs.mcp-server-taskwarrior}/bin/mcp-server-taskwarrior`, args `[ ]`
6. `github` — command `github-mcp-server`, args `[ "stdio" ]`,
   env `{ GITHUB_PERSONAL_ACCESS_TOKEN = "REPLACE_WITH_YOUR_TOKEN"; }`
7. `terraform` — command `terraform-mcp-server`, args `[ "stdio" ]`
8. `aws-mcp` — command `uvx`,
   args `[ "mcp-proxy-for-aws@1.6.3" "https://aws-mcp.us-east-1.api.aws/mcp" "--metadata" "AWS_REGION=us-east-1" ]`

(São 8 servers no total — hypruse é o único omitido dos 9 do kiro-mcp.nix.)

### Bloco `models` a preservar (verbatim do pedido do usuário, mensagem #9)

```yaml
name: Main Config
version: 1.0.0
schema: v1
models:
  - name: Autodetect
    provider: ollama
    model: AUTODETECT
    apiBase: http://localhost:11434
    roles: [ chat, edit, apply ]
    capabilities: [ tool_use ]
    defaultCompletionOptions:
      contextLength: 32768
      temperature: 0.1
```

Representado em Nix como atributos (serializados por `builtins.toJSON`):
`name = "Main Config"; version = "1.0.0"; schema = "v1";` e `models = [ { ... } ]` com
`roles = [ "chat" "edit" "apply" ]`, `capabilities = [ "tool_use" ]`,
`defaultCompletionOptions = { contextLength = 32768; temperature = 0.1; }`.
Nota: o enunciado usa `name: Main Config`; a mensagem #9 do usuário também diz
`name: Main Config`. Mantido `Main Config`.

---

# Itens de implementação (ordenados por dependência)

- [ ] 1. Criar o módulo `home/continue-mcp.nix`.
      Cabeçalho `{ lib, pkgs, ... }:`. Num bloco `let`, montar o atributo de config com
      `builtins.toJSON { name = "Main Config"; version = "1.0.0"; schema = "v1";
      models = [ { ... } ]; mcpServers = [ { name=...; command=...; args=...; (env=...)? } ... ]; }`
      seguindo o bloco `models` da seção acima e a lista final de 8 servers (hypruse fora).
      Cada entrada de `mcpServers` é um attrset com `name`, `command`, `args` e — só quando
      houver — `env`. NÃO incluir `disabled`, `timeout` nem `transport`. Definir o
      `home.activation.continueMcp = lib.hm.dag.entryAfter [ "writeBoundary" ]` que:
      (a) `mkdir -p "$HOME/.continue"`;
      (b) `echo '<json>' > "$HOME/.continue/config.yaml"` (arquivo regular);
      (c) injeta o token: `GH_TOKEN=$(${pkgs.gh}/bin/gh auth token 2>/dev/null || true)` e, se
      não vazio, `sed -i "s/REPLACE_WITH_YOUR_TOKEN/$GH_TOKEN/" "$HOME/.continue/config.yaml"`
      — EXATAMENTE o mesmo padrão de sed do `kiro-mcp.nix`.
      Incluir comentários em português no tom dos outros módulos explicando: (i) por que arquivo
      regular e não symlink (para a UI do Continue poder editar; próximo `home-manager switch`
      regenera com a config canônica + token novo); (ii) por que `hypruse` está de fora (pedido
      do usuário); (iii) que o token vem do `gh auth token` e o placeholder
      `REPLACE_WITH_YOUR_TOKEN` é substituído na activation; (iv) que o `mcpServers` do Continue
      é LISTA e não usa `disabled`.
      Files: `home/continue-mcp.nix`
      Verify: `nix-instantiate --parse home/continue-mcp.nix` retorna sem erro de sintaxe
      (parse puro, não precisa estar no git).

- [ ] 2. Rastrear o arquivo novo no git ANTES de qualquer eval/build.
      Convenção crítica do repo (flake): arquivos não rastreados são invisíveis para
      `nix eval`/`nix build`. Rodar `git add home/continue-mcp.nix` (staging basta, sem commit).
      Files: (nenhum arquivo alterado; apenas git index)
      Verify: `git status --short home/continue-mcp.nix` mostra o arquivo como `A` (added/staged).

- [ ] 3. Adicionar `./continue-mcp.nix` ao bloco `imports` de `home/default.nix`.
      Inserir a linha `./continue-mcp.nix` dentro da lista `imports = [ ... ]` (linhas ~20-30),
      próximo de `./kiro-mcp.nix` para manter os dois módulos de MCP juntos.
      Files: `home/default.nix`
      Verify: incluído implicitamente na avaliação do item 4 (o atributo de activation só existe
      se o import estiver presente).

- [ ] 4. Validar que o atributo de activation avalia e produz YAML/JSON válido.
      Rodar o eval do script de activation do home-manager para o host nobita:
      `nix eval --raw '.#nixosConfigurations.nobita.config.home-manager.users.terabytes.home.activation.continueMcp.data'`
      Isso imprime o corpo do script (echo '<json>' > ...; sed ...). Extrair o JSON do `echo`
      e validá-lo com um parser YAML, ex.:
      `nix eval --raw '.#nixosConfigurations.nobita.config.home-manager.users.terabytes.home.activation.continueMcp.data' | python3 -c "import sys,re,yaml; t=sys.stdin.read(); m=re.search(r\"echo '(.*)' > \", t, re.S); d=yaml.safe_load(m.group(1)); assert d['name']=='Main Config'; names=[s['name'] for s in d['mcpServers']]; assert 'hypruse' not in names; assert set(['fetch','nixos','duckduckgo','qt-docs','taskwarrior','github','terraform','aws-mcp']).issubset(set(names)); assert any(s['name']=='github' and s['env']['GITHUB_PERSONAL_ACCESS_TOKEN']=='REPLACE_WITH_YOUR_TOKEN' for s in d['mcpServers']); print('OK', names)"`
      Esperado: imprime `OK` e a lista de nomes, SEM `hypruse`, COM os 8 servers esperados, e o
      placeholder `REPLACE_WITH_YOUR_TOKEN` presente no `env` do github no template.
      (Se o parse do JSON de dentro do `echo` ficar frágil por causa de escaping, alternativa:
      `nix eval --raw '...home.file.".continue/config.yaml"...'` NÃO se aplica aqui porque usamos
      activation e não `home.file`; então validar o template via o atributo `.data` como acima.)
      Files: (nenhum)
      Verify: comando acima termina com exit 0 e imprime `OK`.

- [ ] 5. Verificação de build do home-manager (dry-run, sem aplicar).
      Confirmar que a configuração inteira ainda avalia/constrói com o novo módulo:
      `nix build '.#nixosConfigurations.nobita.config.system.build.toplevel' --dry-run`
      (ou `sudo nixos-rebuild dry-build --flake .#nobita`). Isso garante que o módulo não quebra
      a avaliação do sistema. Opcionalmente rodar o check de home-manager existente:
      `nix build .#checks.x86_64-linux.home-manager` (ver README, seção Testes).
      Files: (nenhum)
      Verify: o dry-build termina sem erro de avaliação. (Aplicação real do `switch` e a
      substituição efetiva do token pelo `gh` ocorrem no `home-manager switch`/`nixos-rebuild
      switch`, fora desta etapa de verificação — anotar que a troca do placeholder só acontece em
      tempo de activation, quando `gh auth token` roda na máquina do usuário.)

---

## Notas e suposições

- **Token em runtime, não em eval:** assim como no kiro-mcp.nix, o `REPLACE_WITH_YOUR_TOKEN`
  permanece no template avaliado pelo Nix; a substituição real só ocorre durante a activation
  (`home-manager switch`), quando `gh auth token` executa. Portanto a verificação por `nix eval`
  (item 4) deve encontrar o PLACEHOLDER, não o token — isso é o esperado e correto. Não há
  segredo embutido na /nix/store.
- **Host doraemon:** os comandos de verificação usam `nobita`; como o módulo entra via
  `home/default.nix` (compartilhado), vale para ambos os hosts. Pode-se repetir o item 4 trocando
  `nobita` por `doraemon` se desejar confirmar os dois.
- **Caminho do taskwarrior:** usar `${pkgs.mcp-server-taskwarrior}/bin/mcp-server-taskwarrior`
  (caminho absoluto da store, idêntico ao kiro-mcp.nix) — o overlay já fornece esse pacote.
- **`python3` + `yaml`:** `python3` está em `home.packages`. Se `PyYAML` não estiver disponível
  no `python3` padrão, usar `nix shell nixpkgs#python3Packages.pyyaml -c python3 ...` para o
  item 4. Como JSON é YAML válido, `python3 -c "import json,...; json.loads(...)"` também serve
  como fallback de validação de sintaxe do conteúdo.
```
