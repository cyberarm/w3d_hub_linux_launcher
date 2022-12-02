class W3DHub
  class ApplicationManager
    class Task
      LOG_TAG = "W3DHub::ApplicationManager::Task".freeze

      class FailFast < RuntimeError
      end

      include CyberarmEngine::Common

      attr_reader :app_id, :release_channel, :application, :channel, :target_version,
                  :manifests, :packages, :files, :wine_prefix, :status

      def initialize(app_id, release_channel)
        @app_id = app_id
        @release_channel = release_channel

        @task_state = :not_started # :not_started, :running, :paused, :halted, :complete, :failed

        @application = Store.applications.games.find { |g| g.id == app_id }
        @channel = @application.channels.find { |c| c.id == release_channel }

        @target_version = type == :repairer ? Store.settings[:games][:"#{app_id}_#{@channel.id}"][:installed_version] : @channel.current_version

        @packages_to_download = []
        @total_bytes_to_download = -1
        @bytes_downloaded = -1

        @manifests = []
        @files = {}
        @packages = []

        @wine_prefix = nil

        @status = Status.new(application: @application, channel: channel) { update_interface_task_status }

        setup
      end

      def setup
      end

      def type
        raise NotImplementedError
      end

      def state
        @task_state
      end

      # Start task, inside its own thread
      # FIXME: Ruby 3 has parallelism now: Use a Ractor to do work on a seperate core to
      #        prevent the UI from locking up while doing computation heavy work, i.e building
      #        list of packages to download
      def start
        @task_state = :running

        Thread.new do
          # Sync do
            begin
              status = execute_task
            rescue FailFast
              # no-op
            rescue StandardError, ERRNO::EACCES => e
              status = false
              @task_failure_reason = e.message[0..512]

              logger.error(LOG_TAG) { "Task #{type.inspect} failed for #{@application.name}" }
              logger.error(LOG_TAG) { e }
            end

            # Force free some bytes
            GC.compact if GC.respond_to?(:compact)
            GC.start

            @task_state = :failed unless status
            @task_state = :complete unless @task_state == :failed

            hide_application_taskbar if @task_state == :failed
            send_message_dialog(:failure, "Task #{type.inspect} failed for #{@application.name}", @task_failure_reason) if @task_state == :failed && !@fail_silently
          # end
        end
      end

      def execute_task
      end

      # Suspend operation, if possible
      def pause
        @task_state = :paused if pauseable?
      end

      # Halt operation, if possible
      def stop
        @task_state = :halted if stoppable?
      end

      def pauseable?
        false
      end

      def stoppable?
        false
      end

      def complete?
        @task_state == :complete
      end

      def failed?
        @task_state == :failed
      end

      def failure_reason
        @task_failure_reason || ""
      end

      def fail!(reason = "")
        @task_state = :failed
        @task_failure_reason = reason.to_s

        hide_application_taskbar

        raise FailFast, @task_failure_reason
      end

      def fail_silently!
        @fail_silently = true
      end

      # Quick checks before network and computational work starts
      def fail_fast
        # Have write permissions to target directory
        path = Cache.install_path(@application, @channel)
        path = Store.settings[:app_install_dir] unless File.exist?(path)

        begin
          File.write("#{path}/___can_write.wlh", "")
          File.delete("#{path}/___can_write.wlh")

          Dir.mkdir("#{path}/__can_write")
          Dir.rmdir("#{path}/__can_write")
        rescue Errno::EACCES
          fail!("FAIL FAST: Cannot write to #{path}")
        end

        # FIXME: Check that there is enough disk space

        # TODO: Is missing wine/proton really a failure condition?
        # Wine present?
        if W3DHub.unix?
          wine_present = W3DHub.command("which #{Store.settings[:wine_command]}")
          fail!("FAIL FAST: `which #{Store.settings[:wine_command]}` command failed, wine is not installed. Will be unable to create prefixes or launch games.") unless wine_present
        end
      end

      def run_on_main_thread(block)
        Store.main_thread_queue << block
      end

      def send_message_dialog(type, title, message)
        run_on_main_thread(
          proc do
            window.push_state(W3DHub::States::MessageDialog, type: type, title: title, message: message)
          end
        )
      end

      def update_interface_task_status
        run_on_main_thread(
          proc do
            States::Interface.instance&.interface_task_update_pending = self
          end
        )
      end

      def show_application_taskbar
        run_on_main_thread(
          proc do
            States::Interface.instance&.show_application_taskbar
          end
        )
      end

      def hide_application_taskbar
        run_on_main_thread(
          proc do
            States::Interface.instance&.hide_application_taskbar
          end
        )
      end

      ###############
      # Tasks/Steps #
      ###############

      def fetch_manifests
        @status.operations.clear
        @status.label = "Downloading #{@application.name}..."
        @status.value = "Fetching manifests..."
        @status.progress = 0.0

        @status.step = :fetching_manifests

        if fetch_manifest("games", app_id, "manifest.xml", @target_version)
          manifest = load_manifest("games", app_id, "manifest.xml", @target_version)
          @manifests << manifest

          until(manifest.full?)
            fetch_manifest("games", app_id, "manifest.xml", manifest.base_version)
            manifest = load_manifest("games", app_id, "manifest.xml", manifest.base_version)
            manifests << manifest
          end
        end

        @manifests
      end

      def build_package_list(manifests)
        @status.operations.clear
        @status.label = "Downloading #{@application.name}..."
        @status.value = "Building package list..."
        @status.progress = 0.0

        @status.step = :build_package_list

        packages = []

        manifests.reverse.each do |manifest|
          logger.info(LOG_TAG) { "#{manifest.game}-#{manifest.type}: #{manifest.version} (#{manifest.base_version})" }

          manifest.files.each do |file|
            @files["#{file.name}:#{manifest.version}"] = file

            next if file.removed? # No package data

            # if file.patch?
            #   fail!("#{@application.name} requires patches. Patching is not yet supported.")
            #   break
            # end

            next if packages.detect do |pkg|
              pkg.category == "games" &&
              pkg.subcategory == @app_id &&
              pkg.name == file.package &&
              pkg.version == manifest.version
            end

            packages.push(
              Api::Package.new(
                { category: "games", subcategory: @app_id, name: file.package, version: manifest.version }
              )
            )

            packages.last.is_patch = file if file.patch?
          end

          # TODO: Dependencies
        end

        packages
      end

      def verify_files(manifests, packages)
        @status.operations.clear
        @status.label = "Downloading #{@application.name}..."
        @status.value = "Verifying installed files..."
        @status.progress = 0.0

        @status.step = :verify_files

        path = Cache.install_path(@application, @channel)
        accepted_files = {}
        rejected_files = []

        file_count = manifests.map { |m| m.files.count }.sum
        processed_files = 0

        folder_exists = File.directory?(path)

        manifests.each do |manifest|
          break unless folder_exists

          manifest.files.each do |file|
            safe_file_name = file.name.gsub("\\", "/")
            # Fix borked Data -> data 'cause Windows don't care about capitalization
            safe_file_name.sub!("Data/", "data/")

            file_path = "#{path}/#{safe_file_name}"

            processed_files += 1
            @status.progress = processed_files.to_f / file_count

            next if file.removed_since
            next if accepted_files.key?(safe_file_name)

            unless File.exist?(file_path)
              rejected_files << { file: file, manifest_version: manifest.version }
              logger.info(LOG_TAG) { "[#{manifest.version}] File missing: #{file_path}" }
              next
            end

            digest = Digest::SHA256.new
            f = File.open(file_path)

            while (chunk = f.read(32_000_000))
              digest.update(chunk)
            end

            f.close

            logger.info(LOG_TAG) { file.inspect } if file.checksum.nil?

            if digest.hexdigest.upcase == file.checksum.upcase
              accepted_files[safe_file_name] = manifest.version
              logger.info(LOG_TAG) { "[#{manifest.version}] Verified file: #{file_path}" }
            else
              rejected_files << { file: file, manifest_version: manifest.version }
              logger.info(LOG_TAG) { "[#{manifest.version}] File failed Verification: #{file_path}" }
            end
          end
        end

        logger.info(LOG_TAG) { "#{rejected_files.count} missing or corrupt files" }

        selected_packages = []
        selected_packages_hash = {}

        rejected_files.each do |hash|
          next if selected_packages_hash["#{hash[:file].package}_#{hash[:manifest_version]}"]

          package = packages.find { |pkg| pkg.name == hash[:file].package && pkg.version == hash[:manifest_version] }

          if package
            selected_packages_hash["#{hash[:file].package}_#{hash[:manifest_version]}"] = true
            selected_packages << package
          else
            raise "missing package: #{hash[:file].package}:#{hash[:manifest_version]} in fetched packages list!"
          end
        end

        # Removed packages that don't need to be fetched or processed
        packages.delete_if { |package| !selected_packages.find { |pkg| pkg == package } } if folder_exists

        packages
      end

      def fetch_packages(packages)
        hashes = packages.map do |pkg|
          {
            category: pkg.category,
            subcategory: pkg.subcategory,
            name: "#{pkg.name}.zip",
            version: pkg.version
          }
        end

        package_details = Api.package_details(hashes)

        if package_details
          @packages = [package_details].flatten
          @packages.each do |rich|
            package = packages.find do |pkg|
              pkg.category == rich.category &&
              pkg.subcategory == rich.subcategory &&
              "#{pkg.name}.zip" == rich.name &&
              pkg.version == rich.version
            end

            package.instance_variable_set(:"@name", rich.name)
            package.instance_variable_set(:"@size", rich.size)
            package.instance_variable_set(:"@checksum", rich.checksum)
            package.instance_variable_set(:"@checksum_chunk_size", rich.checksum_chunk_size)
            package.instance_variable_set(:"@checksum_chunks", rich.checksum_chunks)
          end

          @packages_to_download = []

          @status.label = "Downloading #{@application.name}..."
          @status.value = "Verifying local packages..."
          @status.progress = 0.0

          package_details.each do |pkg|
            @status.operations[:"#{pkg.checksum}"] = Status::Operation.new(
              label: pkg.name,
              value: "Pending...",
              progress: 0.0
            )
          end

          @status.step = :prefetch_verifying_packages

          package_details.each_with_index.each do |pkg, i|
            operation = @status.operations[:"#{pkg.checksum}"]

            if verify_package(pkg)
              operation.value = "Verified"
              operation.progress = 1.0
            else
              @packages_to_download << pkg

              operation.value = "#{W3DHub.format_size(pkg.custom_partially_valid_at_bytes)} / #{W3DHub.format_size(pkg.size)}"
              operation.progress = pkg.custom_partially_valid_at_bytes.to_f / pkg.size
            end

            @status.progress = i.to_f / package_details.count

            update_interface_task_status
          end

          @status.operations.delete_if { |key, o| o.progress >= 1.0 }

          @status.step = :fetch_packages

          @total_bytes_to_download = @packages_to_download.sum { |pkg| pkg.size - pkg.custom_partially_valid_at_bytes }
          @bytes_downloaded = 0

          pool = Pool.new(workers: Store.settings[:parallel_downloads])

          @packages_to_download.each do |pkg|
            pool.add_job Pool::Job.new( proc {
              package_bytes_downloaded = pkg.custom_partially_valid_at_bytes

              package_fetch(pkg) do |chunk, remaining_bytes, total_bytes|
                @bytes_downloaded += chunk.to_s.length
                package_bytes_downloaded += chunk.to_s.length

                @status.value = "#{W3DHub.format_size(@bytes_downloaded)} / #{W3DHub.format_size(@total_bytes_to_download)}"
                @status.progress = @bytes_downloaded.to_f / @total_bytes_to_download

                operation = @status.operations[:"#{pkg.checksum}"]
                operation.value = "#{W3DHub.format_size(package_bytes_downloaded)} / #{W3DHub.format_size(pkg.size)}"
                operation.progress = package_bytes_downloaded.to_f / pkg.size # total_bytes

                update_interface_task_status
              end
            })
          end

          pool.manage_pool
        else
          fail!("Failed to fetch package details")
        end
      end

      def verify_packages(packages)
      end

      def unpack_packages(packages)
        path = Cache.install_path(@application, @channel)
        logger.info(LOG_TAG) { "Unpacking packages in '#{path}'..." }
        Cache.create_directories(path, true)

        @status.operations.clear
        @status.label = "Installing #{@application.name}..."
        @status.value = "Unpacking..."
        @status.progress = 0.0

        packages.each do |pkg|
          # FIXME: can't add a new key into hash during iteration (RuntimeError)
          @status.operations[:"#{pkg.checksum}"] = Status::Operation.new(
            label: pkg.name,
            value: "Pending...",
            progress: 0.0
          )
        end

        @status.step = :unpacking

        i = -1
        packages.each do |package|
          i += 1

          status = if package.custom_is_patch
            @status.operations[:"#{package.checksum}"].value = "Patching..."
            @status.operations[:"#{package.checksum}"].progress = Float::INFINITY
            @status.progress = i.to_f / packages.count
            update_interface_task_status

            apply_patch(package, path)
          else
            @status.operations[:"#{package.checksum}"].value = "Unpacking..."
            @status.operations[:"#{package.checksum}"].progress = Float::INFINITY
            @status.progress = i.to_f / packages.count
            update_interface_task_status

            unpack_package(package, path)
          end

          if status
            @status.operations[:"#{package.checksum}"].value = package.custom_is_patch ? "Patched" : "Unpacked"
            @status.operations[:"#{package.checksum}"].progress = 1.0

            update_interface_task_status
          else
            logger.info(LOG_TAG) { "COMMAND FAILED!" }
            fail!("Failed to unpack #{package.name}")

            break
          end
        end
      end

      def create_wine_prefix
        if W3DHub.unix? && @wine_prefix
          # TODO: create a wine prefix if configured
          @status.operations.clear
          @status.label = "Installing #{@application.name}..."
          @status.value = "Creating wine prefix..."
          @status.progress = 0.0

          @status.step = :create_wine_prefix
        end
      end

      def install_dependencies(packages)
        # TODO: install dependencies
        @status.operations.clear
        @status.label = "Installing #{@application.name}..."
        @status.value = "Installing dependencies..."
        @status.progress = 0.0

        @status.step = :install_dependencies
      end

      def mark_application_installed
        Store.application_manager.installed!(self)

        @status.operations.clear
        @status.label = "Installed #{@application.name}"
        @status.value = ""
        @status.progress = 1.0

        @status.step = :mark_application_installed

        logger.info(LOG_TAG) { "#{@app_id} has been installed." }
      end

      #############
      # Functions #
      #############

      def fetch_manifest(category, subcategory, name, version, &block)
        # Check for and integrity of local manifest

        package = nil
        array = Api.package_details([{ category: category, subcategory: subcategory, name: name, version: version }])
        if array.is_a?(Array)
          package = array.first
        else
          fail!("Failed to fetch manifest package details!")
          return
        end

        if File.exist?(Cache.package_path(category, subcategory, name, version))
          verified = verify_package(package)

          # download manifest if not valid
          package_fetch(package) unless verified
          true if verified
        else
          # download manifest if not cached
          package_fetch(package)
        end
      end

      def package_fetch(package, &block)
        logger.info(LOG_TAG) { "Downloading: #{package.category}:#{package.subcategory}:#{package.name}-#{package.version}" }

        Api.package(package) do |chunk, remaining_bytes, total_bytes|
          block&.call(chunk, remaining_bytes, total_bytes)
        end
      end

      def verify_package(package, &block)
        logger.info(LOG_TAG) { "Verifying: #{package.category}:#{package.subcategory}:#{package.name}-#{package.version}" }

        digest = Digest::SHA256.new
        path = Cache.package_path(package.category, package.subcategory, package.name, package.version)

        return false unless File.exist?(path)

        operation = @status.operations[:"#{package.checksum}"]
          operation&.value = "Verifying..."

        file_size = File.size(path)
        logger.info(LOG_TAG) { "    File size: #{file_size}" }
        chunk_size = package.checksum_chunk_size
        chunks = package.checksum_chunks.size

        File.open(path) do |f|
          i = -1
          package.checksum_chunks.each do |chunk_start, checksum|
            i += 1
            operation&.progress = i.to_f / chunks
            update_interface_task_status

            chunk_start = Integer(chunk_start.to_s)

            read_length = chunk_size
            read_length = file_size - chunk_start if chunk_start + chunk_size > file_size

            break if (file_size - chunk_start).negative?

            f.seek(chunk_start)

            chunk = f.read(read_length)
            digest.update(chunk)

            if Digest::SHA256.new.hexdigest(chunk).upcase == checksum.upcase
              valid_at = chunk_start + read_length
              # logger.debug(LOG_TAG) { "    Passed chunk: #{chunk_start}" } # Only enable when deep diving to find a bug (VERBOSE)
              # package.partially_valid_at_bytes = valid_at
              package.partially_valid_at_bytes = chunk_start
            else
              logger.info(LOG_TAG) { "    FAILED chunk: #{chunk_start}" }
              break
            end
          end
        end

        digest.hexdigest.upcase == package.checksum.upcase
      end

      def load_manifest(category, subcategory, name, version)
        Manifest.new(category, subcategory, name, version)
      end

      def unpack_package(package, path)
        logger.info(LOG_TAG) { "    #{package.name}:#{package.version}" }
        package_path = Cache.package_path(package.category, package.subcategory, package.name, package.version)

        logger.info(LOG_TAG) { "      Unpacking package \"#{package_path}\" in \"#{path}\"" }

        return unzip(package_path, path)
      end

      def apply_patch(package, path)
        logger.info(LOG_TAG) { "    #{package.name}:#{package.version}" }
        package_path = Cache.package_path(package.category, package.subcategory, package.name, package.version)
        temp_path = "#{Store.settings[:package_cache_dir]}/temp"
        manifest_file = package.custom_is_patch

        Cache.create_directories(temp_path, true)

        logger.info(LOG_TAG) { "      Unpacking patch \"#{package_path}\" in \"#{temp_path}\"" }
        unzip(package_path, temp_path)

        # Fix borked Data -> data 'cause Windows don't care about capitalization
        safe_file_name = "#{manifest_file.name.sub('Data/', 'data/')}"

        logger.info(LOG_TAG) { "      Loading #{temp_path}/#{safe_file_name}.patch..." }
        patch_mix = W3DHub::Mixer::Reader.new(file_path: "#{temp_path}/#{safe_file_name}.patch", ignore_crc_mismatches: false)
        patch_info = JSON.parse(patch_mix.package.files.find { |f| f.name == ".w3dhub.patch" || f.name == ".bhppatch" }.data, symbolize_names: true)

        logger.info(LOG_TAG) { "      Loading #{path}/#{safe_file_name}..." }
        target_mix = W3DHub::Mixer::Reader.new(file_path: "#{path}/#{safe_file_name}", ignore_crc_mismatches: false)

        logger.info(LOG_TAG) { "      Removing files..." } if patch_info[:removedFiles].size.positive?
        patch_info[:removedFiles].each do |file|
          logger.debug(LOG_TAG) { "        #{file}" }
          target_mix.package.files.delete_if { |f| f.name == file }
        end

        logger.info(LOG_TAG) { "      Adding/Updating files..." } if patch_info[:updatedFiles].size.positive?
        patch_info[:updatedFiles].each do |file|
          logger.debug(LOG_TAG) { "        #{file}" }

          patch = patch_mix.package.files.find { |f| f.name == file }
          target = target_mix.package.files.find { |f| f.name == file }

          if target
            target_mix.package.files[target_mix.package.files.index(target)] = patch
          else
            target_mix.package.files << patch
          end
        end

        logger.info(LOG_TAG) { "      Writing updated #{path}/#{safe_file_name}..." } if patch_info[:updatedFiles].size.positive?
        W3DHub::Mixer::Writer.new(file_path: "#{path}/#{safe_file_name}", package: target_mix.package, memory_buffer: true)

        FileUtils.remove_dir(temp_path)

        true
      end

      def unzip(package_path, path)
        stream = Zip::InputStream.new(File.open(package_path))

        while (entry = stream.get_next_entry)

          safe_file_name = entry.name.gsub("\\", "/")
          # Fix borked Data -> data 'cause Windows don't care about capitalization
          safe_file_name.sub!("Data/", "data/")

          dir_path = "#{path}/#{File.dirname(safe_file_name)}"
          unless dir_path.end_with?("/.") || Dir.exist?(dir_path)
            FileUtils.mkdir_p(dir_path)
          end

          File.open("#{path}/#{safe_file_name}", "wb") do |f|
            i = entry.get_input_stream
            
            while (chunk = i.read(32_000_000)) # Read up to ~32 MB per chunk
              f.write chunk
            end
          end
        end

        return true
      end
    end
  end
end
