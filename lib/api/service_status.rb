class W3DHub
  class Api
    class ServiceStatus
      def initialize(response)
        @data = JSON.parse(response, symbolize_names: true)
      end

      def authentication?
        @data[:services][:authentication]
      end

      def package_download?
        @data[:services][:packageDownload]
      end
    end
  end
end
