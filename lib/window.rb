class W3DHub
  class Window < CyberarmEngine::Window
    attr_reader :settings, :application_manager
    attr_accessor :account, :service_status, :applications

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
  end
end