class W3DHub
  class States
    class PromptDialog < Dialog
      def setup
        window.show_cursor = true

        theme(W3DHub::THEME)

        background 0xaa_525252

        stack(width: 1.0, max_width: 720, height: 1.0, max_height: 256, v_align: :center, h_align: :center, background: 0xee_222222) do
          flow(width: 1.0, height: 36, padding: 8) do
            background 0x88_000000

            image "#{GAME_ROOT_PATH}/media/ui_icons/question.png", height: 1.0, align: :center, color: 0xff_ff8800

            title "<b>#{@options[:title]}</b>", fill: true, text_align: :center, font: BOLD_FONT
          end

          stack(width: 1.0, fill: true, padding: 16) do
            para @options[:message], width: 1.0
            @prompt_entry = edit_line @options[:prefill].to_s, margin_top: 24, width: 1.0, autofocus: true, focus: true, type: @options[:input_type] == :password ? :password : :text
          end

          flow(width: 1.0, height: 46, padding: 8) do
            button "Cancel", width: 0.25 do
              pop_state
              @options[:cancel_callback]&.call(@prompt_entry.value)
            end

            stack(fill: true)

            @accept_button = button "Accept", width: 0.25 do
              if @options[:valid_callback]&.call(@prompt_entry.value)
                pop_state
                @options[:accept_callback]&.call(@prompt_entry.value)
              end
            end
          end
        end

        @prompt_entry.subscribe(:changed) do
          if @options[:valid_callback]
            if @options[:valid_callback].call(@prompt_entry.value)
              c = W3DHub::THEME[:Button][:border_color]

              @prompt_entry.style.border_color = c
              @prompt_entry.style.default[:border_color] = c
              @prompt_entry.style.hover[:border_color]   = c
              @prompt_entry.style.active[:border_color]  = c

              @accept_button.enabled = true
            else
              c = 0xff_ff0000

              @prompt_entry.style.border_color = c
              @prompt_entry.style.default[:border_color] = c
              @prompt_entry.style.hover[:border_color]   = c
              @prompt_entry.style.active[:border_color]  = c

              @accept_button.enabled = false
            end

            @prompt_entry.set_border_color
          end
        end
      end
    end
  end
end
