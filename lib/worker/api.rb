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
        Worker::Request.new(:update_settings, settings.to_json, &block)
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
      def self.news(category = "launcher-home", &block)
        Worker::Request.new(:news, category, &block)
      end

      # returns news for application
      def self.events(app_id, &block)
        Worker::Request.new(:events, app_id, &block)
      end

      # request installation of application
      #
      # periodically reports progress until completion
      def self.install_application(app_id, channel_id)
      end

      # request update of application
      #
      # periodically reports progress until completion
      def self.update_application(app_id, channel_id)
      end

      # request repair of application
      #
      # periodically reports progress until completion
      def self.repair_application(app_id, channel_id)
      end

      # request relocation of application
      #
      # periodically reports progress until completion
      def self.move_application(app_id, channel_id)
      end

      # request removal of application
      #
      # periodically reports progress until completion
      def self.uninstall_application(app_id, channel_id)
      end
    end
  end
end
