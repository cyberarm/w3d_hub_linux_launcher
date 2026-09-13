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

    def abort_task!(reason = "")
      puts reason

      raise reason
    end

    # high level methods

    def fetch_manifests(version = @target_version)
      while (manifest = fetch_manifest(version))
        @manifests[version] = manifest

        version = manifest.base_version
        break unless version
        break if manifest.full?
      end
    end

    def build_package_list
      channel_manifests = []
      version = @target_version

      while(manifest = @manifests[version])
        channel_manifests << manifest

        break if manifest.full?

        version = manifest.base_version
      end

      files = []
      deleted_files = []
      channel_manifests.reverse.each do |manifest|
        manifest.files.each do |file|
          if file.removed?
            files.delete_if { |f| f.name.casecmp?(file.name) }
            deleted_files << file

            next
          end

          # remove files that are total replacements, not patches
          files.delete_if { |f| f.name.casecmp?(file.name) } unless file.patch?

          # add file to file list
          files << file
        end
      end

      pp [:files, files.map(&:name), :deleted_files, deleted_files.map(&:name)]
    end

    def remove_deleted_files
    end

    def verify_files
    end

    def fetch_packages
    end

    def install_packages
    end

    # helper functions

    def fetch_manifest(version)
      result = @worker.w3dhub_api.fetch_package_details([
        {
          category: "games",
          subcategory: @application.id,
          name: "manifest.xml",
          version: version
        }
      ])

      return result unless result.okay?

      response = JSON.parse(result.data)
      package_details = response["packages"]&.map { |item| Worker::Api::LegacyManifestPackage.new(item) }&.first

      if package_details.nil? || package_details.error?
        pp package_details
        abort_task!("Failed to fetch package details for manifest #{version}")
      end

      # FIXME: check if locally downloaded manifest is still valid, if present.
      result = if package_details.download_url
        @worker.w3dhub_api.download(package_details.download_url, path: "manifest-#{version}.xml")
      else
        # TODO xD
        @worker.w3dhub_api.fetch_package("TODO")
      end

      if result.okay?
        return Worker::Api::LegacyManifest.new("manifest-#{version}.xml")
      else
        abort_task!("Failed to fetch manifest #{version}")
      end
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
