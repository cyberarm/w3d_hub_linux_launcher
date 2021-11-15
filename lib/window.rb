class W3DHub
  class Window < CyberarmEngine::Window
    attr_reader :settings, :application_manager

    def setup
      self.caption = "#{W3DHub::NAME}"

      @settings = Settings.new
      @application_manager = ApplicationManager.new

      @settings.save_settings

      push_state(W3DHub::States::Boot)
    end

    def close
      @settings.save_settings

      super if @application_manager.idle?
    end

    def button_down(id)
      super

      self.borderless = !self.borderless? if id == Gosu::KB_F7
    end
  end
end
