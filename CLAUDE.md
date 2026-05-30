# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Unofficial Ruby gem providing a client for the [Focus NFe](https://focusnfe.com.br) API — a Brazilian
service for issuing electronic fiscal documents (NFe, NFCe, NFSe, CTe, MDFe, NFCom, DCe, etc.).

The project is at its very start: `lib/focus_nfe.rb` currently holds only the `FocusNfe` module and an
`Error` class. Most of the gem still has to be built. The substantive code that exists today is the
**field-scraping tooling** described below.

## Coding conventions

Code identifiers in this project follow the Focus NFe API's language — **Portuguese** — to keep a
single, consistent vocabulary between the gem and the API it wraps. Classes, modules, methods,
attributes, variables, and constants are named in Portuguese (e.g. `Nfe`, `emitir`, `consultar`,
`cancelar`, `justificativa`).
Follow established Ruby and gem best practices throughout (file/dir naming, `frozen_string_literal`,
double-quoted strings, Ruby 3.2 target — see `.rubocop.yml`).

### Comments

- **No unnecessary comments.** Code must be self-explanatory through clear names; do not narrate what the
  code already says, restate logic, or leave section/banner comments. If a comment only paraphrases the
  next line, delete it and improve the name instead.
- **The only allowed comments are YARD documentation** on public classes, modules, and methods — including
  type tags (`@param name [Type]`, `@return [Type]`, `@raise [Type]`). Prose may be written in Portuguese.
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

- `bin/setup` — install dependencies.
- `bin/console` — IRB session with the gem loaded.
- `bin/rspec` — run the RSpec suite directly (binstub; faster than `bundle exec rspec`). Pass paths/options
  through, e.g. `bin/rspec spec/focus_nfe_spec.rb`.
- `bin/rubocop` — run RuboCop directly (binstub). `bin/rubocop -a` auto-corrects style. Ruby target is 3.2;
  strings are double-quoted, and `rubocop-performance` + `rubocop-rspec` are loaded as plugins (`.rubocop.yml`).
- `bundle exec rake` — default task; runs **RSpec + RuboCop** (TDD is mandatory — see above). Keep it green
  before any commit.
- `bundle exec rake pull_fields` — scrape all document-type field schemas into `tmp/shemas/` (see below).
- `bundle exec rake install` / `rake release` — build/publish the gem (gemspec still has TODO metadata to fill in).

Note: CI (`.github/workflows/main.yml`) pins Ruby `4.0.2`, while `focus_nfe.gemspec` requires `>= 3.2.0`.

## Field schemas (the source of truth for API fields)

Focus NFe documents every request field on `campos.focusnfe.com.br`. The gem's request/field layer should be
derived from these definitions rather than hand-transcribed.

- `scripts/pull_fields.rb` — fetches each documented page, extracts the embedded `__NEXT_DATA__` JSON
  (`props.pageProps.json.object_attributes`), and writes one file per document type to
  `tmp/shemas/schema_<name>.json`. The full URL map for every document type lives at the top of this script.
- Each schema entry is `{ name, description, type, required, tag }`, where `name` is the JSON field the API
  expects, `tag` is the underlying XML tag, and `type` encodes Brazilian fiscal type/length (e.g. `String[1-60]`,
  `Integer[1-9]`).

`tmp/` is gitignored — the schemas are regenerated, not committed.
