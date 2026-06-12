# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Unofficial Ruby gem providing a client for the [Focus NFe](https://focusnfe.com.br) API — a Brazilian
service for issuing electronic fiscal documents (NFe, NFCe, NFSe, CTe, MDFe, NFCom, DCe, etc.).

The project is at its very start: `lib/focus_nfe.rb` currently holds only the `FocusNfe` module and an
`Error` class. Most of the gem still has to be built. The substantive code that exists today is the
**field-scraping tooling** described below.

## Coding conventions

### Language of identifiers (hybrid — English plumbing, Portuguese domain)

This gem uses a **two-language naming rule**. The dividing line is one question:

> **Does this identifier appear in, or directly name, something in the Focus NFe / SEFAZ fiscal domain?**
> If yes → **Portuguese**. If it is the gem's own machinery → **English**.

- **English — the gem's own plumbing** (everything that does *not* exist in the Focus NFe API):
  - Classes/modules: `Client`, `Configuration`, `Connection`, `Response`, `Adapter`,
    `Adapters::NetHttp`, `Authentication`, `Error`, `Errors::*` (`HttpError`, `BadRequest`,
    `Unauthorized`, `ValidationError`, `ServerError`, `ConfigurationError`, `ConnectionError`, …).
  - Structural methods: `configure`, `configuration`, `client`, `connection`, `call`,
    `get`/`post`/`put`/`delete`, `validate!`, `success?`, `from_response`, `class_for`.
  - Generic infrastructure config options & HTTP identifiers: `environment`, `timeout`,
    `open_timeout`, `logger`, `http_adapter`, `headers`, `path`, `params`, `body`, `status`, `url`.
  - All internal variables, private methods, and constants (`BASE_URLS`, `DEFAULT_HEADERS`, `VERBS`, …).
- **Portuguese — the Focus NFe / SEFAZ fiscal domain** (the API's own vocabulary):
  - Resource accessors and fiscal operations that map 1:1 to API actions: `nfe`, `nfce`, `nfse`,
    `cte`, `mdfe`, `emitir`, `consultar`, `cancelar`, `inutilizar`, `justificativa`, `referencia`.
  - **Payload field names: verbatim from the schemas — never translated** (`natureza_operacao`,
    `cnpj_emitente`, `valor_total`, …). These are generated from `campos.focusnfe.com.br`; translating
    them would be a bug. See *Field schemas* below.
- **Domain data *values* stay Portuguese even behind an English identifier.** The key is the gem's API
  (English), the value is fiscal data (Portuguese): e.g. `config.environment = :homologacao`
  (`:producao`/`:homologacao`), or fiscal status strings like `"autorizado"`/`"cancelado"`.

Rule of thumb for the two debated boundaries: the *attribute* `environment` is English (it's gem
machinery that resolves the base URL — `ambiente` is not an API field); `referencia` is Portuguese
(it's the API's `ref`).

Follow established Ruby and gem best practices throughout (file/dir naming, `frozen_string_literal`,
double-quoted strings, Ruby 3.2 target — see `.rubocop.yml`).

### Comments

- **No unnecessary comments.** Code must be self-explanatory through clear names; do not narrate what the
  code already says, restate logic, or leave section/banner comments. If a comment only paraphrases the
  next line, delete it and improve the name instead.
- **The only allowed comments are YARD documentation** on public classes, modules, and methods — including
  type tags (`@param name [Type]`, `@return [Type]`, `@raise [Type]`). **Comment/YARD prose is written in
  Portuguese**, regardless of the identifier language above (type references in tags use the real English
  identifier, e.g. `@return [FocusNfe::Configuration]`).
- Prefer expressing intent in code (well-named methods/constants) over explanatory prose. A genuinely
  non-obvious *why* (a workaround, an external constraint) belongs in the YARD doc of the relevant method,
  not as a loose inline comment.

## Test-Driven Development (mandatory)

This project is built with **TDD — it is a hard rule, not a preference**. For every behavior:

1. **Red** — write a failing spec that describes the desired behavior _before_ writing any
   implementation code.
2. **Green** — write the minimum implementation needed to make the spec pass.
3. **Refactor** — clean up while keeping the suite green.

Rules:

- **No production code without a failing spec that requires it.** New classes, methods, or branches
  arrive test-first.
- Tests use **RSpec** under `spec/`, mirroring `lib/` (`spec/focus_nfe/recursos/nfe_spec.rb`, …).
- HTTP is never hit for real in tests — stub it with **WebMock** (and VCR for recorded interactions
  if useful). Cover both `:homologacao` and `:producao` base URLs.
- Each bug fix starts with a failing spec that reproduces the bug.
- `bundle exec rake` must run **RSpec and RuboCop**, and stay green before any commit.

## Commands

- `bin/setup` — install dependencies. Após o `bundle install`, instale os git hooks com
  `bundle exec overcommit --install` (veja *Git hooks / commits* abaixo).
- `bin/console` — IRB session with the gem loaded.
- `bin/rspec` — run the RSpec suite directly (binstub; faster than `bundle exec rspec`). Pass paths/options
  through, e.g. `bin/rspec spec/focus_nfe_spec.rb`.
- `bin/rubocop` — run RuboCop directly (binstub). `bin/rubocop -a` auto-corrects style. Ruby target is 3.2;
  strings are double-quoted, and `rubocop-performance` + `rubocop-rspec` are loaded as plugins (`.rubocop.yml`).
- `bundle exec rake` — default task; runs **RSpec + RuboCop** (TDD is mandatory — see above). Keep it green
  before any commit.
- `bundle exec rake pull_fields` — scrape all document-type field schemas into `data/schemas/` (see below).
- `bundle exec rake coverage:open` — open the SimpleCov HTML report (`coverage/index.html`) in the browser;
  generate it first with `bin/rspec` / `rake spec`. SimpleCov is configured at the top of `spec/spec_helper.rb`
  (line + branch coverage); the `coverage/` directory is git-ignored.
- `bundle exec rake install` / `rake release` — build/publish the gem (gemspec still has TODO metadata to fill in).

Note: CI (`.github/workflows/main.yml`) pins Ruby `4.0.2`, while `focus_nfe.gemspec` requires `>= 3.2.0`.

## Git hooks / commits (overcommit + Conventional Commits)

Os git hooks são gerenciados pelo [overcommit](https://github.com/sds/overcommit) (`.overcommit.yml`).
Após clonar e instalar as dependências, ative-os uma vez com `bundle exec overcommit --install`.

- **pre-commit** — roda `bundle exec rubocop` nos arquivos alterados, além de checagens de espaços em
  branco, tabs, conflitos de merge e sintaxe YAML.
- **pre-push** — roda a suíte completa (`bundle exec rspec`).
- **commit-msg** — exige que a mensagem siga o padrão
  [Conventional Commits](https://www.conventionalcommits.org): `<tipo>(escopo opcional)!: <descrição>`.
  Tipos aceitos: `build`, `chore`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`, `revert`, `style`,
  `test`. Exemplo: `feat(nfe): adiciona emissão de NFe`. Mensagens de `Merge`/`Revert`/`fixup!`/`squash!`
  são liberadas. O assunto vai até 72 colunas e não pode terminar em ponto.

Ao alterar o `.overcommit.yml`, o overcommit pede para reassinar a configuração: `bundle exec overcommit --sign`.

## Field schemas (the source of truth for API fields)

Focus NFe documents every request field on `campos.focusnfe.com.br`. The gem's request/field layer should be
derived from these definitions rather than hand-transcribed.

- `scripts/pull_fields.rb` — fetches each documented page, extracts the embedded `__NEXT_DATA__` JSON
  (`props.pageProps.json.object_attributes`), and writes one file per document type to
  `data/schemas/schema_<name>.json`. The full URL map for every document type lives at the top of this script.
- Each schema entry is `{ name, description, type, required, tag }` and may also carry `enum`,
  `reforma_tributaria` and a nested `collection` (with `collection_type`). `name` is the JSON field the API
  expects, `tag` is the underlying XML tag, and `type` encodes Brazilian fiscal type/length (e.g. `String[1-60]`,
  `Integer[1-9]`, `Decimal[13.2]`, `Coleção[0-500]`).

`data/schemas/` is git-tracked and packaged with the gem (via `git ls-files` in the gemspec), powering the
opt-in client-side validation (`FocusNfe::Esquemas::*`, `emitir(..., validar: true)`). Regenerate it with
`rake pull_fields`.

**Never edit the `data/schemas/*.json` files by hand** — they are generated by `rake pull_fields` from
`campos.focusnfe.com.br`. To change a schema, update the source (or `scripts/pull_fields.rb`), rerun the task,
and commit the regenerated output. CI runs the `schemas` job on every PR (`.github/workflows/main.yml`), which
regenerates the schemas and fails if they differ from what is committed.
