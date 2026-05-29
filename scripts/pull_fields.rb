# frozen_string_literal: true

require "net/http"
require "json"
require "fileutils"

JSON_START_PATERN = %r{<script id="__NEXT_DATA__" type="application/json">(.*)</script>}

URLS = {
  "dce" => "https://campos.focusnfe.com.br/dce/DeclaracaoConteudoXML.html",
  "nfe" => "https://campos.focusnfe.com.br/nfe/NotaFiscalXML.html",
  "nfgas" => "https://campos.focusnfe.com.br/nfgas/NotaFiscalGasXML.html",
  "nfe_item" => "https://campos.focusnfe.com.br/nfe/ItemNotaFiscalXML.html",
  "nfe_forma_pagamento" => "https://campos.focusnfe.com.br/nfe/FormaPagamentoXML.html",
  "nfse_nacional" => "https://campos.focusnfe.com.br/nfse_nacional/EmissaoDPSXml.html",
  "nfse_recebida" => "https://campos.focusnfe.com.br/nfser/NfseRecebida.html",
  "cte" => "https://campos.focusnfe.com.br/cte_cteos/ConhecimentoTransporteXML.html",
  "cte_transporte_rodoviario" => "https://campos.focusnfe.com.br/cte_cteos/TransporteRodoviarioXML.html",
  "cte_os" => "https://campos.focusnfe.com.br/cte_cteos/ConhecimentoTransporteOsXML.html",
  "cte_os_transporte_rodoviario" => "https://campos.focusnfe.com.br/cte_cteos/TransporteRodoviarioOsXML.html",
  "cte_transporte_aereo" => "https://campos.focusnfe.com.br/cte_cteos/TransporteAereoXML.html",
  "cte_transporte_aquaviario" => "https://campos.focusnfe.com.br/cte_cteos/TransporteAquaviarioXML.html",
  "cte_transporte_ferroviario" => "https://campos.focusnfe.com.br/cte_cteos/TransporteFerroviarioXML.html",
  "cte_transporte_dutoviario" => "https://campos.focusnfe.com.br/cte_cteos/TransporteDutoviarioXML.html",
  "cte_transporte_multimodal" => "https://campos.focusnfe.com.br/cte_cteos/TransporteMultimodalXML.html",
  "mdfe" => "https://campos.focusnfe.com.br/mdfe/MDFeXML.html",
  "mdfe_transporte_rodoviario" => "https://campos.focusnfe.com.br/mdfe/TransporteRodoviarioXML.html",
  "mdfe_transporte_aereo" => "https://campos.focusnfe.com.br/mdfe/TransporteAereoXML.html",
  "mdfe_transporte_aquaviario" => "https://campos.focusnfe.com.br/mdfe/TransporteAquaviarioXML.html",
  "mdfe_transporte_ferroviario" => "https://campos.focusnfe.com.br/mdfe/TransporteFerroviarioXML.html",
  "nfcom" => "https://campos.focusnfe.com.br/nfcom/NotaFiscalComunicacaoXML.html"
}.freeze

def load_schema(url)
  uri = URI(url)
  response = Net::HTTP.get(uri)
  json_data = response.match(JSON_START_PATERN)[1]
  data = JSON.parse(json_data)

  data.dig("props", "pageProps", "json", "object_attributes") || []
rescue StandardError => e
  puts "Error trying to load fields from #{url}: #{e.message}"
  []
end

FileUtils.mkdir_p("./tmp/shemas")

URLS.each do |name, url|
  puts "Loading fields from #{name} API..."
  schema = load_schema(url)

  file_name = "./tmp/shemas/schema_#{name}.json"
  FileUtils.rm(file_name) if File.exist?(file_name)
  File.write(file_name, JSON.pretty_generate(schema))

  puts "Fields from #{name} API saved to #{file_name}"
end
