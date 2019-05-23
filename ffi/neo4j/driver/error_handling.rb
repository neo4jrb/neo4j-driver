# frozen_string_literal: true

module ErrorHandling
  def check_and_print_error(connection = @connection, status = Bolt::Connection.status(connection), error_text = nil)
    error_code = Bolt::Status.error(status)
    return Bolt::Error::BOLT_SUCCESS if error_code == Bolt::Error::BOLT_SUCCESS

    if error_code == Bolt::Error::BOLT_SERVER_FAILURE
      string_buffer = FFI::Buffer.alloc_out(:char, 4096)
      string_buffer[4095] = 0 if Bolt::Value.to_string(Bolt::Connection.failure(connection),
                                                       string_buffer.pointer, 4096, connection) > 4096
      puts("#{error_text || 'server failure'}: #{string_buffer.get_string(0)}")
    else
      error_ctx = Bolt::Status.error_context(status)
      puts("#{error_text || 'Bolt failure'} (code: #{error_code.to_s(16)}, " \
           "text: #{Bolt::Error.get_string(error_code)}, context: #{error_ctx})")
    end
    error_code
  end

  def check_error(code)
    raise Exception, check_and_print_error if code != Bolt::Error::BOLT_SUCCESS
  end
end
