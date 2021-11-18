class W3DHub
  class ApplicationManager
    class Task
      include CyberarmEngine::Common

      attr_reader :app_id, :release_channel, :application, :channel,
                  :total_bytes_to_download, :bytes_downloaded, :packages_to_download,
                  :manifests

      def initialize(app_id, release_channel)
        @app_id = app_id
        @release_channel = release_channel

        @task_state = :not_started # :not_started, :running, :paused, :halted, :complete, :failed

        @application = window.applications.games.find { |g| g.id == app_id }
        @channel = @application.channels.find { |c| c.name == release_channel }

        @packages_to_download = []
        @total_bytes_to_download = -1
        @bytes_downloaded = -1

        @manifests = []

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
      #        prevent the UI for locking up while doing computation heavy work, i.e building
      #        list of packages to download
      def start
        @task_state = :running

        Thread.new do
          status = execute_task

          @task_state = :failed unless status
          @task_state = :complete unless @task_state == :failed

          hide_application_taskbar if @task_state == :failed
          send_message_dialog(:failure, "Task #{type.inspect} failed for #{@application.name}", @task_failure_reason) if @task_state == :failed
        end
      end

      def execute_task; end

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
        @task_failure_reason = "Failed: #{reason}"
      end

      def run_on_main_thread(block)
        window.main_thread_queue << block
      end

      def send_message_dialog(type, title, message)
        run_on_main_thread(
          proc do
            window.push_state(W3DHub::States::MessageDialog, type: type, title: title, message: message)
          end
        )
      end

      def update_application_taskbar(message, status, progress)
        run_on_main_thread(
          proc do
            window.current_state.show_application_taskbar
            window.current_state.update_application_taskbar(message, status, progress)
          end
        )
      end

      def update_download_manager_task(checksum, message, status, progress)
        run_on_main_thread(
          proc do
            window.current_state.update_download_manager_task(checksum, message, status, progress)
          end
        )
      end

      def hide_application_taskbar
        run_on_main_thread(
          proc do
            window.current_state.hide_application_taskbar
          end
        )
      end

      ###############
      # Tasks/Steps #
      ###############

      def fetch_manifests
        if fetch_manifest("games", app_id, "manifest.xml", @channel.current_version)
          manifest = load_manifest("games", app_id, "manifest.xml", @channel.current_version)
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
        packages = []

        manifests.reverse.each do |manifest|
          puts "#{manifest.game}-#{manifest.type}: #{manifest.version} (#{manifest.base_version})"

          manifest.files.each do |file|
            next if file.removed? # No package data

            if file.patch?
              fail!("#{@application.name} requires patches. Patching is not yet supported.")
              break
            end

            next if packages.detect do |pkg|
              pkg.category == "games" &&
              pkg.subcategory == @app_id &&
              pkg.name == file.package &&
              pkg.version == manifest.version
            end

            packages.push(Api::Package.new(
                { category: "games", subcategory: @app_id, name: file.package, version: manifest.version }
              )
            )
          end

          # TODO: Dependencies
        end

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
          @packages_to_download = []

          update_application_taskbar("Downloading #{@application.name}...", "Verifying local packages...", 0.0)

          package_details.each do |pkg|
            unless verify_package(pkg)
              @packages_to_download << pkg
            end
          end

          @total_bytes_to_download = @packages_to_download.sum { |pkg| pkg.size - pkg.custom_partially_valid_at_bytes }
          @bytes_downloaded = 0

          @packages_to_download.each do |pkg|
            package_bytes_downloaded = 0

            package_fetch(pkg) do |chunk, remaining_bytes, total_bytes|
              @bytes_downloaded += chunk.to_s.length
              package_bytes_downloaded += chunk.to_s.length

              update_application_taskbar(
                "Downloading #{@application.name}...",
                "#{W3DHub.format_size(@bytes_downloaded)} / #{W3DHub.format_size(@total_bytes_to_download)}",
                @bytes_downloaded.to_f / @total_bytes_to_download
              )

              update_download_manager_task(
                pkg.checksum,
                pkg.name,
                "#{W3DHub.format_size(package_bytes_downloaded)} / #{W3DHub.format_size(total_bytes)}",
                package_bytes_downloaded.to_f / total_bytes
              )
            end
          end
        else
          puts "FAILED!"
          pp package_details
        end

      end

      def verify_packages(packages)
      end

      def unpack_packages(packages)
      end

      def create_wine_prefix
      end

      def install_dependencies(packages)
      end

      def mark_application_installed
        puts "#{@app_id} has been installed."
      end

      #############
      # Functions #
      #############

      def fetch_manifest(category, subcategory, name, version, &block)
        # Check for and integrity of local manifest
        package = Api.package_details([{ category: category, subcategory: subcategory, name: name, version: version }])

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
        puts "Downloading: #{package.category}:#{package.subcategory}:#{package.name}-#{package.version}"

        Api.package(package) do |chunk, remaining_bytes, total_bytes|
          # Store progress somewhere
          # Kernel.puts "#{name}-#{version}: #{(remaining_bytes.to_f / total_bytes).round}%"

          block&.call(chunk, remaining_bytes, total_bytes)
        end
      end

      def verify_package(package, &block)
        puts "Verifying: #{package.category}:#{package.subcategory}:#{package.name}-#{package.version}"

        digest = Digest::SHA256.new
        path = Cache.package_path(package.category, package.subcategory, package.name, package.version)

        return false unless File.exists?(path)

        file_size = File.size(path)
        puts "    File size: #{file_size}"
        chunk_size = package.checksum_chunk_size

        File.open(path) do |f|
          package.checksum_chunks.each do |chunk_start, checksum|
            chunk_start = Integer(chunk_start.to_s)

            read_length = chunk_size
            read_length = file_size - chunk_start if chunk_start + chunk_size > file_size

            break if file_size - chunk_start < 0

            f.seek(chunk_start)

            chunk = f.read(read_length)
            digest.update(chunk)

            if Digest::SHA256.new.hexdigest(chunk).upcase == checksum.upcase
              valid_at = chunk_start + read_length
              puts "    Passed chunk: #{chunk_start}"
              # package.partially_valid_at_bytes = valid_at
              package.partially_valid_at_bytes = chunk_start
            else
              puts "    FAILED chunk: #{chunk_start}"
              break
            end
          end
        end

        digest.hexdigest.upcase == package.checksum.upcase
      end

      def load_manifest(category, subcategory, name, version)
        Manifest.new(category, subcategory, name, version)
      end
    end
  end
end