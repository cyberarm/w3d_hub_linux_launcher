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
        manifests_result = fetch_manifests
        abort_task!(manifests_result) unless manifests_result.okay?

        package_list_result = build_package_list(manifests_result)
        abort_task!(package_list_result) unless package_list_result.okay?

        # remove_deleted_files

        verify_files
      end
    end
  end
end
