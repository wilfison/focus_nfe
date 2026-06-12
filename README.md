# FocusNfe

Cliente Ruby **não-oficial** para a API da [Focus NFe](https://focusnfe.com.br) —
serviço brasileiro de emissão de documentos fiscais eletrônicos (NFe, NFCe, NFSe,
CTe, MDFe, NFCom, DCe e outros).

> ⚠️ **Não-oficial.** Esta gem não tem vínculo com a Focus NFe. A autoridade
> final sobre campos, regras e validações fiscais é sempre a API da Focus/SEFAZ.

A gem é uma camada fina sobre HTTP: transporta JSON, autentica, trata os status
HTTP em **erros tipados** e devolve objetos Ruby úteis. Não reimplementa regras
fiscais. Não tem dependências de runtime (usa apenas a stdlib).

Cobre:

- **Documentos emitidos** — `nfe`, `nfce`, `nfse`, `nfse_nacional`, `cte`,
  `cte_os`, `mdfe`, `nfcom`, `dce`, `nfgas`.
- **Documentos recebidos** — `nfes_recebidas`, `ctes_recebidas`,
  `nfses_nacionais_recebidas` (listagem com sincronização incremental,
  consulta, downloads, manifestação e eventos).
- **APIs auxiliares** (somente leitura, autenticadas pelo **token da conta**) —
  `ceps`, `municipios`, `cfops`, `cnaes`, `ncms`, `cnpjs`.
- **APIs de gestão** — `empresas` (token da conta); `webhooks`,
  `emails_bloqueados`, `backups` (token da empresa).

## Instalação

Adicione a gem ao `Gemfile` da aplicação:

```bash
bundle add focus_nfe
```

Ou instale diretamente:

```bash
gem install focus_nfe
```

## Configuração

### Os dois tokens da Focus NFe

A API usa **dois tokens distintos**, e a gem os separa:

- **`token_empresa`** — identifica a empresa que emite/consulta o documento.
  Autentica todos os documentos (`nfe`, `nfce`, …, e as recebidas) e as APIs
  de gestão por empresa (`webhooks`, `emails_bloqueados`, `backups`).
- **`token_conta`** — token da conta. Autentica as consultas auxiliares (`ceps`,
  `municipios`, `cfops`, `cnaes`, `ncms`, `cnpjs`) e a gestão de empresas
  (`empresas`).

Configure só o que for usar: um cliente só com `token_empresa` emite documentos;
acessar um recurso de conta sem `token_conta` levanta `ConfigurationError` (e
vice-versa), antes de qualquer ida à rede.

Há dois modos de uso, que coexistem.

### Global — para aplicações de uma empresa só

```ruby
FocusNfe.configure do |config|
  config.token_empresa = ENV["FOCUS_NFE_TOKEN_EMPRESA"]
  config.token_conta   = ENV["FOCUS_NFE_TOKEN_CONTA"]   # opcional (consultas auxiliares/empresas)
  config.environment   = :producao       # ou :homologacao (padrão)
  config.timeout       = 30
  config.logger        = Rails.logger
end

client = FocusNfe.client                 # usa a config global
```

### Explícito — várias empresas no mesmo processo

O `token_empresa` é por empresa; cada `Client` carrega seus próprios tokens e
ambiente, sem estado compartilhado. O `token_conta`, quando usado, é o mesmo da
conta que agrupa as empresas.

```ruby
loja   = FocusNfe::Client.new(token_empresa: "TOKEN_LOJA",   environment: :producao)
filial = FocusNfe::Client.new(token_empresa: "TOKEN_FILIAL", environment: :homologacao)

# Consultas auxiliares e gestão de empresas usam o token da conta:
conta  = FocusNfe::Client.new(token_conta: "TOKEN_CONTA", environment: :producao)
conta.cnpjs.consultar("12345678000123")
conta.empresas.criar(dados: dados_empresa, dry_run: true)
```

O ambiente resolve a URL base (o prefixo `/v2` é interno):

- `:producao` → `https://api.focusnfe.com.br`
- `:homologacao` → `https://homologacao.focusnfe.com.br`

## Uso

### Emissão e ciclo assíncrono

A emissão é assíncrona na maioria dos documentos. A `ref` é a referência única do
documento na sua aplicação (validada client-side como alfanumérica antes do
envio). As respostas de emissão e consulta são encapsuladas em
`FocusNfe::Modelos::Documento`.

```ruby
doc = client.nfe.emitir(ref: "pedido-42", dados: payload_nfe)
doc.status           # => "processando_autorizacao"
doc.processando?     # => true
doc.ref              # => "pedido-42"

# Acompanhamento por polling (ou via webhooks — ver Gestão).
doc = client.nfe.consultar("pedido-42")
if doc.autorizado?
  doc.chave_nfe
  doc.caminho_xml_nota_fiscal
  doc.caminho_danfe
elsif doc.erro?
  doc.status_sefaz
  doc.mensagem_sefaz
end
```

Predicados de status disponíveis: `autorizado?`, `cancelado?`, `processando?`,
`erro?`, `denegado?`. Campos não mapeados continuam acessíveis via `doc["campo"]`
ou `doc.dados`.

A NFC-e é **síncrona** — o resultado já vem na própria chamada de emissão:

```ruby
nota = client.nfce.emitir(ref: "venda-1001", dados: payload_nfce)
nota.autorizado?   # => true/false na mesma chamada
```

### Cancelamento

```ruby
client.nfe.cancelar("pedido-42", justificativa: "Cliente desistiu da compra.")
```

### Documentos recebidos e sincronização incremental

`listar` devolve uma `FocusNfe::Modelos::Pagina` (enumerável). O cabeçalho
`X-Max-Version` é exposto em `versao_maxima`, para retomar a sincronização do
ponto onde parou.

```ruby
pagina = client.nfes_recebidas.listar(cnpj: "12345678000123", versao: ultima_versao)
pagina.cada { |nfe| processar(nfe) }
proxima_versao = pagina.versao_maxima

# Consulta, downloads e manifestação do destinatário:
client.nfes_recebidas.consultar(chave, completa: true)
xml = client.nfes_recebidas.baixar_xml(chave)
pdf = client.nfes_recebidas.baixar_pdf(chave)
client.nfes_recebidas.manifestar(chave, tipo: "confirmacao")
```

### APIs auxiliares

Autenticadas pelo `token_conta` (ver [Configuração](#configuração)):

```ruby
client.ceps.consultar("69909032")
client.cnpjs.consultar("12345678000123")
client.ncms.consultar("01012100")
```

### APIs de gestão

```ruby
# Cadastro de empresa (apenas produção); dry_run valida sem persistir.
client.empresas.criar(dados: dados_empresa, dry_run: true)

# Webhooks (a gem ajuda a registrar; a entrega é externa à gem).
client.webhooks.criar(dados: { event: "nfe", url: "https://meu.app/hooks/nfe", cnpj: "12345678000123" })
```

## Erros tipados

Cada faixa de status HTTP vira uma exceção específica, todas descendentes de
`FocusNfe::Error`. Cada exceção carrega `status`, `body` (mensagens da API) e a
`response` original.

| Status | Exceção                             | Significado                            |
| ------ | ----------------------------------- | -------------------------------------- |
| 400    | `FocusNfe::Errors::BadRequest`      | Requisição malformada                  |
| 401    | `FocusNfe::Errors::Unauthorized`    | Token ausente ou inválido              |
| 403    | `FocusNfe::Errors::Forbidden`       | Sem permissão                          |
| 404    | `FocusNfe::Errors::NotFound`        | Recurso inexistente                    |
| 409    | `FocusNfe::Errors::Conflict`        | Conflito de estado (ex.: `ref` em uso) |
| 422    | `FocusNfe::Errors::ValidationError` | Erro de validação dos campos           |
| 429    | `FocusNfe::Errors::RateLimited`     | Limite de requisições excedido         |
| 5xx    | `FocusNfe::Errors::ServerError`     | Falha no servidor da Focus/SEFAZ       |

```ruby
begin
  client.nfe.emitir(ref: "pedido-42", dados: payload)
rescue FocusNfe::Errors::ValidationError => e
  e.status   # => 422
  e.body     # => mensagens de erro da API
rescue FocusNfe::Error => e
  # captura qualquer falha da gem
end
```

Há ainda `ConfigurationError` (token/ambiente inválidos, client-side) e
`ConnectionError` (timeout, conexão recusada, excesso de redirects).

## Validação opt-in por schemas

Os campos de emissão derivam dos schemas documentados em
`campos.focusnfe.com.br` (empacotados em `data/schemas/`). A validação
client-side é **opcional e desligada por padrão** — a Focus é a autoridade final
e os campos mudam (ex.: Reforma Tributária em transição).

```ruby
client.nfe.emitir(ref: "pedido-42", dados: payload, validar: true)
# => levanta FocusNfe::Esquemas::ErroDeValidacao se faltar obrigatório
#    ou o tipo/tamanho de um campo escalar não bater.
```

A validação é **recursiva**: campos de coleção (`Coleção[...]`, como `itens`) têm
cada item validado contra o schema da coleção, em qualquer profundidade. Os erros
vêm com o caminho até o campo — a posição do item é base 1:

```ruby
payload = {
  natureza_operacao: "Venda",
  itens: [
    { numero_item: 1, descricao: "Produto A" },
    { numero_item: 2 } # falta a descrição obrigatória
  ]
}

begin
  client.nfe.emitir(ref: "pedido-42", dados: payload, validar: true)
rescue FocusNfe::Esquemas::ErroDeValidacao => e
  e.erros # => ["itens[2].descricao: campo obrigatório ausente", ...]
end
```

Documentos sem schema próprio são emitidos sem validar (pulam silenciosamente).

### Introspecção dos schemas

Os mesmos schemas empacotados ficam acessíveis como dado, para você (ou uma
ferramenta automatizada) descobrir quais campos e tipos um documento aceita — sem
token nem conexão:

```ruby
FocusNfe::Esquemas.disponiveis
# => ["cte", "cte_os", "dce", "mdfe", "nfcom", "nfe", "nfe_item", "nfgas", ...]

FocusNfe::Esquemas.descrever("nfe")
# => [
#   { nome: "natureza_operacao", descricao: "Descrição da natureza de operação.",
#     tipo: :string, tipo_bruto: "String[1-60]", obrigatorio: true,
#     tamanho_minimo: 1, tamanho_maximo: 60, enum: nil, tag: "natOp", colecao: nil },
#   ...
# ]
# => nil para documento sem schema
```

Cada campo vira um `Hash` serializável. Campos de coleção (`Coleção[...]`) aninham
a descrição dos subcampos em `:colecao`, em qualquer profundidade; enums trazem os
valores aceitos em `:enum`. `disponiveis` também lista os sub-schemas auxiliares
(`nfe_item`, `cte_transporte_aereo`, …), que igualmente podem ser descritos.

## Desenvolvimento

Após clonar o repositório, rode `bin/setup` para instalar as dependências.
`bin/console` abre um IRB com a gem carregada.

O projeto é desenvolvido **test-first (TDD)** com RSpec + WebMock — nenhuma
classe/método/branch nasce sem um spec falhando que o exija. O `rake` default
roda **RSpec + RuboCop** e precisa estar verde antes de cada commit:

```bash
bundle exec rake          # RSpec + RuboCop
bin/rspec                 # apenas a suíte
bin/rubocop -a            # estilo, com auto-correção
bundle exec rake pull_fields   # regenera data/schemas/ a partir de campos.focusnfe.com.br
```

Os arquivos em `data/schemas/` são **gerados automaticamente** por
`rake pull_fields` — não os edite à mão. Para atualizá-los, rode o script e
faça commit do resultado. O CI verifica em cada PR se os schemas estão em dia.

Para instalar a gem localmente, rode `bundle exec rake install`. Para publicar
uma nova versão, atualize o número em `version.rb` e rode `bundle exec rake
release`, que cria a tag git, sobe os commits + tag e publica o `.gem` no
[rubygems.org](https://rubygems.org).

## Contribuindo

Bug reports e pull requests são bem-vindos no GitHub em
https://github.com/wilfison/focus_nfe. Espera-se que os participantes sigam o
[código de conduta](https://github.com/wilfison/focus_nfe/blob/main/CODE_OF_CONDUCT.md).

## Licença

Disponível como código aberto sob os termos da
[licença MIT](https://opensource.org/licenses/MIT).
