class W3DHub
  # all http(s) requests for API calls and downloading images run through here
  class NetworkManager
    NetworkEvent = Data.define(:context, :result)
    Request = Struct.new(:active, :context, :async, :callback)
    Context = Data.define(
      :request_id,
      :method,
      :url,
      :headers,
      :body
    )

    def initialize
      @requests = []
      @running = true

      @thread = Thread.new do
        @http_client = HttpClient.new

        Sync do
          while @running
            request = @requests.find { |r| !r.active }

            # goto sleep for an second if there is no work to be doing
            unless request
              sleep 1
              next
            end

            request.active = true

            Async do |task|
              assigned_request = request
              result = if assigned_request.context.url.empty?
                assigned_request.callback.call(nil)
              else
                @http_client.handle(task, assigned_request)
              end

              @requests.delete(assigned_request)

              # callback for this is already handled!
              unless assigned_request.context.url.empty?
                Store.main_thread_queue << -> { assigned_request.callback.call(result) }
              end
            end
          end
        end
      end
    end

    def request(method, url, headers, body, async, &block)
      request_id = SecureRandom.hex

      request = Request.new(
        false,
        Context.new(
          request_id,
          method,
          url,
          headers,
          body
        ),
        async,
        block
      )

      @requests << request


      if async
        request_id
      else # Not async, process immediately.
        raise "WTF? This should NOT happen!" unless Async::Task.current?

        Sync do |task|
          assigned_request = request
          result = @http_client.handle(task, assigned_request)

          @requests.delete(assigned_request)
          # "return" callback "value"
          assigned_request.callback.call(result)
        end
      end
    end

    def busy?
      @requests.any?(&:active)
    end
  end
end
