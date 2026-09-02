module W3DHubLauncher
  class W3DHubApi
    API_TIMEOUT = 30 # seconds
    API_CONNECT_TIMEOUT = 10 # seconds

    PRIMARY_W3DHUB_API_ENDPOINT = "https://secure.w3dhub.com".freeze
    ALTERNATIVE_W3DHUB_API_ENDPOINT = "https://backend.w3d.cyberarm.dev".freeze

    def initialize
      @access_token = nil

      @http_clients = {}
    end

    def headers(form_encoded: false)
      array = [
        ["user-agent", W3DHubLauncher::USER_AGENT],
        ["accept", "application/json"],
      ]

      array << ["content-type", "application/x-www-form-urlencoded"] if form_encoded
      array << ["authorization", "Bearer #{@access_token}"] if @access_token

      # pp array

      array
    end

    # return raw response to requester
    def fetch(url, method: :get, body: nil, headers: headers())
      result = CyberarmEngine::Result.new

      Sync do |task|
        task.with_timeout(API_TIMEOUT) do
          Async::HTTP::Internet.send(method, url, headers, body) do |response|
            if response.success?
              result.data = response.read
            else
              pp response
              result.error = true
            end
          end
        rescue StandardError => e
          result.error = e
        rescue Async::TimeoutError => e
          result.error = e
        end

        result
      end

      result
    end

    # write response to file, periodically reporting progress to requester
    def download(url, path:, method: :get, body: nil, headers: headers(), &block)
      result = CyberarmEngine::Result.new

      Sync do |task|
        task.with_timeout(API_TIMEOUT) do
          Async::HTTP::Internet.send(method, url, headers, body) do |response|
            if response.success?
              content_length = response.headers["content-length"] || 0

              total_downloaded_bytes = 0
              File.open(path, "wb") do |file|
                response.each do |chunk|
                  file.write(chunk)
                  downloaded_bytes = chunk.length
                  total_downloaded_bytes += downloaded_bytes

                  block&.call(downloaded_bytes, total_downloaded_bytes, content_length)
                end
              end

              result.data = true
            end
          rescue StandardError => e
            result.error = e
          end
        rescue Async::TimeoutError
          result.error = e
        end
      end

      result
    end

    def user_login()
      result = CyberarmEngine::Result.new
    end

    def refresh_user_login()
      result = CyberarmEngine::Result.new
    end

    def fetch_user_details()
      result = CyberarmEngine::Result.new
    end

    def fetch_applications
      result = CyberarmEngine::Result.new
      # If we're not signed in, then the primary backend will try to redirect us to the alternate backend. So skip it if we're not signed in.
      primary_result = @access_token ? fetch("#{PRIMARY_W3DHUB_API_ENDPOINT}/apis/launcher/1/get-applications") : CyberarmEngine::Result.new(error: true)
      alternate_result = fetch("#{ALTERNATIVE_W3DHUB_API_ENDPOINT}/apis/launcher/1/get-applications")

      # We've failed to retrieve data
      if primary_result.error? && alternate_result.error?
        return result
      # We've only gotten data back from the primary backend
      elsif primary_result.okay? && alternate_result.error?
        result.data = primary_result.data
        return result
      # We've only gotten data back from the alternate backend
      elsif primary_result.error? && alternate_result.okay?
        result.data = alternate_result.data
        return result
      end

      # We've gotten data back from both backends, merge them.
      # pp [primary_result, alternate_result]

      # FIXME: Merge primary and alternate results
      result
    end

    def fetch_news()
      result = CyberarmEngine::Result.new
    end

    def fetch_events()
      result = CyberarmEngine::Result.new
    end

    def fetch_manifest()
      result = CyberarmEngine::Result.new
    end

    def fetch_manifests()
      result = CyberarmEngine::Result.new
    end

    def fetch_package_details()
      result = CyberarmEngine::Result.new
    end

    def fetch_package()
      download()
    end
  end
end
