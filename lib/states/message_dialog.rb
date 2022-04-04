class W3DHub
  class States
    class MessageDialog < CyberarmEngine::GuiState
      def setup
        window.show_cursor = true

        theme(W3DHub::THEME)

        background 0xee_444444

        flow(width: 1.0, height: 1.0) do
          flow(fill: true, height: 1.0)

          stack(width: 1.0, height: 1.0, max_width: MAX_PAGE_WIDTH, margin: 128, background: 0xee_222222) do
            flow(width: 1.0, height: 32, padding: 8) do
              background 0x88_000000

              image "#{GAME_ROOT_PATH}/media/ui_icons/warning.png", width: 32, align: :center, color: 0xff_ff8800

              tagline "<b>#{@options[:title]}</b>", width: 0.9, text_align: :center
            end

            stack(width: 1.0, fill: true, padding: 16) do
              para @options[:message], width: 1.0
            end

            stack(width: 1.0, height: 40, padding: 8) do
              button "Okay", width: 1.0 do
                pop_state
              end
            end
          end

          flow(fill: true, height: 1.0)
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
