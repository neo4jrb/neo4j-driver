# frozen_string_literal: true

# Workaround for missing zeitwerk support in jruby-9.2.7.0
if RUBY_PLATFORM.match?(/java/)
  module Neo4j
    module Driver
      module Exceptions
      end
      module Internal
      end
    end
  end
end
# End workaround

require 'active_support/duration'
require 'active_support/time'
require 'neo4j/driver'
