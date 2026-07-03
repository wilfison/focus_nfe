# Changelog

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/)
e versionamento em [SemVer](https://semver.org/lang/pt-BR/).

## [Unreleased]

## [1.0.1] - 2026-07-03

### Documentação

- Adiciona badges no `README` (versão da gem, CI, versão do Ruby e licença).

## [1.0.0] - 2026-07-03

Primeira versão pública. Cliente Ruby não-oficial para a API da
[Focus NFe](https://focusnfe.com.br), sem dependências de runtime (apenas a
stdlib).

### Cliente e configuração

- `FocusNfe::Client` com dois modos que coexistem: configuração global
  (`FocusNfe.configure`) para aplicações de uma empresa só, e instâncias
  independentes para cenários multi-empresa.
- Dois tokens da Focus NFe separados: `Configuration#token_empresa`
  (emissão/consulta de documentos e gestão por empresa) e
  `Configuration#token_conta` (consultas auxiliares e gestão de empresas). O
  cliente mantém uma conexão por token e roteia cada recurso para a correta;
  acessar um recurso sem o token exigido levanta `ConfigurationError` antes de
  qualquer ida à rede.
- Ambientes `:homologacao` e `:producao`, resolvidos para a URL base correta.
- `timeout`, `logger` e adaptador HTTP configuráveis; adaptador padrão sobre
  `net/http`, sem gems externas.
- Erros tipados por status HTTP (`FocusNfe::Errors::*`) a partir de
  `FocusNfe::Error`, com o corpo da resposta preservado.

### Documentos emitidos

- Recursos `nfe`, `nfce`, `nfse`, `nfse_nacional`, `cte`, `cte_os`, `mdfe`,
  `nfcom`, `dce` e `nfgas`.
- Operações fiscais conforme cada documento: `emitir`, `consultar`, `cancelar`,
  `inutilizar`, carta de correção e demais eventos, além de download dos XMLs
  e do DANFE/DACTE quando disponível.
- Eventos próprios do MDF-e: `Mdfe#encerrar`, `Mdfe#incluir_condutor` e
  `Mdfe#incluir_dfe`, devolvendo `Modelos::Documento`.
- Respostas devolvidas como `Modelos::Documento` (e `Modelos::Inutilizacao`
  para inutilizações).

### Documentos recebidos

- Recursos `nfes_recebidas`, `ctes_recebidas` e `nfses_nacionais_recebidas`.
- Listagem com sincronização incremental paginada (`Modelos::Pagina`),
  consulta, manifestação do destinatário, eventos e download dos XMLs
  (documento e eventos).

### APIs auxiliares (token da conta)

- Consultas somente leitura `ceps`, `municipios`, `cfops`, `cnaes`, `ncms` e
  `cnpjs`.

### APIs de gestão

- `empresas` (token da conta) para cadastro e manutenção de empresas.
- `webhooks`, `emails_bloqueados` e `backups` (token da empresa).

### Webhooks inbound

- `FocusNfe::Webhook.parse(raw_body)` devolve um `Modelos::Documento`.
- `FocusNfe::Webhook.autenticado?(headers:, authorization:, authorization_header:)`
  valida a chamada comparando o header recebido com o `authorization` do
  gatilho em tempo constante. Inclui `Modelos::Documento.from_payload` e o erro
  `Errors::WebhookError`.

### Validação client-side (opt-in)

- Esquemas de campos (`FocusNfe::Esquemas::*`) derivados de
  `campos.focusnfe.com.br` e empacotados em `data/schemas/`, com validação
  opcional na emissão (`emitir(..., validar: true)`).

### Qualidade

- Assinaturas de tipo RBS (`sig/`) verificadas por Steep e documentação YARD em
  português nas APIs públicas.
