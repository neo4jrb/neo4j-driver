# frozen_string_literal: true

module Neo4j
  module Driver
    module Internal
      class NetworkSession
        include BookmarksHolder
        include ErrorHandling
        extend AutoClosable

        auto_closable :begin_transaction

        def initialize(connection_provider, mode, retry_logic = nil, logging = nil)
          super()
          @open = Concurrent::AtomicBoolean.new(true)
          @connection_provider = connection_provider
          @mode = mode
          # @retry_logic = retry_logic
          @retry_logic = Class.new do
            def retry
              yield
            end
          end.new
        end

        def run(statement, parameters = {}, config = nil)
          ensure_session_is_open
          ensure_no_open_tx_before_running_query
          acquire_connection(@mode)
          @result = @connection.protocol.run_in_auto_commit_transaction(
            @connection, Statement.new(statement, parameters), self, config
          )
        end

        def read_transaction(&block)
          transaction(Neo4j::Driver::AccessMode::READ, &block)
        end

        def write_transaction(&block)
          transaction(Neo4j::Driver::AccessMode::WRITE, &block)
        end

        def close
          return unless @open.make_false
          begin
            @result&.finalize
            @result&.failure
          ensure
            close_transaction_and_release_connection
          end
        end

        def release_connection
          @connection&.release
        end

        def begin_transaction(mode = @mode, config = nil)
          ensure_no_open_tx_before_starting_tx
          acquire_connection(mode)
          @transaction = ExplicitTransaction.new(@connection, self).begin(bookmarks, config)
        end

        def last_bookmark
          bookmarks&.max
        end

        private

        def transaction(mode, config = nil)
          @retry_logic.retry do
            tx = begin_transaction(mode, config)
            result = yield tx
            tx.success
            result
          rescue StandardError => e
            tx&.failure
            raise e
          ensure
            tx&.close
          end
        end

        def acquire_connection(mode = @mode)
          @result&.failure
          raise Exceptions::IllegalStateException, 'Existing open connection detected' if @connection&.open?
          @connection = @connection_provider.acquire_connection(@mode)
          # old
          # raise Exception, 'existing connection present' if @connection
          #
          # status = Bolt::Status.create
          # @connection = Bolt::Connector.acquire(@connector, mode, status)
          # check_status(status)
        end

        def close_transaction_and_release_connection
          @transaction&.close
        ensure
          @transaction = nil
          release_connection
        end

        def ensure_session_is_open
          return if @open.true?
          raise Exceptions::ClientException,
                'No more interaction with this session are allowed as the current session is already closed.'
        end

        def ensure_no_open_tx_before_running_query
          ensure_no_open_tx('Statements cannot be run directly on a session with an open transaction; ' \
                            'either run from within the transaction or use a different session.')
        end

        def ensure_no_open_tx_before_starting_tx
          ensure_no_open_tx('You cannot begin a transaction on a session with an open transaction; ' \
                            'either run from within the transaction or use a different session.')
        end

        def ensure_no_open_tx(error_message)
          raise Exceptions::ClientException, error_message if @transaction&.open?
        end
      end
    end
  end
end
