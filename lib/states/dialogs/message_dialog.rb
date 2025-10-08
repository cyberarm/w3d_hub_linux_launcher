class W3DHub
  class States
    class MessageDialog < Dialog
      def setup
        window.show_cursor = true

        theme(W3DHub::THEME)

        background 0xaa_525252

        stack(width: 1.0, max_width: 720, height: 1.0, max_height: 480, v_align: :center, h_align: :center, background: 0xee_222222) do
          flow(width: 1.0, height: 36, padding: 8) do
            background 0x88_000000

            image "#{GAME_ROOT_PATH}/media/ui_icons/warning.png", height: 1.0, align: :center, color: 0xff_ff8800

            title "<b>#{@options[:title]}</b>", width: 0.9, text_align: :center, font: BOLD_FONT
          end

          stack(width: 1.0, fill: true, padding: 16) do
            para @options[:message], width: 1.0
          end

          stack(width: 1.0, height: 46, padding: 8) do
            button "Okay", width: 1.0 do
              pop_state
              @options[:accept_callback]&.call
            end
          end
        end
      end
    end
  end
end
