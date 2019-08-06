# frozen_string_literal: true

module Neo4j
  module Driver
    module Ext
      module GraphDatabase
        extend AutoClosable
        include ExceptionCheckable

        auto_closable :driver

        def driver(uri, auth_token = Neo4j::Driver::AuthTokens.none, config = {})
          check do
            java_method(:driver, [java.lang.String, org.neo4j.driver.v1.AuthToken, org.neo4j.driver.v1.Config])
              .call(uri, auth_token, to_java_config(config))
          end
        end

        private

        def to_java_config(hash)
          hash.reduce(Neo4j::Driver::Config.build) { |object, key_value| object.send(*config_method(*key_value)) }
              .to_config
        end

        def config_method(key, value)
          method = :"with_#{key}"
          unit = nil
          case key.to_s
          when 'encryption'
            unless value
              method = :without_encryption
              value = nil
            end
          when 'load_balancing_strategy'
            value = load_balancing_strategy(value)
          when /Time(out)?$/i
            unit = java.util.concurrent.TimeUnit::SECONDS
          end
          [method, value, unit].compact
        end

        def load_balancing_strategy(value)
          case value
          when :least_connected
            Config::LoadBalancingStrategy::LEAST_CONNECTED
          when :round_robin
            Config::LoadBalancingStrategy::ROUND_ROBIN
          else
            raise ArgumentError
          end
        end
      end
    end
  end
end
