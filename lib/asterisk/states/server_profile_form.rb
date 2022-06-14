class W3DHub
  class Asterisk
    class States
      class ServerProfileForm < CyberarmEngine::GuiState
        def setup
          @server_profile = @options[:editing]

          theme W3DHub::THEME

          background 0xaa_444444

          stack(width: 1.0, max_width: 760, height: 1.0, max_height: 256, v_align: :center, h_align: :center, background: 0xff_222222) do
            # Title bar
            flow(width: 1.0, height: 32, padding: 8) do
              background 0x88_000000

              # image "#{GAME_ROOT_PATH}/media/ui_icons/export.png", width: 32, align: :center, color: 0xaa_ffffff

              # tagline "<b>#{I18n.t(:"server_browser.direct_connect")}</b>", fill: true, text_align: :center
              tagline @server_profile ? "Update Server Profile" : "Add Server Profile", width: 1.0, text_align: :center
            end

            stack(width: 1.0, fill: true, padding_left: 8, padding_right: 8) do
              stack(width: 1.0, height: 65) do
                para "Server Profile Name:"
                @server_name = edit_line "#{@server_profile&.name}", width: 1.0
                @server_name.subscribe(:changed) do |label|
                  @save_button.enabled = label.value.length.positive?
                end
              end

              flow(fill: true)

              flow(width: 1.0, height: 40, padding_bottom: 8) do
                button "Cancel", fill: true, margin_right: 4 do
                  pop_state
                end

                flow(fill: true)

                @save_button = button "Save", fill: true, margin_left: 4 do
                  pop_state
                  @options[:save_callback].call(
                    @server_profile,
                    @server_name.value
                  )
                end
              end
            end
          end
        end

        def draw
          previous_state&.draw

          Gosu.flush

          super
        end

        def button_down(id)
          super

          case id
          when Gosu::KB_ESCAPE
            pop_state
          end
        end
      end
    end
  end
end
