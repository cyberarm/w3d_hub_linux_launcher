class W3DHub
  class ApplicationManager
    class Task
      LOG_TAG = "W3DHub::ApplicationManager::Task".freeze

      class AbortTaskExecutionError < StandardError
      end

      # Task failed
      EVENT_FAILURE = -1
      # Task started, show application taskbar
      EVENT_START = 0
      # Task completed successfully
      EVENT_SUCCESS = 1
      # Task progress
      EVENT_STATUS = 2
      # Subtask progress
      EVENT_STATUS_OPERATION = 3

      Context = Data.define(
        :task_id,
        :app_type,
        :application,
        :channel,
        :version,
        :target_path,
        :temp_path
      )

      MessageEvent = Data.define(
        :task_id,
        :type,
        :subtype,
        :data # { message: "Complete", progress: 0.1 }
      )

      attr_reader :context, :state
      attr_accessor :status

      def initialize(context:)
        @context = context

        @state = :not_started

        # remember all case insensitive file paths
        @cache_file_paths = {}

        @status = Status.new(application: context.application, channel: context.channel)

        @failure = false
        @failure_reason = ""
      end

      def setup
      end

      def fail!(reason: "")
        @state = :failed
        @failure = true
        @failure_reason = reason

        send_task_result

        raise AbortTaskExecutionError, reason
      end

      def failed?
        @failure
      end

      def send_status_update(type)
      end

      def send_package_list()
      end

      def send_task_result
        internal_send_message_event(
          failed? ? EVENT_FAILURE : EVENT_SUCCESS,
          nil,
          failed? ? { type: :failure, title: "Task Failed", message: @failure_reason } : nil
        )
      end

      def internal_send_message_event(type, subtype = nil, data = nil)
        Ractor.yield(
          MessageEvent.new(
            context.task_id,
            type,
            subtype,
            data
          )
        )
      end

      def type
        raise NotImplementedError
      end

      def start
        @state = :running

        # only mark task as running then return unless we're NOT running on the
        # main ractor. Task is deep copied when past to the ractor.
        return if Ractor.main?

        internal_send_message_event(EVENT_START)

        sleep 1

        execute_task

        sleep 1

        @state = failed? ? :failed : :complete

        send_task_result

        sleep 1
      rescue StandardError => e
        fail!(reason: "Fatal Error\n#{e}") unless e.is_a?(AbortTaskExecutionError)
      end

      # returns true on success and false on failure
      def execute_task
      end

      ###########################
      ## High level task steps ##
      ###########################

      # Quick checks before network and computational work starts
      def fail_fast!
        # is wine present?
        if W3DHub.unix?
          wine_present = W3DHub.command("which #{Store.settings[:wine_command]}")

          unless wine_present
            fail!(reason: "FAIL FAST: `which #{Store.settings[:wine_command]}` command failed, wine is not installed.\n\n"\
                          "Will be unable to launch game.\n\n"\
                          "Check wine options in launcher's settings.")
          end
        end

        # can read/write to destination
        # TODO

        # have enough disk space

        fail!(reason: "FAIL FAST: Insufficient disk space available.") unless disk_space_available?
      end

      def fetch_manifests(version)
        manifests = []
        result = Result.new

        while (package_result = fetch_package(category, subcategory, version, "manifest.xml"))
          break unless package_result.okay?

          path = package_file_path(category, subcategory, version, "manifest.xml")
          unless File.exist?(path) && !File.directory?(path)
            result.error = RuntimeError.new("File missing: #{path}")
            return result
          end

          manifest = LegacyManifest.new(path)

          manifests << manifest

          break unless manifest.patch?

          version = manifest.base_version
        end

        # return in oldest to newest order
        result.data = manifests.reverse
        result
      rescue StandardError => e # Async derives its errors from StandardError
        result.error = e
        result
      end

      def build_package_list
        result = CyberarmEngine::Result.new

        result
      end

      def remove_deleted_files
        result = CyberarmEngine::Result.new

        result
      end

      def verify_files
        result = CyberarmEngine::Result.new

        result
      end

      def fetch_packages
        result = CyberarmEngine::Result.new

        result
      end

      def verify_packages
        result = CyberarmEngine::Result.new

        result
      end

      def unpack_packages
        result = CyberarmEngine::Result.new

        result
      end

      def create_wine_prefix
        result = CyberarmEngine::Result.new

        result
      end

      def install_dependencies
        result = CyberarmEngine::Result.new

        result
      end

      def write_paths_ini
        result = CyberarmEngine::Result.new

        result
      end

      def mark_application_installed
      end

      ##########################
      ## Supporting functions ##
      ##########################

      # pestimistically estimate required disk space to:
      #   download, unpack/patch, and install.
      def disk_space_available?
        true
      end

      # returns JSON hash on success, false or nil on failure
      def fetch_package_details(packages)
        endpoint = "/apis/launcher/1/get-package-details"
        result = Result.new

        hash = {
          packages: packages.map do |h|
                      { category: h[:category], subcategory: h[:subcategory], name: h[:name], version: h[:version] }
                    end
        }

        body = URI.encode_www_form("data": JSON.dump(hash))

        Sync do
          Async::HTTP::Internet.post("#{UPSTREAM_ENDPOINT}#{endpoint}", CLIENT_FORM_ENCODED_HEADERS, body) do |response|
            if response.success?
              result.data = JSON.parse(response.read)
            else
              result.error = RuntimeError.new(response) # FIXME: have better error
            end
          rescue StandardError => e
            result.error = e
          end
        end

        result
      end

      def fetch_package(version, name)
        endpoint = "/apis/launcher/1/get-package"
        result = Result.new

        path = package_file_path(category, subcategory, version, name)
        headers = [
          ["user-agent", USER_AGENT],
          ["content-type", "application/x-www-form-urlencoded"],
          ["authorization", "Bearer #{FAKE_BEARER_TOKEN}"]
        ].freeze
        body = URI.encode_www_form("data": JSON.dump({ category: category, subcategory: subcategory, name: name, version: version }))

        Sync do
          Async::HTTP::Internet.post("#{UPSTREAM_ENDPOINT}#{endpoint}", headers, body) do |response|
            if response.success?
              create_directories(path)

              File.open(path, "wb") do |file|
                response.each do |chunk|
                  file.write(chunk)
                end
              end

              result.data = true
            end
          rescue StandardError => e
            result.error = e
          end
        end

        result
      end

      def verify_package(version, name)
        result = CyberarmEngine::Result.new

        result
      end

      def unpack_package(version, name)
        result = CyberarmEngine::Result.new

        result
      end

      # Apply all patches for a particular MIX file at once
      def apply_patches(package)
        result = CyberarmEngine::Result.new

        result
      end

      def apply_patch(target_mix, patch_mix)
        result = CyberarmEngine::Result.new

        result
      end

      def unzip(package_path)
        result = CyberarmEngine::Result.new

        result
      end

      def package_file_path(category, subcategory, version, name)
        "#{PACKAGE_CACHE}/"\
        "#{category}/"\
        "#{subcategory.to_s.empty? ? "" : "#{subcategory}/"}"\
        "#{version.to_s.empty? ? "" : "#{version}/"}"\
        "#{name}"
      end
    end
  end
end
