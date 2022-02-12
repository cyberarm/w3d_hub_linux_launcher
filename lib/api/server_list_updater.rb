class W3DHub
  class Api
    class ServerListUpdater
      include CyberarmEngine::Common

      ##!!! When this breaks update from: https://github.com/socketry/async-websocket/blob/master/lib/async/websocket/connection.rb
      # refinements preserves super... 😢
      class PatchedConnection < ::Protocol::WebSocket::Connection
        include ::Protocol::WebSocket::Headers

        def self.call(framer, protocol = [], **options)
          instance = self.new(framer, Array(protocol).first, **options)

          return instance unless block_given?

          begin
            yield instance
          ensure
            instance.close
          end
        end

        def initialize(framer, protocol = nil, response: nil, **options)
          super(framer, **options)

          @protocol = protocol
          @response = response
        end

        def close
          super

          if @response
            @response.finish
            @response = nil
          end
        end

        attr :protocol

        def read
          if (buffer = super)
            buffer.split("\x1e").map { |json| parse(json) }
          end
        end

        def write(object)
          super("#{dump(object)}\x1e")
        end

        def parse(buffer)
          JSON.parse(buffer, symbolize_names: true)
        end

        def dump(object)
          JSON.dump(object)
        end

        def call
          self.close
        end
      end

      @@instance = nil

      def self.instance
        return @@instance if @@instance

        @@instance = ServerListUpdater.new
      end

      def initialize
        run
      end

      def run
        Thread.new do
          Async do |task|
            internet = Async::HTTP::Internet.instance

            response = internet.post("https://gsh.w3dhub.com/listings/push/v2/negotiate?negotiateVersion=1", Api::DEFAULT_HEADERS, [""])
            data = JSON.parse(response.read, symbolize_names: true)

            id = data[:connectionToken]
            endpoint = Async::HTTP::Endpoint.parse("https://gsh.w3dhub.com/listings/push/v2?id=#{id}", alpn_protocols: Async::HTTP::Protocol::HTTP11.names)

            Async::WebSocket::Client.connect(endpoint, headers: Api::DEFAULT_HEADERS, handler: PatchedConnection) do |connection|
              connection.write({ protocol: "json", version: 1 })
              connection.flush
              pp connection.read
              connection.write({ "type": 6 })

              Store.server_list.each_with_index do |server, i|
                i += 1
                mode = 1 # 2 full details, 1 basic details
                out = { "type": 1, "invocationId": "#{i}", "target": "SubscribeToServerStatusUpdates", "arguments": [server.id, mode] }
                connection.write(out)
              end

              while (message = connection.read)
                connection.write({ type: 6 }) if message.first[:type] == 6

                if message&.first&.fetch(:type) == 1
                  message.each do |rpc|
                    next unless rpc[:target] == "ServerStatusChanged"

                    id, data = rpc[:arguments]
                    server = Store.server_list.find { |s| s.id == id }
                    server_updated = server&.update(data)
                    States::Interface.instance&.update_server_browser(server) if server_updated
                  end
                end
              end
            end
          ensure
            @@instance = nil
          end
        end
      end
    end
  end
end
