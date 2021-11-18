class W3DHub
  class States
    class MessageDialog < CyberarmEngine::GuiState
      def setup
        window.show_cursor = true

        theme(W3DHub::THEME)

        background 0xee_444444

        stack(width: 1.0, height: 1.0, margin: 128, padding: 8, background: 0xee_222222) do
          flow(width: 1.0, height: 0.06) do
            image "#{GAME_ROOT_PATH}/media/ui_icons/warning.png", width: 0.04, align: :center, color: 0xff_ff8800

            tagline "<b>#{@options[:title]}</b>", width: 0.9, text_align: :center
          end

          para @options[:message], width: 1.0, height: 0.7, padding: 8

          button "Okay", width: 1.0, margin_top: 64 do
            pop_state
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
