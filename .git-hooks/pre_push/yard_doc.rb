# frozen_string_literal: true

module Overcommit
  module Hook
    module PrePush
      # Garante que a documentação YARD é gerada sem warnings
      # (`--fail-on-warning`), espelhando o job `docs` do CI.
      class YardDoc < Base
        def run
          result = execute(%w[bundle exec yard doc --no-output --fail-on-warning])
          return :pass if result.success?

          [:fail, result.stdout + result.stderr]
        end
      end
    end
  end
end
