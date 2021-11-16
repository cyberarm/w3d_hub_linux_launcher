class W3DHub
  class ApplicationManager
    class Task
      include CyberarmEngine::Common

      attr_reader :app_id, :release_channel

      def initialize(app_id, release_channel)
        @app_id = app_id
        @release_channel = release_channel

        @task_state = :not_started # :not_started, :running, :paused, :halted, :complete, :failed

        @application = window.applications.games.find { |g| g.id == app_id }
        @channel = @application.channels.find { |c| c.name == release_channel }

        setup
      end

      def setup
      end

      def state
        @task_state
      end

      # Start task, inside its own thread
      def start
        @task_state = :running

        Thread.new do
          status = execute_task

          @task_state = :failed unless status
          @task_state = :complete unless @task_state == :failed
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

      def fetch_manifests
        manifests = []

        if fetch_manifest("games", app_id, "manifest.xml", @channel.current_version)
          manifest = load_manifest("games", app_id, "manifest.xml", @channel.current_version)
          manifests << manifest

          until(manifest.full?)
            fetch_manifest("games", app_id, "manifest.xml", manifest.base_version)
            manifest = load_manifest("games", app_id, "manifest.xml", manifest.base_version)
            manifests << manifest
          end
        end

        manifests
      end

      def build_package_list(manifests)
        packages = []

        manifests.reverse.each do |manifest|
          puts "#{manifest.game}-#{manifest.type}: #{manifest.version} (#{manifest.base_version})"

          manifest.files.each do |file|
            next if file.removed? # No package data

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
          package_details.each do |pkg|
            unless verify_package(pkg, pkg.category, pkg.subcategory, pkg.name, pkg.version)
              package_fetch(pkg.category, pkg.subcategory, pkg.name, pkg.version)
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

      def fetch_manifest(category, subcategory, name, version)
        # Check for and integrity of local manifest
        if File.exist?(Cache.package_path(category, subcategory, name, version))
          package = Api.package_details([{ category: category, subcategory: subcategory, name: name, version: version }])
          verified = verify_package(package, category, subcategory, name, version)

          # download manifest if not valid
          package_fetch(category, subcategory, name, version) unless verified
          true if verified
        else
          # download manifest if not cached
          package_fetch(category, subcategory, name, version)
        end
      end

      def package_fetch(category, subcategory, name, version)
        puts "Downloading: #{category}:#{subcategory}:#{name}-#{version}"

        Api.package(category, subcategory, name, version) do |chunk, remaining_bytes, total_bytes|
          # Store progress somewhere
          # Kernel.puts "#{name}-#{version}: #{(remaining_bytes.to_f / total_bytes).round}%"
        end
      end

      def verify_package(package, category, subcategory, name, version)
        puts "Verifying: #{category}:#{subcategory}:#{name}-#{version}"

        digest = Digest::SHA256.new
        path = Cache.package_path(category, subcategory, name, version)

        return false unless File.exists?(path)

        file_size = File.size(path)
        puts "    File size: #{file_size}"
        chunk_size = 128_000_000 if file_size >= 32_000_000
        chunk_size ||= 32_000_000

        File.open(path) do |f|
          while (chunk = f.read(32_000_000))
            digest.update(chunk)
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