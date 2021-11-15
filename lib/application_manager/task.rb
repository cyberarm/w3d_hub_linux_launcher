class W3DHub
  class ApplicationManager
    class Task
      include CyberarmEngine::Common

      attr_reader :app_id, :release_channel

      def initialize(app_id, release_channel)
        @app_id = app_id
        @release_channel = release_channel

        @task_state = :not_started # :not_started, :running, :paused, :halted, :complete, :failed
        @task_steps = []
        @task_step_index = 0

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
          @task_steps.each_with_index do |step, i|
            break if @task_state == :halted

            @task_step_index = i

            success = step.start

            failure!(step) unless success
            break unless success
          end

          @task_state = :complete unless @task_state == :failed
        end
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

      def failure!(step)
        @task_state = :failed
        @task_failure_reason = "Failed to complete: \"#{step.name}\" due to an error: #{step.error}"
      end

      def run_on_main_thread(block)
        window.main_thread_queue << block
      end

      def add_step(name, method, *args)
        @task_steps << Step.new(name, method, args)
      end

      def fetch_manifests
        # Do stuff

        package_fetch("games", app_id, "manifest.xml", @channel.version)
      end

      def package_fetch(category, subcategory, package, version)
      end

      class Step
        attr_reader :name

        def initialize(name, method, args)
          @name = name
          @method = method
          @args = args

          @step_state = :not_started # :not_started, :running, :paused, :halted, :complete, :failed
          @success = false
        end

        def start
          # do work
          # ensure that a boolean value is returned
        ensure
          @success
        end

        def pause
        end

        def stop
        end

        def status
          nil
        end

        def progress
          0.0
        end

        def total_work
          1.0
        end

        # data to pass on to next step(s)
        def result
          nil
        end
      end
    end
  end
end