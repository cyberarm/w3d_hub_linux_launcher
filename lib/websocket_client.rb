class W3DHub
  class WebSocketClient
    def initialize
      @errored = nil
      @connection = nil

      @events = {
        open: nil,
        message: nil,
        close: nil,
        error: nil
      }
    end

    def connect(endpoint, headers: nil, &block)
      yield(self)

      Sync do |task|
        ssl_context = W3DHub.ca_bundle_path ? OpenSSL::SSL::SSLContext.new : nil
        ssl_context&.alpn_protocols = Async::HTTP::Protocol::HTTP11.names
        ssl_context&.set_params(
          ca_file: W3DHub.ca_bundle_path,
          verify_mode: OpenSSL::SSL::VERIFY_PEER
        )

        endpoint = Async::HTTP::Endpoint.parse(endpoint, alpn_protocols: Async::HTTP::Protocol::HTTP11.names, ssl_context: ssl_context)

        Async::WebSocket::Client.connect(endpoint, headers: headers) do |connection|
          @connection = connection

          @events[:open]&.call

          while message = connection.read
            @events[:message].call(message)
          end
        # FIXME: Don't rescue for all ta errors?
        rescue => error
          @errored = true
          @events[:error]&.call(error)
        ensure
          @events[:close]&.call unless @errored
          @connection = nil
          @errored = false
        end
      end

      self
    end

    def on(event, &block)
      raise "Event must be a symbol" unless event.is_a?(Symbol)
      raise "Unknown event: #{event.inspect}" unless @events.keys.include?(event)
      raise "No block given for #{event.inspect}" unless block_given?

      @events[event] = block
    end

    def send(data, type: :text)
      @connection&.write(data)
      @connection&.flush
    end

    def close
      @connection&.close
    end

    def open?
      !closed?
    end

    def closed?
      @connection&.closed?
    end
  end
end
