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
          execute_task

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
        Api.package(category, subcategory, name, version) do |chunk, remaining_bytes, total_bytes|
          # Store progress somewhere
        end
      end

      def verify_package(package, category, subcategory, name, version)
        digest = Digest::SHA256.new
        File.open(Cache.package_path(category, subcategory, name, version)) do |f|
          while (chunk = f.read(1_000_000))
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