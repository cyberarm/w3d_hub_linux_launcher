class W3DHub
  class ApplicationManager
    class Installer < Task
      def execute_task
        manifests = fetch_manifests
        return false if failed?

        packages = build_package_list(manifests)
        return false if failed?

        fetch_packages(packages)
        return false if failed?

        verify_packages(packages)
        return false if failed?

        unpack_packages(packages)
        return false if failed?

        create_wine_prefix
        return false if failed?

        install_dependencies(packages)
        return false if failed?

        mark_application_installed
        return false if failed?

        true
      end
    end
  end
end