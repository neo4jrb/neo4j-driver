# frozen_string_literal: true

module Neo4j
  module Driver
    module Internal
      module ErrorHandling
        def check_error(error_code, status = nil, error_text = nil)
          case error_code
            # Identifies a successful operation which is defined as 0
          when Bolt::Error::BOLT_SUCCESS # 0
            nil
            # Permission denied
          when Bolt::Error::BOLT_PERMISSION_DENIED # 7
            failure Exceptions::AuthenticationException.new(error_code, 'Permission denied')
            # Connection refused
          when Bolt::Error::BOLT_CONNECTION_REFUSED
            failure Exceptions::ServiceUnavailableException.new(error_code, 'unable to acquire connection')
          else
            error_ctx = status && Bolt::Status.get_error_context(status)
            failure Exceptions::Neo4jException.new(
              error_code,
              "#{error_text || 'Unknown Bolt failure'} (code: #{error_code.to_s(16)}, " \
           "text: #{Bolt::Error.get_string(error_code)}, context: #{error_ctx})"
            )
          end
        end

        def on_failure(_error); end

        def check_status(status)
          check_error(Bolt::Status.get_error(status), status)
        end

        def with_status
          status = Bolt::Status.create
          yield status
        ensure
          check_status(status)
        end

        private

        def failure(error)
          on_failure(error)
          raise error
        end
      end
    end
  end
end
