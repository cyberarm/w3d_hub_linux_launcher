# Helper for launcher frontend to safely communicate with ractor (prevent deadlocks and concurrent access errors)

module W3DHubLauncher
  class Worker
    class Api
      # downloads requested resource, returns raw string
      def self.fetch_url
      end

      # downloads requested resource, periodically reporting progress until completion, returning path for file on disk
      def self.download_url
      end

      # returns user account data
      #
      # automatically handles signing in / refreshing token (DOES NOT remove account data if failed to refresh token due to network timeout)
      def self.account
      end

      # returns launcher settings
      def self.settings
      end

      # write updated launcher settings
      def self.update_settings(settings, &block)
        Worker::Request.new(Request::LAUNCHER_UPDATE_SETTINGS, settings.to_json, &block)
      end

      # returns list of available applications
      #
      # if updated list is requested, return cached version immediately and then the updated list later.
      def self.applications
      end

      # returns current list of servers as reported from GSH / cache
      def self.servers
      end

      # returns news for application
      def self.news
      end

      # request installation of application
      #
      # periodically reports progress until completion
      def self.install_application
      end

      # request update of application
      #
      # periodically reports progress until completion
      def self.update_application
      end

      # request repair of application
      #
      # periodically reports progress until completion
      def self.repair_application
      end

      # request relocation of application
      #
      # periodically reports progress until completion
      def self.move_application
      end

      # request removal of application
      #
      # periodically reports progress until completion
      def self.uninstall_application
      end
    end
  end
end
