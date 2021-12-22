class W3DHub
  class Window < CyberarmEngine::Window
    def setup
      self.caption = I18n.t(:app_name)

      Store[:server_list] = []
      Store[:settings] = Settings.new
      Store[:application_manager] = ApplicationManager.new

      Store.settings.save_settings

      begin
        I18n.locale = Store.settings[:language]
      rescue I18n::InvalidLocale
        I18n.locale = :en
      end

      @last_interaction = Gosu.milliseconds
      @last_mouse_position = CyberarmEngine::Vector.new(mouse_x, mouse_y)

      # push_state(W3DHub::States::DemoInputDelay)
      push_state(W3DHub::States::Boot)
    end

    def update
      super

      Store.application_manager.start_next_available_task if Store.application_manager.idle?
      manage_update_interval
    end

    def button_down(id)
      super

      @last_interaction = Gosu.milliseconds
    end

    def close
      Store.settings.save_settings

      super if Store.application_manager.idle?
    end

    def manage_update_interval
      return # Wait for #gain/lose_focus callbacks to be merged into Gosu

      @last_interaction = Gosu.milliseconds if @last_mouse_position.x != mouse_x || @last_mouse_position.y != mouse_y
      @last_interaction = Gosu.milliseconds if mouse_x.between?(0, width) && mouse_y.between?(0, height)

      self.update_interval = if Gosu.milliseconds - @last_interaction >= 1_000
                               1000.0 / 10
                             else
                               1000.0 / 60
                             end

      @last_mouse_position.x = mouse_x
      @last_mouse_position.y = mouse_y
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