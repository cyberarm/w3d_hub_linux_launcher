module W3DHubLauncher
  class Task
    class InstallApplication < Task
      def setup
      end

      def execute
        # TODO:
        # fail_fast

        # get case-insensitive file list
        index_installation_directory

        # fetch manifests for currently installed version
        # AND the target version so we can detect files that need to be removed
        # between versions
        fetch_manifests

        # build list of packages we'll need to download
        build_package_list

        # verify our pre-existing files for presence and validity
        verify_files

        # download required packages to get missing or out of date files
        fetch_packages

        # unpack packages and patch files to reach target version
        install_packages

        # delete files that are no longer part of the application (and whose presence may break the application)
        remove_deleted_files

        # tell the application to behive
        write_paths_ini

        # store application install state and notify frontend/ui that the application is ready for use!
        mark_application_installed
      end
    end
  end
end
