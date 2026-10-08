module W3DHubLauncher
  class Task
    class RepairApplication < InstallApplication
      def setup
        super

        # User requested a repair, make sure everything is as it should be!
        @force_verification = true

        @task_verb = "Repairing".freeze
      end
    end
  end
end
