# frozen_string_literal: true

class DriverHelper
  module Helper
    def driver
      DriverHelper.driver
    end

    def uri
      DriverHelper.uri
    end
  end

  class << self
    def uri
      ENV.fetch('NEO4J_BOLT_URL', 'bolt://127.0.0.1:7998')
    end

    def driver
      @driver ||= Neo4j::Driver::GraphDatabase.driver(uri, Neo4j::Driver::AuthTokens.basic('neo4j', 'password'))
      # @driver ||= Neo4j::Driver::GraphDatabase.driver(uri, Neo4j::Driver::AuthTokens.none)
    end
  end
end
