class W3DHub
  class ApplicationManager
    class Installer < Task
      def type
        :installer
      end

      def execute_task
        update_application_taskbar("Downloading #{@application.name}...", "Fetching manifests...", 0.0)
        manifests = fetch_manifests
        return false if failed?

        update_application_taskbar("Downloading #{@application.name}...", "Building package list...", 0.0)
        packages = build_package_list(manifests)
        return false if failed?

        # update_application_taskbar("Downloading #{@application.name}...", "Downloading packages...", 0.0)
        fetch_packages(packages)
        return false if failed?

        update_application_taskbar("Downloading #{@application.name}...", "Verifying packages...", 0.0)
        verify_packages(packages)
        return false if failed?

        update_application_taskbar("Installing #{@application.name}...", "Unpacking...", 0.0)
        unpack_packages(packages)
        return false if failed?
        sleep 1

        update_application_taskbar("Installing #{@application.name}...", "Creating wine prefix...", 0.0)
        create_wine_prefix
        return false if failed?
        sleep 1

        update_application_taskbar("Installing #{@application.name}...", "Installing dependencies...", 0.0)

        install_dependencies(packages)
        return false if failed?
        sleep 1

        mark_application_installed
        return false if failed?

        update_application_taskbar("Installed #{@application.name}", "", 1.0)
        sleep 5
        hide_application_taskbar

        true
      end
    end
  end
end