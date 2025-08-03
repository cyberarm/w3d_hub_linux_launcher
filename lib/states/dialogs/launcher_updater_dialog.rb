class W3DHub
  class States
    class LauncherUpdaterDialog < Dialog
      BUTTON_STYLE = { text_size: 18, padding_top: 3, padding_bottom: 3, padding_left: 3, padding_right: 3, height: 18 }
      LIST_ITEM_THEME = Marshal.load(Marshal.dump(THEME))
      BUTTON_STYLE.each do |key, value|
        LIST_ITEM_THEME[:Button][key] = value
      end

      def setup
        window.show_cursor = true

        theme(THEME)

        background 0xaa_525252

        stack(width: 1.0, max_width: 760, height: 1.0, max_height: 640, v_align: :center, h_align: :center, background: 0xee_222222, border_thickness: 2, border_color: 0xee_222222, padding: 16) do
          flow(width: 1.0, height: 36, padding: 8) do
            background 0xff_0052c0

            title @options[:title] || "Launcher Update Available", fill: true, text_align: :center, font: BOLD_FONT
          end

          stack(width: 1.0, fill: true, margin_top: 14) do
            subtitle "Release Notes - #{@options[:available_version]}"

            # case launcher_release_type
            # when :git
            # when :tebako
            # end

            pp @options[:release_data]
            
            stack(width: 1.0, fill: true, scroll: true, padding: 8, border_thickness: 1, border_color: 0x44_ffffff) do
              # para @options[:release_data][:body], width: 1.0
              # FIXME: Finish this bit
              @options[:release_data][:body].lines.each do |line|
                line.strip
              end
            end
          end

          flow(width: 1.0, height: 46, margin_top: 16) do
            background 0xff_ffffff

            button "Cancel", width: 0.25 do
              pop_state
              @options[:cancel_callback]&.call
            end

            flow(fill: true)

            button "Update", width: 0.25 do
              pop_state
              @options[:accept_callback]&.call
            end
          end
        end
      end
    end
  end
end
