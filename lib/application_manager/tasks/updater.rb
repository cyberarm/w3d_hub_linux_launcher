class W3DHub
  class ApplicationManager
    class Updater < Installer
      LOG_TAG = "W3DHub::ApplicationManager::Updater".freeze

      def type
        :updater
      end
    end
  end
end
