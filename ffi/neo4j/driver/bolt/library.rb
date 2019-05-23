# frozen_string_literal: true

module Bolt
  module Library
    include FFI::Library
    include Bolt::AutoReleasable

    def self.extended(mod)
      mod.ffi_lib ENV['SEABOLT_LIB']
    end
  end
end
