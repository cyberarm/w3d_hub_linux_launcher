class W3DHub
  # all http(s) requests for API calls and downloading images run through here
  class NetworkManager
    NetworkEvent = Data.define(:context, :result)
    Request = Struct.new(:context, :callback)
    Context = Data.define(
      :request_id,
      :url,
      :headers,
      :body,
      :bearer_token
    )

    def initialize
      @requests = {}

      @ractor = Ractor.new do
        raise "Something has gone quite wrong!" if Ractor.main?

        queue = []
        api_client = ApiClient.new

        # Ractor has no concept of non-blocking send/receive... :cry:
        Thread.new do
          while (context = Ractor.receive) # blocking
            # we cannot (easily) ensure we always are receive expected data
            next unless context.is_a?(Context)

            queue << context
          end
        end

        Async do
          loop do
            context = queue.shift

            # goto sleep for an instant if there is no work to be doing
            unless context
              sleep 0.1
              next
            end

            Sync do
              result = api_client.handle(context)

              Ractor.yield(NetworkEvent.new(context, result))
            end
          end
        end
      end

      monitor
    end

    def add_request(url, headers, body, bearer_token, &block)
      request_id = SecureRandom.hex

      @requests << Request.new(
        Context.new(
          request_id,
          url,
          headers,
          body,
          bearer_token
        ),
        block
      )

      @ractor.send(context)

      request_id
    end

    def monitor
      raise "Something has gone quite wrong!!!" unless Ractor.main?

      # Thread that spends its days sleeping **yawn**
      Thread.new do
        while (event = @ractor.take)
          pp event

          next unless event.is_a?(NetworkEvent)

          request = @request.find { |r| r.context.request_id == event.context.request_id }

          next if request

          @requests.delete(request)
          result = event.result

          Store.main_thread_queue << ->(result) { request.callback(result) }
        end
      end
    end
  end
end
