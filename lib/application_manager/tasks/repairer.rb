class W3DHub
  class ApplicationManager
    class Repairer < Installer
      LOG_TAG = "W3DHub::ApplicationManager::Repairer".freeze

      def type
        :repairer
      end
    end
  end
end