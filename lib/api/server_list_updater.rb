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

      attr_accessor :auto_reconnect, :invocation_id

      def initialize
        @auto_reconnect = false

        @invocation_id = 0

        logger.info(LOG_TAG) { "Starting emulated SignalR Server List Updater..." }
        run
      end

      def run
        return

        Thread.new do
          Sync do |task|
            begin
              async_connect(task)

              while W3DHub::BackgroundWorker.alive?
                async_connect(task) if @auto_reconnect
                sleep 1
              end
            rescue => e
              puts e
              puts e.backtrace

              sleep 30
              retry
            end
          end
        end

        logger.debug(LOG_TAG) { "Cleaning up..." }
        @@instance = nil
      end

      def async_connect(task)
        @auto_reconnect = false

        logger.debug(LOG_TAG) { "Requesting connection token..." }
        response = Api.post("/listings/push/v2/negotiate?negotiateVersion=1", Api::DEFAULT_HEADERS, "", :gsh)

        if response.status != 200
          @auto_reconnect = true
          return
        end

        data = JSON.parse(response.body, symbolize_names: true)

        @invocation_id = 0 if @invocation_id > 9095
        id = data[:connectionToken]
        endpoint = "#{Api::SERVER_LIST_ENDPOINT}/listings/push/v2?id=#{id}"

        logger.debug(LOG_TAG) { "Connecting to websocket..." }

        Async::WebSocket::Client.connect(Async::HTTP::Endpoint.parse(endpoint)) do |connection|
          logger.debug(LOG_TAG) { "Requesting json protocol, v1..." }
          async_websocket_send(connection, { protocol: "json", version: 1 }.to_json)
        end
      end

      def async_websocket_send(connection, payload)
        connection.write("#{payload}\x1e")
        connection.flush
      end

      def async_websocket_read(connection, payload)
      end

      def connect
        @auto_reconnect = false

        logger.debug(LOG_TAG) { "Requesting connection token..." }
        response = Api.post("/listings/push/v2/negotiate?negotiateVersion=1", Api::DEFAULT_HEADERS, "", :gsh)

        if response.status != 200
          @auto_reconnect = true
          return
        end

        data = JSON.parse(response.body, symbolize_names: true)

        @invocation_id = 0 if @invocation_id > 9095
        id = data[:connectionToken]
        endpoint = "#{Api::SERVER_LIST_ENDPOINT}/listings/push/v2?id=#{id}"

        logger.debug(LOG_TAG) { "Connecting to websocket..." }
        this = self
        @ws = WebSocket::Client::Simple.connect(endpoint, headers: Api::DEFAULT_HEADERS) do |ws|
          ws.on(:open) do
            logger.debug(LOG_TAG) { "Requesting json protocol, v1..." }
            ws.send({ protocol: "json", version: 1 }.to_json + "\x1e")

            logger.debug(LOG_TAG) { "Subscribing to server changes..." }
            Store.server_list.each do |server|
              this.invocation_id += 1
              mode = 1 # 2 full details, 1 basic details
              out = { "type": 1, "invocationId": "#{this.invocation_id}", "target": "SubscribeToServerStatusUpdates", "arguments": [server.id, mode] }
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

                  this.invocation_id += 1
                  out = { "type": 1, "invocationId": "#{this.invocation_id}", "target": "SubscribeToServerStatusUpdates", "arguments": [data[:id], 1] }
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
            logger.error(LOG_TAG) { e }
            this.auto_reconnect = true
            ws.close
          end

          ws.on(:error) do |e|
            logger.error(LOG_TAG) { e }
            this.auto_reconnect = true
            ws.close
          end
        end

        @ws = nil
      end

      def refresh_server_list(list)
        new_servers = []
        removed_servers = []

        # find new servers
        list.each do |server|
          found_server = Store.server_list.find { |s| s.id == server.id }

          new_servers << server unless found_server
        end

        # find removed servers
        Store.server_list.each do |server|
          found_server = list.find { |s| s.id == server.id }

          removed_servers << server unless found_server
        end

        # purge removed servers from list
        Store.server_list.reject! do |server|
          removed_servers.find { |s| server.id == s.id }
        end

        # add new servers to list
        Store.server_list = Store.server_list + new_servers

        if @ws
          # unsubscribe from removed servers
          removed_servers.each do
            @invocation_id += 1
            out = { "type": 1, "invocationId": "#{@invocation_id}", "target": "SubscribeToServerStatusUpdates", "arguments": [server.id, 0] }
            ws.send(out.to_json + "\x1e")
          end

          # subscribe to new servers
          new_servers.each do
            @invocation_id += 1
            out = { "type": 1, "invocationId": "#{@invocation_id}", "target": "SubscribeToServerStatusUpdates", "arguments": [server.id, 1] }
            ws.send(out.to_json + "\x1e")
          end
        end

        # sort list
        Store.server_list.sort_by! { |s| [s.status.player_count, s.id] }.reverse!
      end
    end
  end
end
