class W3DHub
  class States
    class ConfirmDialog < CyberarmEngine::GuiState
      def setup
        window.show_cursor = true

        theme(W3DHub::THEME)

        background 0xee_444444

        stack(width: 1.0, max_width: 720, height: 1.0, max_height: 480, v_align: :center, h_align: :center, background: 0xee_222222) do
          flow(width: 1.0, height: 0.1, padding: 8) do
            background 0x88_000000

            image "#{GAME_ROOT_PATH}/media/ui_icons/question.png", width: 0.04, align: :center, color: 0xaa_ff0000

            tagline "<b>#{@options[:title]}</b>", width: 0.9, text_align: :center
          end

          stack(width: 1.0, height: 0.78, padding: 16) do
            para @options[:message], width: 1.0, text_align: :center
          end

          flow(width: 1.0, height: 0.1, padding: 8) do
            button "Cancel", width: 0.25 do
              pop_state
              @options[:cancel_callback]&.call
            end

            stack(width: 0.5)

            button "Confirm", width: 0.25, background: 0xff_800000, hover: { background: 0xff_d00000 }, active: { background: 0xff_600000, color: 0xff_ffffff } do
              pop_state
              @options[:accept_callback]&.call
            end
          end
        end
      end

      def draw
        previous_state&.draw

        Gosu.flush

        super
      end
    end
  end
end
