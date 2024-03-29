class W3DHub
  class Window < CyberarmEngine::Window
    def setup
      self.show_stats_plotter = false
      self.caption = I18n.t(:app_name)

      Store[:server_list] = []
      Store[:settings] = Settings.new
      Store[:application_manager] = ApplicationManager.new

      Store[:main_thread_queue] = []

      begin
        I18n.locale = Store.settings[:language]
      rescue I18n::InvalidLocale
        I18n.locale = :en
      end

      # push_state(W3DHub::States::DemoInputDelay)
      # push_state(W3DHub::States::Welcome)
      push_state(W3DHub::States::Boot)
      # push_state(W3DHub::States::DirectConnectDialog)
      # push_state(W3DHub::Asterisk::States::IRCProfileForm)
    end

    def update
      super

      Store.application_manager.start_next_available_task if Store.application_manager.idle?

      while (block = Store.main_thread_queue.shift)
        block&.call
      end

      # Manually sleep main thread so that the BackgroundWorker thread can be scheduled
      sleep(update_interval / 1000.0) if W3DHub::BackgroundWorker.busy? || Store.application_manager.busy?
    end

    def needs_redraw?
      states.any?(&:needs_repaint?)
    end

    def close
      Store.settings.save_settings

      current_state_options = current_state&.instance_variable_get(:@options)

      if Store.application_manager.idle? || current_state_options&.dig(:tag_as) == :closer
        super
      else
        push_state(
          States::ConfirmDialog,
          tag_as: :closer,
          title: I18n.t(:app_name),
          message: "An application management task is currently running, are you sure you want to exit?",
          accept_callback: method(:close!)
        )
      end
    end

    def main_thread_queue
      Store.main_thread_queue
    end
  end
end
