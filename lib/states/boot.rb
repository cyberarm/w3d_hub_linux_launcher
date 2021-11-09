class W3DHub
  class States
    class Boot < CyberarmEngine::GuiState
      def setup
        background 0xff_252525

        @fraction = 0.0
        @w3dhub_logo = get_image("#{GAME_ROOT_PATH}/media/icons/w3dhub.png")

        stack(width: 1.0, height: 1.0) do
          stack(width: 1.0, height: 0.925) do
          end

          @progressbar = progress height: 0.025, width: 1.0

          flow(width: 1.0, height: 0.05, padding_left: 16, padding_right: 16, padding_bottom: 8, padding_top: 8) do
            caption "Checking for updates...", width: 0.5
            inscription "W3D Hub Launcher 0.14.0.0", width: 0.5, text_align: :right
          end
        end
      end

      def draw
        @w3dhub_logo.draw_rot(window.width / 2, window.height / 2, 32)

        super
      end

      def update
        super

        @fraction += 1.0 * window.dt

        @progressbar.value = @fraction

        push_state(States::Interface) if @progressbar.value >= 1.0
      end
    end
  end
end
