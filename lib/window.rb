class W3DHub
  class Window < CyberarmEngine::Window
    attr_reader :settings, :application_manager
    attr_accessor :account, :service_status, :applications

    def setup
      self.caption = I18n.t(:app_name)

      @settings = Settings.new
      @application_manager = ApplicationManager.new

      @settings.save_settings

      push_state(W3DHub::States::Boot)
    end

    def update
      super

      @application_manager.start_next_available_task if @application_manager.idle?
      current_state.update_application_manager_status if current_state.is_a?(States::Interface)
    end

    def close
      @settings.save_settings

      super if @application_manager.idle?
    end

    def main_thread_queue
      if current_state.is_a?(W3DHub::States::Interface)
        current_state.main_thread_queue
      else
        warn "Task will not be run for:"
        warn caller
        []
      end
    end
  end
end