class W3DHub
  class ApplicationManager
    class Importer < Task
      LOG_TAG = "W3DHub::ApplicationManager::Importer".freeze

      def type
        :importer
      end

      def execute_task
        path = W3DHub.ask_file

        unless File.exist?(path) && !File.directory?(path)
          fail!("File #{path.inspect} does not exist or is a directory")
          fail_silently! if path.nil? || path&.length&.zero? # User likely canceled the file selection
        end

        return false if failed?

        Store.application_manager.imported!(self, path)

        true
      end
    end
  end
end
