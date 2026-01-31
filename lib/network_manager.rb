class W3DHub
  # all http(s) requests for API calls and downloading images run through here
  class NetworkManager
    NetworkEvent = Data.define(:context, :result)
    Request = Struct.new(:context, :callback)
    Context = Data.define(
      :request_id,
      :method,
      :url,
      :headers,
      :body,
      :bearer_token
    )

    def initialize
      @requests = []
      @running = true

      Thread.new do
        http_client = HttpClient.new

        Sync do
          while @running
            request = @requests.shift

            # goto sleep for an second if there is no work to be doing
            unless request
              sleep 1
              next
            end

            Async do |task|
              assigned_request = request
              result = http_client.handle(task, assigned_request)

              pp [assigned_request, result]

              Store.main_thread_queue << -> { assigned_request.callback.call(result) }
            end
          end
        end
      end
    end

    def request(method, url, headers, body, bearer_token, &block)
      request_id = SecureRandom.hex

      request = Request.new(
        Context.new(
          request_id,
          method,
          url,
          headers,
          body,
          bearer_token
        ),
        block
      )

      @requests << request

      request_id
    end
  end
end
