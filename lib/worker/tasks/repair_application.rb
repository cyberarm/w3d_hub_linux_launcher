module W3DHubLauncher
  class Task
    class RepairApplication < InstallApplication
      def setup
        super

        @task_verb = "Repairing".freeze
      end
    end
  end
end
