class W3DHub
  class States
    class DemoInputDelay < CyberarmEngine::GameState
      def button_down(id)
        return unless id == Gosu::KB_SPACE

        pop_state # Erase self
        push_state(States::Boot)
      end
    end
  end
end
