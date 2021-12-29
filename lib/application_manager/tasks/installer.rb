class W3DHub
  class ApplicationManager
    class Installer < Task
      def type
        :installer
      end

      def execute_task
        fail_fast
        return false if failed?

        manifests = fetch_manifests
        return false if failed?

        packages = build_package_list(manifests)
        return false if failed?

        verify_files(manifests, packages)
        return false if failed?

        fetch_packages(packages)
        return false if failed?

        verify_packages(packages)
        return false if failed?

        unpack_packages(packages)
        return false if failed?
        sleep 1

        create_wine_prefix
        return false if failed?
        sleep 1

        install_dependencies(packages)
        return false if failed?
        sleep 1

        mark_application_installed
        return false if failed?

        sleep 5
        hide_application_taskbar

        true
      end
    end
  end
end