module W3DHubLauncher
  class Task
    attr_reader :request_id, :application, :channel, :installed_version, :target_version

    def initialize(request_id:, application:, channel:, installed_version:, target_version:)
      @request_id = request_id
      @application = application
      @channel = channel
      @installed_version = installed_version
      @target_version = target_version

      pp self

      @manifests = {}

      setup
    end

    def setup
    end

    def start(worker)
      @worker =  worker

      execute
    end

    def fetch_manifests(version = @target_version)
      while (manifest = fetch_manifest(version))
        @manifests[version] = manifest

        version = manifest.base_version
      end
    end

    def fetch_manifest(version)
      result = @worker.w3dhub_api.fetch_package_details([{category: "games", subcategory: @application.id, name: "manifest.xml", version: version }])

      return false unless result.okay?

      response = JSON.parse(result.data)
      pp response
      pp package_details = response["packages"]&.map { |item| Worker::Api::LegacyManifestPackage.new(item) }&.first

      return false unless package_details
      return false if package_details.error?

      # FIXME: check if locally downloaded manifest is still valid, if present.
      result = if package_details.download_url
        @worker.w3dhub_api.download(package_details.download_url, path: "manifest-#{version}.xml")
      else
        # TODO xD
        @worker.w3dhub_api.fetch_package("TODO")
      end

      pp result

      return Worker::Api::LegacyManifest.new("manifest-#{version}.xml") if result.okay?

      false
    end
  end
end

# def execute_task
#   show_application_taskbar

#   fail_fast
#   return false if failed?

#   fetch_manifests
#   return false if failed?

#   build_package_list
#   return false if failed?

#   remove_deleted_files
#   return false if failed?

#   verify_files
#   return false if failed?

#   fetch_packages
#   return false if failed?

#   verify_packages
#   return false if failed?

#   unpack_packages
#   return false if failed?

#   create_wine_prefix
#   return false if failed?

#   install_dependencies
#   return false if failed?

#   write_paths_ini
#   return false if failed?

#   mark_application_installed
#   return false if failed?

#   sleep 1
#   hide_application_taskbar

#   true
# end
