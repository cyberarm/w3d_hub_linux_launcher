module W3DHubLauncher
  class Worker
    DEFAULT_HEADERS = [
      ["user-agent", W3DHubLauncher::USER_AGENT]
    ].freeze
    DEFAULT_NETWORK_TIMEOUT = 30

    Response = Data.define(:status, :request_id, :data)

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

      # connect to and monitor GSH web service
      @threads << Thread.new { game_server_hub_websocket }
      # connect to and monitor Backend web service
      @threads << Thread.new { backend_websocket }

      @w3dhub_api = W3DHubLauncher::W3DHubApi.new

      Async do |task|
        UNIXServer.open(IPC_PATH) do |server|
          while(socket = server.accept)
            task.async do
              while(data =socket.gets)
                json = JSON.parse(data)
                query = Request::Query.new(type: json["type"].to_sym, request_id: json["request_id"], data: json["data"])

                pp [:server_incoming, data, query]

                if respond_to?(query.type)
                  response = send(query.type, query)
                  pp [:server_to_client, response]
                  payload = { status: response.status, request_id: response.request_id, data: response.data.data }.to_json
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

    # Send request to server
    def request(query)
      pp [:client_request, query]
      payload = { type: query.type, request_id: query.request_id, data: query.data }.to_json

      if respond_to?(query.type)
        @socket.puts(payload)
      else
        raise "UNKNOWN REQUEST: #{query}"
      end
    end

    def service
      data = @socket.read_nonblock(1_048_576) # 1 MB
      pp [:CLIENT, data]
      json = JSON.parse(data)
      response = Response.new(status: json["status"], request_id: json["request_id"], data: json["data"])
      request = W3DHubLauncher::Worker::Request.requests.find { |r| r.request_id == response.request_id }

      pp [json, response, request]
      return unless request

      CyberarmEngine::Window.instance&.add_to_queue(proc {
        request.handle_event(
          response.status,
          CyberarmEngine::Result.new(data: response.data, error: response.status.negative? ? true : nil)
        )
      })

    rescue Errno::EWOULDBLOCK
    end

    def deliver_response(result, query)
      response = Response.new(result.okay? ? Request::STATUS_COMPLETE : Request::STATUS_ERROR, query.request_id, result)
      pp response

      response
    end

    #
    # ------------ query / request handlers ------------
    #
    def fetch_url(query)
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
