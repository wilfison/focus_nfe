# frozen_string_literal: true

module Overcommit
  module Hook
    module PrePush
      # Roda `steep check` para garantir que as assinaturas RBS em `sig/`
      # continuam consistentes com a implementação em `lib/`.
      class Steep < Base
        def run
          result = execute(%w[bundle exec steep check])
          return :pass if result.success?

          [:fail, result.stdout + result.stderr]
        end
      end
    end
  end
end
