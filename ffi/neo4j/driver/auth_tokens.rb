# frozen_string_literal: true

module Neo4j
  module Driver
    class AuthTokens
      class << self
        def basic(username, password)
          Bolt::Auth.basic(username, password, nil)
        end

        def none
          Bolt::Auth.none
        end
      end
    end
  end
end
