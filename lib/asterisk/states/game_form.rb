class W3DHub
  class Asterisk
    class States
      class GameForm < CyberarmEngine::GuiState
        def setup
          @game = @options[:editing]

          theme W3DHub::THEME

          background 0xaa_444444

          stack(width: 1.0, max_width: 760, height: 1.0, max_height: 256, v_align: :center, h_align: :center, background: 0xff_222222) do
            # Title bar
            flow(width: 1.0, height: 32, padding: 8) do
              background 0x88_000000

              # image "#{GAME_ROOT_PATH}/media/ui_icons/export.png", width: 32, align: :center, color: 0xaa_ffffff

              # tagline "<b>#{I18n.t(:"server_browser.direct_connect")}</b>", fill: true, text_align: :center
              tagline @game ? "Update Game" : "Add Game", width: 1.0, text_align: :center
            end

            stack(width: 1.0, fill: true, padding_left: 8, padding_right: 8) do
              stack(width: 1.0, height: 66) do
                para "Game or Mod Title:"
                @game_title = edit_line "#{@game&.title}", width: 1.0, fill: true
              end

              stack(width: 1.0, height: 66) do
                para "Path to Executable:"

                flow(width: 1.0, fill: true) do
                  @game_path = edit_line "#{@game&.path}", fill: true, height: 1.0
                  button "Browse...", width: 128, height: 1.0, enabled: W3DHub.unix?, tip: W3DHub.unix? ? "Browse for game executable" : "Not available on Windows" do
                    path = W3DHub.ask_file
                    @game_path.value = path if !path.empty? && File.exist?(path)
                  end
                end
              end

              flow(fill: true)

              flow(width: 1.0, margin_top: 8, height: 40, padding_bottom: 8) do
                button "Cancel", fill: true, margin_right: 4 do
                  pop_state
                end

                flow(fill: true)

                @save_button = button "Save", fill: true, margin_left: 4, enabled: false do
                  pop_state
                  @options[:save_callback].call(
                    @game,
                    @game_path.value,
                    @game_title.value
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
          existing_game = W3DHub::Store[:asterisk_config].games.find { |g| g.title == @game_title.value }
          existing_game = nil if existing_game == @game

          @game_title.value.length.positive? &&
          @game_path.value.length.positive? &&
          File.exist?(@game_path.value) &&
          !existing_game
        end
      end
    end
  end
end
