module W3DHubLauncher
  class Task
    # ignore *.meta and paths.ini files
    IGNORED_FILES = [/\A.+\.meta\z/i, /\A.+\/paths\.ini\z/i].freeze

    IndexedFile = Data.define(:type, :path)

    attr_reader :request_id, :application, :channel, :installed_version, :target_version

    def initialize(request_id:, application:, channel:, installed_version:, target_version:)
      @request_id = request_id
      @application = application
      @channel = channel
      @installed_version = installed_version
      @target_version = target_version

      pp self

      # caching mechinism for file path normalization
      @file_index = {}
      # manifests!
      @manifests = {}
      # files that must exist for a valid installation
      @manifest_files = []
      # files that should be removed
      @deleted_manifest_files = []
      # files needed to make installation valid for target version
      @required_manifest_files = []
      # packages to verify and/or download
      @packages = []

      setup
    end

    def setup
    end

    def start(worker)
      @worker = worker

      @installation_directory ||= application_target_installation_directory

      update_status(label: "Starting...", fraction: 0.0)

      execute
    end

    def abort_task!(reason = "")
      puts reason

      message_requester(Worker::Request::STATUS_ERROR, data: nil, error: reason)

      raise reason
    end

    # high level methods

    def index_installation_directory
      return unless File.directory?(@installation_directory)

      Dir.glob("#{@installation_directory}/**/**").each do |path|
        add_to_file_index(path)
      end
    end

    def fetch_manifests(version = @target_version)
      update_status(label: "Fetching manifests...", fraction: 0.0)

      while (manifest = fetch_manifest(version))
        @manifests[version] = manifest

        version = manifest.base_version
        break unless version
        break if manifest.full?
      end
    end

    def build_package_list
      update_status(label: "Building package list...", fraction: 0.0)

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

          # exclude ignored files from consideration
          files.delete_if { |f| ignored_file?(f.name) }

          # add file to file list
          files << file
        end
      end

      @manifest_files = files
      @deleted_manifest_files = deleted_files
    end

    def verify_files
      update_status(label: "Verifying files...", fraction: 0.0)

      @required_manifest_files = @manifest_files.clone

      # Process manifest game files in NEWEST to OLDEST order so that we don't erroneously flag
      #   valid files as invalid due to an OLDER version of the file being checked FIRST.
      @manifest_files.reverse.each do |file|
        break unless File.directory?(@installation_directory)

        # skip irrelevant older versions of files
        next unless @required_manifest_files.include?(file)

        file_path = normalize_path(file.name)

        next unless File.exist?(file_path) # && !File.directory?(file_path)

        puts "verifying #{file_path}..."
        checksum = Digest::SHA256.file(file_path).hexdigest.upcase

        if checksum == file.checksum
          @required_manifest_files.delete(file)

          # remove irrelevant older versions of the file from consideration
          @required_manifest_files.delete_if { |f| f.name.casecmp?(file.name) && f.version < file.version }
        end
      end
    end

    def fetch_packages
      update_status(label: "Downloading packages...", fraction: 0.0)

      required_packages = {}
      @required_manifest_files.each do |file|
        required_packages[file.version] ||= []

        next if required_packages[file.version].find { |pkg| pkg.casecmp?(file.package) }

        required_packages[file.version] << file.package
      end

      packages = required_packages.map do |version, packages|
        packages.map do |package_name|
          {
            category: @application.category,
            subcategory: @application.id,
            name: format("%s.zip", package_name),
            version: version.to_s
          }
        end
      end.flatten

      return if packages.empty?

      result = @worker.w3dhub_api.fetch_package_details(packages)

      unless result.okay?
        abort_task!("Failed to fetch required package details!")
      end

      response = JSON.parse(result.data)
      manifest_packages = response["packages"]&.map { |item| Worker::Api::LegacyManifestPackage.new(item) }
      if (failed_packages = manifest_packages.select(&:error?)) && !failed_packages.empty?
        abort_task!("Failed to retrieve packages details for: #{failed_packages.map { |pkg| "#{pkg.name}:#{pkg.version}: #{pkg.error}"}.join(', ') }")
      end

      @packages = manifest_packages

      manifest_packages.each do |pkg|
        file_path = package_cache_path(pkg)
        unless File.directory?(File.dirname(file_path))
          puts "creating directory: #{File.dirname(file_path)}"
          create_directory(File.dirname(file_path))
        end

        partially_valid_at = 0
        state = pkg.verify_file(file_path)
        if state.is_a?(Integer)
          puts "partially valid at: #{state} bytes (#{file_path})" # 20971520
          partially_valid_at = state
        else
          if state == true # completely verified, skip download!
            puts "skipping #{file_path}"
            next
          end
        end

        result = if pkg.download_url
          puts "downloading #{pkg.download_url} to #{file_path}"
          @worker.w3dhub_api.download(pkg.download_url, path: file_path, headers: @worker.w3dhub_api.headers(range: partially_valid_at))
        else
          # TODO xD
          @worker.w3dhub_api.fetch_package("TODO")
        end

        abort_task!("Failed to download required package: #{pkg.name}:#{pkg.version} (#{result.error})") unless result.okay?
      end
    end

    def install_packages
      update_status(label: "Installing...", fraction: 0.0)

      create_directory(@installation_directory)

      processed_packages = {}
      @required_manifest_files.each do |manifest_file|
        package = @packages.find do |pkg|
          pkg.name.casecmp?("#{manifest_file.package}.zip") && manifest_file.version == pkg.version
        end
        package_path = package_cache_path(package)

        next if processed_packages[package_path]

        if manifest_file.patch?
          apply_patch(manifest_file, package)
        else
          unzip(package_path)
        end

        processed_packages[package_path] = manifest_file
      end
    end

    def remove_deleted_files
      update_status(label: "Removing files...", fraction: 0.0)

      @deleted_manifest_files.each do |manifest_file|
        file_path = normalize_path(manifest_file.name)

        if File.exist?(file_path) && !File.directory?(file_path)
          puts "Removing file: #{file_path}"
          File.delete(file_path)

          remove_from_file_index(file_path)
        end
      end
    end

    def write_paths_ini
      File.open(normalize_path("data/paths.ini"), "w") do |file|
        file.puts("[paths]")
        file.puts("RegBase=W3D Hub")
        file.puts("RegClient=#{@application.category}\\#{@application.id}-#{@channel.id}")
        file.puts("RegFDS=#{@application.category}\\#{@application.id}-#{@channel.id}-server")
        file.puts("FileBase=W3D Hub");
        file.puts("FileClient=#{@application.category}\\#{@application.id}-#{@channel.id}")
        file.puts("FileFDS=#{@application.category}\\#{@application.id}-#{@channel.id}-server")

        file.puts("UseRenFolder=#{@channel.extended_data("usesRenFolder", false)}")
      end
    end

    # updated, and moved applications will overwrite existing application data in settings
    def mark_application_installed
      app = Worker::Api::Settings::Application.create(
        id: @application.id,
        channel: @channel.id,
        version: @target_version.to_s,
        installation_path: @installation_directory,
        wine_prefix_path: "",
        launch_command: "%COMMAND%",
        timestamp: Time.now.to_i
      )

      message_requester(Worker::Request::STATUS_COMPLETE, data: { application: app })

      puts "APPLICATION: #{@application.name} #{@application.id}:#{@channel.id}:#{@target_version} installed."
    end

    def mark_application_uninstalled
      message_requester(Worker::Request::STATUS_COMPLETE, data: {})
    end

    # helper functions

    def message_requester(status = Worker::Request::STATUS_IN_PROGRESS, data:, error: nil)
      @worker.message_requester(request_id: @request_id, status: status, data: data, error: error)
    end

    def update_status(label:, fraction:)
      message_requester(data: { status: { title: "TASK #{@application.name} (#{@channel.name})", label: label, fraction: fraction } } )
    end

    def application_target_installation_directory
      target_application = @worker.settings.applications.find { |app| app.id == @application.id && app.channel == @channel.id }
      if target_application
        target_application.installation_path
      else
        format("%s/%s/%s", @worker.settings.preferences.application_installation_directory, @application.id, @channel.id)
      end
    end

    def package_cache_path(package)
      directory = @worker.settings.preferences.launcher_package_cache_directory

      if package.version?
        format("%s/%s/%s/%s", directory, @application.id, package.version.to_s, package.name)
      else
        format("%s/%s/%s", directory, @application.id, package.name)
      end
    end

    def ignored_file?(path)
      IGNORED_FILES.any? { |regex| path.match?(regex) }
    end

    def create_directory(path)
      path.gsub!("\\", "/")

      # directory doesn't exists, create it!
      unless File.directory?(path)
        FileUtils.mkdir_p(path)

        add_directory_to_file_index(path)
      end
    end

    # add EXISTING file or directory to index
    def add_to_file_index(path)
      path.gsub!("\\", "/")

      @file_index[path.downcase] = IndexedFile.new(File.directory?(path) ? :directory : :file, path)
    end

    # add EXISTING directory to file index, walking up the directory tree until existing directory entries are found
    # NOTE: this will **NOT** "scan" the directory for new directories or files
    def add_directory_to_file_index(path)
      path.gsub!("\\", "/")

      segments = path.split("/")
      sub_path = path
      until (file_index = @file_index[sub_path.downcase])
        @file_index[sub_path.downcase]

        segments.pop

        break if segments.empty?

        sub_path = segments.join("/")
      end
    end

    def remove_from_file_index(path)
      path.gsub!("\\", "/")

      @file_index.delete(path.downcase)
    end

    # And behold, the backslashes were slain and the path deemed sane!
    def normalize_path(base_path)
      base_path = base_path.gsub("\\", "/")
      path = "#{@installation_directory}/#{base_path}".gsub("\\", "/")

      # try to find exact, existing match
      index_file = @file_index[path.downcase]
      return index_file.path if index_file

      # try to find directory structure
      if (index_directory = @file_index[File.dirname(path).downcase])
        return format("%s/%s", index_directory.path, File.basename(path))
      end

      # walk directories to see if we have a partial path match
      sub_paths = base_path.split("/")
      sub_paths.pop # drop file name from sub path reconstruction
      unless sub_paths.empty?
        partial_index_directory = nil
        sub_path = format("%s/%s", @installation_directory, sub_paths.shift).downcase
        while (partial_index_directory = @file_index[sub_path.downcase])
          sub_path = format("%s/%s", sub_path, sub_paths.shift)
        end

        if partial_index_directory
          if sub_paths.empty? # we've found the path!
            return format("%s/%s", partial_index_directory.path, File.basename(base_path))
          else # we has a directory or two that don't exist, downcase them, and then head out to the pub!
            return format("%s/%s/%s", partial_index_directory.path, sub_paths.map(&:downcase).join("/"), File.basename(base_path))
          end
        end
      end

      # path doesn't exist, convert directories to lower-case, and use provided file case
      if File.basename(path) == base_path # base_path doesn't have a sub directory
        format("%s/%s", File.dirname(path), File.basename(path))
      else # base_path has sub directory/directories
        format("%s/%s/%s", @installation_directory, File.dirname(base_path).downcase, File.basename(path))
      end
    end

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
      manifest_package = response["packages"]&.map { |item| Worker::Api::LegacyManifestPackage.new(item) }&.first

      if manifest_package.nil? || manifest_package.error?
        pp manifest_package
        abort_task!("Failed to fetch package details for manifest #{version}")
      end

      # FIXME: check if locally downloaded manifest is still valid, if present.
      file_path = package_cache_path(manifest_package)

      create_directory(File.dirname(file_path))

      result = if manifest_package.download_url
        @worker.w3dhub_api.download(manifest_package.download_url, path: file_path)
      else
        # TODO xD
        @worker.w3dhub_api.fetch_package("TODO")
      end

      if result.okay?
        return Worker::Api::LegacyManifest.new(package_cache_path(manifest_package))
      else
        pp result
        abort_task!("Failed to fetch manifest #{version}")
      end
    end

    def apply_patch(manifest_file, package)
      Tempfile.create do |f|
        package_path = package_cache_path(package)

        puts "unpacking patch..."
        unzip(package_path, f.path)

        puts "reading patch data.."
        patch_mix = W3DHubLauncher::WWMix.new(path: f.path)
        raise patch_mix.error_reason unless patch_mix.load

        patch_entry = patch_mix.entries.find { |e| e.name.casecmp?(".w3dhub.patch") || e.name.casecmp?(".bhppatch") }
        patch_entry.read
        # "remove" patch meta file from patch before copying patch data
        patch_mix.entries.delete(patch_entry)

        patch_info = JSON.parse(patch_entry.blob)

        puts "loading target mix metadata... (#{normalize_path(manifest_file.name)})"
        target_mix = W3DHubLauncher::WWMix.new(path: normalize_path(manifest_file.name))
        raise target_mix.error_reason unless target_mix.load

        patch_info["removedFiles"].each do |file|
          puts "removing file from target: #{file}"
          target_mix.entries.delete_if  { |e| e.name.casecmp?(file) }
        end

        patch_info["updatedFiles"].each do |file|
          puts "adding/updating file from target: #{file}"
          patch_mix.entries.each do |entry|
            target_mix.add_entry(entry: entry, replace: true)
          end
        end

        Tempfile.create do |temp|
          temp_mix = W3DHubLauncher::WWMix.new(path: temp.path, encrypted: target_mix.encrypted?)
          target_mix.entries.each { |e| temp_mix.add_entry(entry: e, replace: true) }
          raise temp_mix.error_reason unless temp_mix.save

          puts "copying file..."
          FileUtils.cp(temp.path, normalize_path(manifest_file.name))
        end
      end
    end

    def unzip(zip_path, output_path = nil)
      stream = Zip::InputStream.new(File.open(zip_path))

      while(entry = stream.get_next_entry)
        file_path = output_path || normalize_path(entry.name)

        next if ignored_file?(file_path)

        pp file_path

        create_directory(File.dirname(file_path)) unless output_path

        File.open(file_path, "wb") do |f|
          entry_stream = entry.get_input_stream

          while(chunk = entry_stream.read(4_194_304))
            f.write(chunk)
          end
        end

        add_to_file_index(file_path)
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
