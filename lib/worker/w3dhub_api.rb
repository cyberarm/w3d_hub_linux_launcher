module W3DHubLauncher
  class W3DHubApi
    API_TIMEOUT = 30 # seconds
    API_CONNECT_TIMEOUT = 10 # seconds

    PRIMARY_W3DHUB_API_ENDPOINT = "https://secure.w3dhub.com".freeze
    ALTERNATIVE_W3DHUB_API_ENDPOINT = "https://backend.w3d.cyberarm.dev".freeze

    def initialize
      @access_token = nil
    end

    def headers(form_encoded: false)
    end

    # return raw response to requester
    def fetch(url, method: :get, body: nil, headers: headers())
      result = CyberarmEngine::Result.new

      Sync do |task|
        task.with_timeout(API_TIMEOUT) do
          Async::HTTP::Internet.send(method, url, headers, body) do |response|
            result.data = response.read
          rescue StandardError => e
            result.error = e
          end
        rescue Async::TimeoutError
          result.error = e
        end
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
