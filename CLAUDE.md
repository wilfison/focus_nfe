# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this is

Unofficial Ruby gem: a client for the [Focus NFe](https://focusnfe.com.br) API (Brazilian electronic
fiscal documents — NFe, NFCe, NFSe, CTe, MDFe, NFCom, DCe, …). Early stage: most of the gem is still
to be built; the substantive existing code is the field-scraping tooling (*Field schemas* below).

## Coding conventions

### Identifier language (hybrid: English plumbing, Portuguese domain)

Dividing question: **does the identifier name something in the Focus NFe / SEFAZ fiscal domain?**
Yes → **Portuguese**. The gem's own machinery → **English**.

- **English (gem plumbing, not in the API):** classes/modules (`Client`, `Configuration`, `Connection`,
  `Response`, `Adapter`, `Authentication`, `Error`, `Errors::*`); structural methods (`configure`,
  `connection`, `call`, `get`/`post`/`put`/`delete`, `validate!`, `success?`, `from_response`,
  `class_for`); infra config & HTTP terms (`environment`, `timeout`, `logger`, `http_adapter`, `headers`,
  `path`, `params`, `body`, `status`, `url`); all internal vars, private methods, constants.
- **Portuguese (the API's own vocabulary):** resource accessors / fiscal operations mapping 1:1 to API
  actions (`nfe`, `nfce`, `nfse`, `cte`, `mdfe`, `emitir`, `consultar`, `cancelar`, `inutilizar`,
  `justificativa`, `referencia`); **payload field names verbatim from the schemas — never translated**
  (`natureza_operacao`, `cnpj_emitente`, `valor_total`, …).
- **Domain values stay Portuguese even behind an English key:** `config.environment = :homologacao`
  (`:producao`/`:homologacao`); fiscal statuses like `"autorizado"`/`"cancelado"`.
- Debated boundaries: `environment` is English (resolves the base URL; `ambiente` is not an API field);
  `referencia` is Portuguese (the API's `ref`).

General Ruby/gem best practices: `frozen_string_literal`, double-quoted strings, Ruby 3.2 target (`.rubocop.yml`).

### Comments

- **No unnecessary comments** — names carry intent; no narration, restatement, or banner/section comments.
- **Only YARD docs allowed**, on public classes/modules/methods, with type tags (`@param`, `@return`,
  `@raise`). **Prose in Portuguese**; type references use the real English identifier (`@return [FocusNfe::Configuration]`).
- A genuinely non-obvious *why* (workaround, external constraint) goes in the method's YARD doc, not inline.

## TDD (mandatory — hard rule)

Red → Green → Refactor for every behavior. **No production code without a failing spec first** (new
classes, methods, branches arrive test-first; each bug fix starts with a reproducing spec).

- **RSpec** under `spec/`, mirroring `lib/` (`spec/focus_nfe/recursos/nfe_spec.rb`, …).
- HTTP never hit for real — stub with **WebMock** (VCR for recorded interactions if useful). Cover both
  `:homologacao` and `:producao` base URLs.
- `bundle exec rake` (RSpec + RuboCop) must stay green before any commit.

## Commands

- `bin/setup` — install deps; then `bundle exec overcommit --install` (git hooks, see below).
- `bin/console` — IRB with the gem loaded.
- `bin/rspec` / `bin/rubocop` — binstubs (faster than `bundle exec`). `bin/rubocop -a` auto-corrects.
- `bundle exec rake` — default; runs **RSpec + RuboCop**. Keep green before committing.
- `bundle exec rake ci` — roda **localmente todas as verificações do CI** (`.github/workflows/ci.yml`):
  specs, RuboCop, Steep, YARD (`--fail-on-warning`), cobertura de docs e schemas atualizados. Continua
  mesmo se um passo falhar e imprime um resumo no fim — pegue o CI quebrado antes de enviar ao GitHub.
- `bundle exec rake steep` — **Steep** type-check (`sig/` vs `lib/`). Standalone, *not* in default rake;
  CI gates it in a `typecheck` job. See *Type signatures*.
- `bundle exec rake pull_fields` — regenerate field schemas into `data/schemas/`.
- `bundle exec rake coverage:open` — open SimpleCov HTML report (generate first via `bin/rspec`/`rake spec`;
  configured atop `spec/spec_helper.rb`, line+branch; `coverage/` git-ignored).
- `bundle exec rake install` / `release` — build/publish (gemspec metadata still has TODOs).

CI (`.github/workflows/ci.yml`) pins Ruby `4.0.2`; gemspec requires `>= 3.2.0`.

## Git hooks / commits (overcommit + Conventional Commits)

Managed by [overcommit](https://github.com/sds/overcommit) (`.overcommit.yml`); activate once with
`bundle exec overcommit --install`. After editing `.overcommit.yml`, re-sign: `bundle exec overcommit --sign`.

- **pre-commit** — `rubocop` on changed files + whitespace/tab/merge-conflict/YAML checks.
- **pre-push** — full `rspec` suite.
- **commit-msg** — [Conventional Commits](https://www.conventionalcommits.org): `<tipo>(escopo)!: <descrição>`.
  Types: `build`, `chore`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`, `revert`, `style`, `test`.
  Subject ≤ 72 cols, no trailing period (`Merge`/`Revert`/`fixup!`/`squash!` exempt).

## Field schemas (source of truth for API fields)

The request/field layer is derived from `campos.focusnfe.com.br`, not hand-transcribed.

- `tools/pull_fields.rb` fetches each page, extracts the embedded `__NEXT_DATA__` JSON
  (`props.pageProps.json.object_attributes`), and writes `data/schemas/schema_<name>.json` per document
  type (URL map at the top of the script).
- Each entry: `{ name, description, type, required, tag }`, optionally `enum`, `reforma_tributaria`, and a
  nested `collection` (with `collection_type`). `name` = JSON field the API expects; `tag` = XML tag;
  `type` encodes Brazilian fiscal type/length (`String[1-60]`, `Integer[1-9]`, `Decimal[13.2]`, `Coleção[0-500]`).
- `data/schemas/` is git-tracked and packaged (gemspec `git ls-files`); powers opt-in client-side validation
  (`FocusNfe::Esquemas::*`, `emitir(..., validar: true)`).

**Never edit `data/schemas/*.json` by hand** — generated by `rake pull_fields`. To change a schema, edit the
source / `tools/pull_fields.rb`, rerun, and commit the regenerated output. CI's `schemas` job regenerates on
every PR and fails on any diff.

## Type signatures (RBS + Steep)

Hand-written RBS under `sig/`, checked by Steep — `steep check` must stay green (CI `typecheck` job, Ruby 3.4;
local `bundle exec rake steep`, standalone to keep the 3.2–4.0 matrix fast). `Steepfile` has one `target :lib`
checking `lib` against `sig` with stdlib `json`, `uri`, `net-http`, `timeout` (no `rbs_collection` — zero
runtime deps). `sig/` is packaged with the gem; `Steepfile`/`rbs_collection.*` are excluded via the gemspec
reject-list.

- **`sig/` mirrors `lib/`, one file per `.rb`.** Keep in sync — a new class/method/branch arrives with its
  signature. **Hand-written, never generated** (`rbs prototype` loses overloads, self-types, `define_method`'d methods).
- **Typing boundary mirrors the naming rule:** gem plumbing is **precise** (`Response#status: Integer`,
  `raw_body: String?`, `Configuration`/`Connection`/`Adapter` shapes, `Campo`'s parsed type/size); the
  **fiscal payload/JSON domain is `untyped`** (`Response#body`, `Documento` fields & `#dados`, every
  `**dados`/`**opcoes`/`**filtros`, raw-body returns of auxiliary/recebidas/management resources). When unsure
  at a payload boundary, widen to `Hash[untyped, untyped]`/`untyped`.
- **Mixins use RBS self-types:** each `Recursos::Concerns::*` is `module X : FocusNfe::Recursos::Base` so Steep
  resolves the host's private `connection`/`caminho_*`/`esquemas_extras`.
- **No `# steep:ignore`** (the comment rule allows only YARD). When Steep can't follow the code (e.g.
  `define_method` doesn't rebind `self`), **restructure to explicit methods** instead of silencing — why
  `HTTP::Connection`'s verbs and `Modelos::Documento`'s readers are written out. For stdlib nil-narrowing,
  capture into a local and guard.
- `Ruby::UnannotatedEmptyCollection` (empty `{}`) is disabled in `Steepfile`.
