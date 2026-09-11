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

      setup
    end

    def setup
    end

    def start(worker)
      @worker =  worker

      execute
    end

    def fetch_manifests(version = @target_version)
      result = fetch_manifest(version)
      if result.okay?
        pp result
      else
        pp [:error, result]
      end
    end

    def fetch_manifest(version)
      @worker.w3dhub_api.fetch_package_details([{category: "games", subcategory: @application.id, name: "manifest.xml", version: version }])
    end
  end
end

def execute_task
  show_application_taskbar

  fail_fast
  return false if failed?

  fetch_manifests
  return false if failed?

  build_package_list
  return false if failed?

  remove_deleted_files
  return false if failed?

  verify_files
  return false if failed?

  fetch_packages
  return false if failed?

  verify_packages
  return false if failed?

  unpack_packages
  return false if failed?

  create_wine_prefix
  return false if failed?

  install_dependencies
  return false if failed?

  write_paths_ini
  return false if failed?

  mark_application_installed
  return false if failed?

  sleep 1
  hide_application_taskbar

  true
end
