## [Unreleased]

- Eventos próprios do MDF-e via novo `Recursos::Concerns::Eventavel`: `Mdfe#encerrar`, `Mdfe#incluir_condutor` e `Mdfe#incluir_dfe`, devolvendo `Modelos::Documento`.
- **Breaking:** `NfesRecebidas#emitir_evento` e `NfesRecebidas#cancelar_evento` passam a devolver `Modelos::Documento` (antes `Hash` cru), reescritos sobre o `Concerns::Eventavel`.
- Suporte aos dois tokens da Focus NFe: `Configuration#token_empresa` (emissão/consulta de documentos) e `Configuration#token_conta` (consultas auxiliares e gestão de empresas). O `Client` mantém uma conexão por token e roteia cada recurso para a correta — `ceps`, `municipios`, `cfops`, `cnaes`, `ncms`, `cnpjs` e `empresas` passam a usar o `token_conta`. **Breaking:** o antigo `token` foi renomeado para `token_empresa`.
- Documentação de uso (README) reescrita em português com exemplos reais.
- Metadata da gemspec preenchida (summary, description, homepage, source_code_uri, changelog_uri) para release público no RubyGems.org.
- CI alinhada ao `required_ruby_version`: matriz Ruby 3.2, 3.3, 3.4 e 4.0 (4.0 não-bloqueante).

## [0.1.0] - 2026-05-29

- Initial release
