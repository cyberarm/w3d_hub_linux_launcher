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

      attr_accessor :auto_reconnect

      def initialize
        @auto_reconnect = false

        logger.info(LOG_TAG) { "Starting emulated SignalR Server List Updater..." }
        run
      end

      def run
        Thread.new do
          begin
            connect

            while W3DHub::BackgroundWorker.alive?
              connect if @auto_reconnect
              sleep 1
            end
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
        @auto_reconnect = false

        logger.debug(LOG_TAG) { "Requesting connection token..." }
        response = Excon.post("https://gsh.w3dhub.com/listings/push/v2/negotiate?negotiateVersion=1", headers: Api::DEFAULT_HEADERS, body: "")
        data = JSON.parse(response.body, symbolize_names: true)

        invocation_id = 0
        id = data[:connectionToken]
        endpoint = "https://gsh.w3dhub.com/listings/push/v2?id=#{id}"

        logger.debug(LOG_TAG) { "Connecting to websocket..." }
        this = self
        WebSocket::Client::Simple.connect(endpoint, headers: Api::DEFAULT_HEADERS) do |ws|
          ws.on(:open) do
            logger.debug(LOG_TAG) { "Requesting json protocol, v1..." }
            ws.send({ protocol: "json", version: 1 }.to_json + "\x1e")

            logger.debug(LOG_TAG) { "Subscribing to server changes..." }
            Store.server_list.each do |server|
              invocation_id += 1
              mode = 1 # 2 full details, 1 basic details
              out = { "type": 1, "invocationId": "#{invocation_id}", "target": "SubscribeToServerStatusUpdates", "arguments": [server.id, mode] }
              ws.send(out.to_json + "\x1e")
            end
          end

          ws.on(:message) do |msg|
            msg = msg.data.split("\x1e").first

            hash = JSON.parse(msg, symbolize_names: true)

            # pp hash if hash[:target] != "ServerStatusChanged" && hash[:type] != 6 && hash[:type] != 3

            # Send PING(?)
            if hash.empty? || hash[:type] == 6
              ws.send({ type: 6 }.to_json + "\x1e")
            else
              case hash[:type]
              when 1
                case hash[:target]
                when "ServerRegistered"
                  data = hash[:arguments].first

                  invocation_id += 1
                  out = { "type": 1, "invocationId": "#{invocation_id}", "target": "SubscribeToServerStatusUpdates", "arguments": [data[:id], 1] }
                  ws.send(out.to_json + "\x1e")

                  BackgroundWorker.foreground_job(
                    ->(data) { [Api.server_details(data[:id], 2), data] },
                    ->(array) do
                      server_data, data = array

                      next unless server_data

                      data[:status] = server_data

                      server = ServerListServer.new(data)
                      Store.server_list.push(server)
                      States::Interface.instance&.update_server_browser(server, :update)
                    end,
                    nil,
                    data
                  )

                when "ServerStatusChanged"
                  id, data = hash[:arguments]
                  server = Store.server_list.find { |s| s.id == id }
                  server_updated = server&.update(data)

                  BackgroundWorker.foreground_job(->(server) { server }, ->(server) { States::Interface.instance&.update_server_browser(server, :update) }, nil, server) if server_updated

                when "ServerUnregistered"
                  id = hash[:arguments].first
                  server = Store.server_list.find { |s| s.id == id }

                  if server
                    Store.server_list.delete(server)
                    BackgroundWorker.foreground_job(->(server) { server }, ->(server) { States::Interface.instance&.update_server_browser(server, :remove) }, nil, server)
                  end
                end
              end
            end
          end

          ws.on(:close) do |e|
            p e
            this.auto_reconnect = true
            ws.close
          end

          ws.on(:error) do |e|
            p e
            this.auto_reconnect = true
            ws.close
          end
        end
      end
    end
  end
end
