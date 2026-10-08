module W3DHubLauncher
  class Task
    class UpdateApplication < InstallApplication
      def setup
        super

        @task_verb = "Updating".freeze
      end
    end
  end
end
