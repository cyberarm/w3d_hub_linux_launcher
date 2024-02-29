class W3DHub
  class States
    class ConfirmDialog < Dialog
      def setup
        window.show_cursor = true

        theme(W3DHub::THEME)

        background 0xaa_525252

        stack(width: 1.0, max_width: 720, height: 1.0, max_height: 480, v_align: :center, h_align: :center, background: 0xee_222222) do
          flow(width: 1.0, height: 48, padding: 8) do
            background 0x88_000000

            image "#{GAME_ROOT_PATH}/media/ui_icons/question.png", height: 1.0, align: :center, color: 0xaa_ff0000

            title "<b>#{@options[:title]}</b>", width: 0.9, text_align: :center, font: BOLD_FONT
          end

          stack(width: 1.0, fill: true, padding: 16) do
            para @options[:message], width: 1.0, text_align: :center
          end

          flow(width: 1.0, height: 46, padding: 8) do
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
    end
  end
end
