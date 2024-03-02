class W3DHub
  class ApplicationManager
    class Installer < Task
      LOG_TAG = "W3DHub::ApplicationManager::Installer".freeze

      def type
        :installer
      end

      def execute_task
        show_application_taskbar

        fail_fast
        return false if failed?

        fetch_manifests
        return false if failed?

        build_package_list
        return false if failed?

        remove_deleted_files
        return false if failed?

        verify_files
        return false if failed?

        fetch_packages
        return false if failed?

        verify_packages
        return false if failed?

        unpack_packages
        return false if failed?

        create_wine_prefix
        return false if failed?

        install_dependencies
        return false if failed?

        mark_application_installed
        return false if failed?

        sleep 1
        hide_application_taskbar

        true
      end
    end
  end
end