class W3DHub
  class States
    class Dialog < CyberarmEngine::GuiState
      def draw
        previous_state&.draw

        Gosu.flush

        super
      end

      def update
        super

        return unless window.current_state == self

        window.states.reverse.each do |state|
          # Don't update ourselves, forever
          next if state == self && state.is_a?(CyberarmEngine::GuiState)

          state.update
        end
      end
    end
  end
end
