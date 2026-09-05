module W3DHubLauncher
  class Worker
    DEFAULT_HEADERS = [
      ["user-agent", W3DHubLauncher::USER_AGENT]
    ].freeze
    DEFAULT_NETWORK_TIMEOUT = 30

    Response = Data.define(:status, :request_id, :result)

    def initialize
    end

    def connect
      puts :connect

      @socket = UNIXSocket.new(IPC_PATH)
    end

    def connected?
      @socket && !@socket.closed?
    end

    def listen
      init_server
    end

    def init_server
      @threads = []
      @requests = []

      @settings = 0# Settings.new
      @game_servers = []
      @host_pings = {}

      # connect to and monitor GSH web service
      @threads << Thread.new { game_server_hub_websocket }
      # connect to and monitor Backend web service
      @threads << Thread.new { backend_websocket }
      # poke game servers to ascertain their ping relative to the local machine
      @threads << Thread.new { ping_game_servers }

      @w3dhub_api = W3DHubLauncher::W3DHubApi.new

      Async do |task|
        UNIXServer.open(IPC_PATH) do |server|
          while(socket = server.accept)
            task.async do
              while(data = socket.gets)
                json = JSON.parse(data)
                query = Request::Query.new(type: json["type"].to_sym, request_id: json["request_id"], data: json["data"])

                # pp [:server_incoming, data, query]

                if respond_to?(query.type)
                  response = send(query.type, query)
                  # pp [:server_to_client, response]
                  payload = { status: response.status, request_id: response.request_id, data: response.result.data, error: response.result.error }.to_json
                  socket.puts(payload)
                end
              end
            end
          end
        ensure # manually delete "socket"
          File.delete(IPC_PATH)
        end
      end
    end

    def game_server_hub_websocket
    end

    def backend_websocket
    end

    def ping_game_servers
      socket = Socket.open(Socket::AF_INET, Socket::SOCK_DGRAM, Socket::IPPROTO_ICMP)
      socket.setsockopt(:SOCKET, :TIMESTAMP, true)

      Async do |task|
        while true
          echo_requests = {}

          # Send pings to each unique server host
          @game_servers.map(&:address).uniq.each do |server_address|
            address = Socket.sockaddr_in(0, server_address)
            sequence_id = Digest::SHA256.hexdigest("#{server_address}-#{Time.now.iso8601}")

            # ICMP Echo Request, ICMP Code, <checksum>, <identifier>, <sequence number>, Data
            msg = [8, 0, 0, 0, sequence_id].flatten.pack("C2n2A64")
            echo_requests[sequence_id] = { send_time: Time.now, address: server_address, replied: false }
            socket.send(msg, 0, address)
          end

          # Receive replies until timeout
          task.with_timeout(3) do
            while(echo_requests.values.any? { |v| v[:replied] == false })
              response, sender_address, flags, *controls = socket.recvmsg(256)
              _type, _code, _identifier, _sequence, data = response.unpack("C2n2A64")

              if (request = echo_requests[data])# && request[:address] == sender_address.
                request[:replied] = true
                round_trip_time = ((controls.last.timestamp - request[:send_time]) * 1000.0).round
                @host_pings[request[:address]] = round_trip_time

                # puts "#{request[:address]}: #{round_trip_time}ms"
              # else
              #   # packet not for us, or it got mangled in transit.
              end
            end
          rescue Async::TimeoutError
            # puts "Timed out waiting for: #{echo_requests.values.select { |v| v[:replied] == false }.map { |v| v[:address] }.join(', ')}"
          end

          sleep 5
        end
      end

    ensure
      socket&.close
    end

    # Send request to server
    def request(query)
      # pp [:client_request, query]
      payload = { type: query.type, request_id: query.request_id, data: query.data }.to_json

      if respond_to?(query.type)
        @socket.puts(payload)
      else
        raise "UNKNOWN REQUEST: #{query}"
      end
    end

    def service
      data = @socket.read_nonblock(1_048_576) # 1 MB
      # pp [:CLIENT, data]
      json = JSON.parse(data)
      request = W3DHubLauncher::Worker::Request.requests.find { |r| r.request_id == json["request_id"] }

      # pp [json, request]
      return unless request

      CyberarmEngine::Window.instance&.add_to_queue(proc {
        request.handle_event(
          json["status"],
          CyberarmEngine::Result.new(data: json["data"], error: json["error"])
        )
      })

    rescue Errno::EWOULDBLOCK
    end

    def deliver_response(result, query)
      response = Response.new(result.okay? ? Request::STATUS_COMPLETE : Request::STATUS_ERROR, query.request_id, result)
      # pp response

      response
    end

    #
    # ------------ query / request handlers ------------
    #
    def fetch_url(query)
      result = CyberarmEngine::Result.new

      method = query.data["method"]
      url = query.data["url"]
      headers = query.data["headers"] || DEFAULT_HEADERS
      body = query.data["body"]

      Sync do |task|
        task.with_timeout(DEFAULT_NETWORK_TIMEOUT) do
          Async::HTTP::Internet.send(method, url, headers, body) do |response|
            if response.success?
              result.data = response.read
            end
        #   rescue StandardError => e
        #     result.error = e
          end
        # rescue Async::TimeoutError
        #   result.error = e
        end
      end

      deliver_response(result, query)
    end

    def download_url(query)
      result = CyberarmEngine::Result.new

      method = query.data["method"]
      url = query.data["url"]
      path = query.data["path"]
      headers = query.data["headers"] || DEFAULT_HEADERS
      body = query.data["body"]

      Sync do |task|
        task.with_timeout(DEFAULT_NETWORK_TIMEOUT) do
          Async::HTTP::Internet.send(method, url, headers, body) do |response|
            if response.success?
              content_length = response.headers["content-length"] || 0

              total_downloaded_bytes = 0
              File.open(path, "wb") do |file|
                response.each do |chunk|
                  file.write(chunk)
                  downloaded_bytes = chunk.length
                  total_downloaded_bytes += downloaded_bytes

                  progress_result = CyberarmEngine::Result.new(data: {
                    downloaded_bytes: downloaded_bytes,
                    total_downloaded_bytes: total_downloaded_bytes,
                    content_length: content_length
                  })
                  # FIXME: Send intermediate response to requester
                  # send(query, Response.new(Request::STATUS_IN_PROGRESS, query.request_id progress_result))
                end
              end

              result.data = true
            end
        #   rescue StandardError => e
        #     result.error = e
          end
        # rescue Async::TimeoutError
        #   result.error = e
        end
      end

      deliver_response(result, query)
    end

    def dns_resolution(query)
      result = CyberarmEngine::Result.new

      domains = [
        "w3dhub-api.w3d.cyberarm.dev",
        "s3.w3d.cyberarm.dev",
        "secure.w3dhub.com"
      ]

      domains.each do |domain|
        Resolv.getaddress(domain)
      rescue StandardError => e
        result.error = "Failed to resolve: #{domain}"
      end

      result.data = true if result.error.nil?

      deliver_response(result, query)
    end

    def w3dhub_api_call(query)
      result = @w3dhub_api.send(query.data["call"], *(query.data["arguments"] || []))

      deliver_response(result, query)
    end

    def load_settings(query)
      result = CyberarmEngine::Result.new

      path = "#{W3DHubLauncher::CONFIG_PATH}/settings.json"
      begin
        if File.exist?(path) && File.size(path).positive?
          json = File.read(path)
          result.data = json
        else
          result.error = RuntimeError.new("Launcher settings file does not exist or is empty.")
        end
      rescue => e
        result.error = e
      end

      deliver_response(result, query)
    end

    def update_settings(query)
      result = CyberarmEngine::Result.new

      begin
        @settings = Api::Settings.new(JSON.parse(query.data))
        FileUtils.mkdir_p(W3DHubLauncher::CONFIG_PATH)
        File.write("#{W3DHubLauncher::CONFIG_PATH}/settings.json", query.data)

        result.data = query.data
      rescue => e
        result.error = e
      end

      deliver_response(result, query)
    end

    def servers(query)
      hash = {
        "method" => "get",
        "url" => "https://gsh.w3d.cyberarm.dev/listings/getAll/v2?statusLevel=2",
        "headers" => DEFAULT_HEADERS,
        "body" => query.data["body"]
      }

      # inject data into query
      query = Request::Query.new(query.type, query.request_id, hash)

      response = fetch_url(query)

      if response.result.okay?
        @game_servers = JSON.parse(response.result.data).map { |server| Worker::Api::GameServer.new(server) }
      end

      deliver_response(response.result, query)
    end

    def install_application(query)
    end

    def update_application(query)
    end

    def repair_application(query)
    end

    def move_application(query)
    end

    def uninstall_application(query)
    end
  end
end
