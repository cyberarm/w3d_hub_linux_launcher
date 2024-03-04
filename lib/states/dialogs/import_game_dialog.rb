class W3DHub
  class States
    class ImportGameDialog < CyberarmEngine::GuiState
      def setup
        @application = Store.applications.games.find { |g| g.id == @options[:app_id] }
        @channel = @application.channels.find { |c| c.id == @options[:channel] }

        theme W3DHub::THEME

        background 0x88_525252

        stack(width: 1.0, max_width: 760, height: 1.0, max_height: 268, v_align: :center, h_align: :center, background: 0xee_222222) do
          # Title bar
          flow(width: 1.0, height: 36, padding: 8) do
            background 0x88_000000

            # image "#{GAME_ROOT_PATH}/media/ui_icons/export.png", width: 32, align: :center, color: 0xaa_ffffff

            # tagline "<b>#{I18n.t(:"server_browser.direct_connect")}</b>", fill: true, text_align: :center
            title "Import #{@application.name} (#{@channel.name})", width: 1.0, text_align: :center, font: BOLD_FONT
          end

          stack(width: 1.0, fill: true, padding_left: 8, padding_right: 8) do
            stack(width: 1.0, height: 72) do
              para "Path to Executable:"

              flow(width: 1.0, fill: true) do
                @game_path = edit_line "", fill: true, height: 1.0
                button "Browse...", width: 128, height: 1.0, enabled: W3DHub.unix?, tip: W3DHub.unix? ? "Browse for game executable" : "Not available on Windows" do
                  path = W3DHub.ask_file
                  @game_path.value = path if !path.empty? && File.exist?(path)
                end
              end
            end

            flow(fill: true)

            flow(width: 1.0, margin_top: 8, height: 46, padding_bottom: 8) do
              button "Cancel", fill: true, margin_right: 4 do
                pop_state
              end

              flow(fill: true)

              @save_button = button "Save", fill: true, margin_left: 4, enabled: false do
                pop_state

                Store.application_manager.imported!(@application, @channel, @game_path.value)
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

      def update
        super

        @save_button.enabled = valid?
      end

      def button_down(id)
        super

        case id
        when Gosu::KB_ESCAPE
          pop_state
        end
      end

      def valid?
        path = @game_path.value

        File.exist?(path) && !File.directory?(path) && File.extname(path) == ".exe"
      end
    end
  end
end
