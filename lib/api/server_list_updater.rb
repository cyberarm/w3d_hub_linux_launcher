class W3DHub
  class Api
    class ServerListUpdater
      class Connection < ::Protocol::WebSocket::Connection
        def read
          if (buffer = super)
            buffer.split("\x1e").map { |json| parse(json) }
          end
        end

        def read1
          read1&.first
        end

        def write(object)
          super(dump(object) + "\x1e")
        end
      end

      # TODO: Properly start up and monitor for updates to server list
      def initialize
        Async do |task|
          headers = [["User-Agent", "Cyberarm's Websocket Testing"]]

          internet = Async::HTTP::Internet.instance

          response = internet.post("https://gsh.w3dhub.com/listings/push/v2/negotiate?negotiateVersion=1", headers, [""])
          data = JSON.parse(response.read, symbolize_names: true)

          # TODO: Replace with Api.server_list
          response = internet.get("https://gsh.w3dhub.com/listings/getAll/v2?statusLevel=2", headers, [""])
          servers = JSON.parse(response.read, symbolize_names: true)

          id = data[:connectionToken]
          endpoint = Async::HTTP::Endpoint.parse("https://gsh.w3dhub.com/listings/push/v2?id=#{id}", alpn_protocols: Async::HTTP::Protocol::HTTP11.names)

          Async::WebSocket::Client.connect(endpoint, headers: headers, handler: WSS::Connection) do |connection|
            connection.write({ protocol: "json", version: 1 })
            connection.flush
            pp connection.read
            connection.write({ "type": 6 })

            servers.each_with_index do |server, i|
              i += 1
              out = { "type": 1, "invocationId": "#{i}", "target": "SubscribeToServerStatusUpdates", "arguments": [server[:id], 2] }
              connection.write(out)
            end

            while (message = connection.read)
              connection.write({ type: 6 }) if message.first[:type] == 6

              # TODO: process messages (of type 3?)
              pp message
            end
          end
        end
      end
    end
  end
end
