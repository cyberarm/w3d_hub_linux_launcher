class W3DHub
  class ApplicationManager
    class Repairer < Installer
      LOG_TAG = "W3DHub::ApplicationManager::Repairer".freeze

      def type
        :repairer
      end

      # def execute_task
      #   fail_fast
      #   return false if failed?

      #   manifests = fetch_manifests
      #   return false if failed?

      #   packages = build_package_list(manifests)
      #   return false if failed?

      #   verify_files(manifests, packages)
      #   return false if failed?

      #   # pp packages.select { |pkg| pkg.name == "misc" }

      #   true
      # end
    end
  end
end