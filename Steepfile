# frozen_string_literal: true

target :lib do
  signature "sig"
  check "lib"

  library "json"
  library "uri"
  library "net-http"
  library "timeout"
  library "date"

  configure_code_diagnostics(Steep::Diagnostic::Ruby.default) do |hash|
    hash[Steep::Diagnostic::Ruby::UnannotatedEmptyCollection] = nil
  end
end
