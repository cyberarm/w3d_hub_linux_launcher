# Helper for launcher frontend to safely communicate with ractor (prevent deadlocks and concurrent access errors)

module W3DHubLauncher
  class Worker
    class Api
      Request = Data.define(:coming_soon)

      def initialize
        @requests = []
      end

      # downloads requested resource, returns raw string
      def fetch_url
      end

      # downloads requested resource, periodically reporting progress until completion, returning path for file on disk
      def download_url
      end

      # returns user account data
      #
      # automatically handles signing in / refreshing token (DOES NOT remove account data if failed to refresh token due to network timeout)
      def account
      end

      # returns launcher settings
      def settings
      end

      # write updated launcher settings
      def update_settings
      end

      # returns list of available applications
      #
      # if updated list is requested, return cached version immediately and then the updated list later.
      def applications
      end

      # returns current list of servers as reported from GSH / cache
      def servers
      end

      # returns news for application
      def news
      end

      # request installation of application
      #
      # periodically reports progress until completion
      def install_application
      end

      # request update of application
      #
      # periodically reports progress until completion
      def update_application
      end

      # request repair of application
      #
      # periodically reports progress until completion
      def repair_application
      end

      # request relocation of application
      #
      # periodically reports progress until completion
      def move_application
      end

      # request removal of application
      #
      # periodically reports progress until completion
      def uninstall_application
      end
    end
  end
end
