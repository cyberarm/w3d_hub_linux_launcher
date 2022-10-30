class W3DHub
  class Api
    class ServerListUpdater
      LOG_TAG = "W3DHub::Api::ServerListUpdater".freeze
      include CyberarmEngine::Common
      @@instance = nil

      def self.instance
        return @@instance if @@instance

        @@instance = ServerListUpdater.new
      end

      def initialize
        logger.info(LOG_TAG) { "Starting emulated SignalR Server List Updater..." }
        run
      end

      def run
        Thread.new do
          begin
            connect
          rescue => e
            puts e
            puts e.backtrace

            sleep 10
            retry
          end
        end

        logger.debug(LOG_TAG) { "Cleaning up..." }
        @@instance = nil
      end

      def connect
        auto_reconnect = false

        logger.debug(LOG_TAG) { "Requesting connection token..." }
        response = Excon.post("https://gsh.w3dhub.com/listings/push/v2/negotiate?negotiateVersion=1", headers: Api::DEFAULT_HEADERS, body: "")
        data = JSON.parse(response.body, symbolize_names: true)

        id = data[:connectionToken]
        endpoint = "https://gsh.w3dhub.com/listings/push/v2?id=#{id}"

        logger.debug(LOG_TAG) { "Connecting to websocket..." }
        WebSocket::Client::Simple.connect(endpoint, headers: Api::DEFAULT_HEADERS) do |ws|
          ws.on(:message) do |msg|
            msg = msg.data.split("\x1e").first

            hash = JSON.parse(msg, symbolize_names: true)

            # Send PING(?)
            if hash.empty? || hash[:type] == 6
              ws.send({ type: 6 }.to_json + "\x1e")
            else
              case hash[:type]
              when 1
                if hash[:target] == "ServerStatusChanged"
                  id, data = hash[:arguments]
                  server = Store.server_list.find { |s| s.id == id }
                  server_updated = server&.update(data)
                  States::Interface.instance&.update_server_browser(server) if server_updated
                end
              end
            end
          end

          ws.on(:open) do
            logger.debug(LOG_TAG) { "Requesting json protocol, v1..." }
            ws.send({ protocol: "json", version: 1 }.to_json + "\x1e")

            logger.debug(LOG_TAG) { "Subscribing to server changes..." }
            Store.server_list.each_with_index do |server, i|
              i += 1
              mode = 1 # 2 full details, 1 basic details
              out = { "type": 1, "invocationId": "#{i}", "target": "SubscribeToServerStatusUpdates", "arguments": [server.id, mode] }
              ws.send(out.to_json + "\x1e")
            end
          end

          ws.on(:close) do |e|
            p e
            auto_reconnect = true
          end

          ws.on(:error) do |e|
            p e
            auto_reconnect = true
          end
        end

        connect if auto_reconnect
      end
    end
  end
end
