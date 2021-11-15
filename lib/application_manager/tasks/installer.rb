class W3DHub
  class ApplicationManager
    class Installer < Task
      def setup
        add_step("Fetching manifests...", :fetch_manifests)
        add_step("Building package list...", :build_package_list)

        add_step("Downloading packages...", :fetch_packages)
        add_step("Verifying packages...", :verify_packages)
        add_step("Unpacking packages...", :unpack_packages)

        add_step("Crushing grapes...", :create_wine_prefix)

        add_step("Installing dependencies...", :install_dependencies)

        add_step("Completed.", :mark_application_installed)
      end
    end
  end
end