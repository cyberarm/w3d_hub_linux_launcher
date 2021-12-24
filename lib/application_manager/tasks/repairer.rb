class W3DHub
  class ApplicationManager
    class Repairer < Task
      def type
        :repairer
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

        # pp packages.select { |pkg| pkg.name == "misc" }

        true
      end
    end
  end
end