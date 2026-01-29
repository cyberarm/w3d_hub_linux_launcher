class W3DHub
  class ApplicationManager
    class Task
      LOG_TAG = "W3DHub::ApplicationManager::Task".freeze

      # Task failed
      EVENT_FAILURE = -1
      # Task started, show application taskbar
      EVENT_START = 0
      # Task completed successfully
      EVENT_SUCCESS = 1
      # Task progress
      EVENT_PROGRESS = 2
      # List of packages this task will be working over
      EVENT_PACKAGE_LIST = 3
      # Update a package's status: verifying, downloading, unpacking, patching
      EVENT_PACKAGE_STATUS = 4

      Context = Data.define(
        :task_id,
        :app_type,
        :app_id,
        :channel_id,
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

      def initialize(context:)
        @context = context

        @state = :not_started

        # remember all case insensitive file paths
        @cache_file_paths = {}

        @failure = false
        @failure_reason = ""
      end

      def setup
      end

      def fail!(reason: "")
        @failure = true

        Ractor.current.send(
          MessageEvent.new(
            context.task_id,

          )
        )
      end

      def failed?
        @failure
      end

      def send_status_update(type)
      end

      def send_package_list()
      end

      def send_task_result
        Ractor.current.send(
          MessageEvent.new(
            context.task_id,
            @failure ? EVENT_FAILURE : EVENT_SUCCESS,
            nil,
            @failure_reason
          )
        )
      end

      def type
        raise NotImplementedError
      end

      def start
        execute_task

        send_task_result
      end

      # returns true on success and false on failure
      def execute_task
      end

      ###########################
      ## High level task steps ##
      ###########################

      # Quick checks before network and computational work starts
      def fail_fast!
        # can read/write to destination

        fail!("FAIL FAST: Insufficient disk space available.") unless disk_space_available?
      end

      def fetch_manifests
        result = CyberarmEngine::Result.new

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

      def fetch_package(version, name)
        result = CyberarmEngine::Result.new

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
    end
  end
end
