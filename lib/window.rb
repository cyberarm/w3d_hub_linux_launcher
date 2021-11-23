class W3DHub
  class Window < CyberarmEngine::Window
    def setup
      self.caption = I18n.t(:app_name)

      Store[:server_list] = []
      Store[:settings] = Settings.new
      Store[:application_manager] = ApplicationManager.new

      Store.settings.save_settings

      push_state(W3DHub::States::Boot)
    end

    def update
      super

      Store.application_manager.start_next_available_task if Store.application_manager.idle?
      current_state.update_application_manager_status if current_state.is_a?(States::Interface)
    end

    def close
      Store.settings.save_settings

      super if Store.application_manager.idle?
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