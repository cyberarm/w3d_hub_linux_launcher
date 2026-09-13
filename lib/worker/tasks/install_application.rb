module W3DHubLauncher
  class Task
    class InstallApplication < Task
      def setup
      end

      def execute
        # TODO:
        # fail_fast

        # fetch manifests for currently installed version
        # AND the target version so we can detect files that need to be removed
        # between versions
        fetch_manifests

        # build list of packages we'll need to download
        build_package_list

        verify_files

        fetch_packages

        install_packages

        remove_deleted_files
      end
    end
  end
end
