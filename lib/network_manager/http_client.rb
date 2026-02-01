class W3DHub
  class NetworkManager
    # non-blocking, http requests.
    class HttpClient
      def initialize
        @http_clients = {}
      end

      def handle(task, request)
        result = CyberarmEngine::Result.new
        context = request.context

        task.with_timeout(W3DHub::Api::API_TIMEOUT) do
          uri = URI(context.url)

          response = provision_http_client(uri.origin).send(
            context.method,
            uri.request_uri,
            context.headers,
            context.body
          )

          if response.success?
            result.data = response.read
          else
            result.error = response
          end
        rescue Async::TimeoutError => e
          result.error = e
        rescue StandardError => e
          result.error = e
        ensure
          response&.close
        end

        result
      end

      def provision_http_client(hostname)
        return @http_clients[hostname.downcase] if @http_clients[hostname.downcase]

        ssl_context = W3DHub.ca_bundle_path ? OpenSSL::SSL::SSLContext.new : nil
        ssl_context&.set_params(
          ca_file: W3DHub.ca_bundle_path,
          verify_mode: OpenSSL::SSL::VERIFY_PEER
        )

        endpoint = Async::HTTP::Endpoint.parse(hostname, ssl_context: ssl_context)
        @http_clients[hostname.downcase] = Async::HTTP::Client.new(endpoint)
      end

      def wrapped_error(error)
        WrappedError.new(error.class, error.message.to_s, error.backtrace)
      end
    end
  end
end
