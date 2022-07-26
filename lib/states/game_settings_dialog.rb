class W3DHub
  class States
    class GameSettingsDialog < CyberarmEngine::GuiState
      BUTTON_STYLE = { text_size: 18, padding_top: 3, padding_bottom: 3, padding_left: 3, padding_right: 3 }
      def setup
        window.show_cursor = true

        theme(W3DHub::THEME)

        background 0xee_444444

        stack(width: 1.0, max_width: 720, height: 1.0, max_height: 512, v_align: :center, h_align: :center, background: 0xee_222222) do
          flow(width: 1.0, height: 0.1, padding: 8) do
            background 0x88_000000

            image "#{GAME_ROOT_PATH}/media/icons/#{@options[:app_id]}.png", width: 0.04, align: :center

            tagline "<b>#{@options[:title]}</b>", width: 0.9, text_align: :center
          end

          stack(width: 1.0, fill: true, padding: 16) do
            flow(width: 1.0, fill: true) do
              stack(width: 0.5, height: 1.0) do
                caption "General"

                flow(width: 1.0, height: 24, margin: 4) do
                  para "Default to First Person", fill: true
                  toggle_button tip: "Default to First Person", **BUTTON_STYLE
                end

                flow(width: 1.0, height: 24, margin: 4) do
                  para "Enable Chat Log", fill: true
                  toggle_button tip: "Enable Chat Log", **BUTTON_STYLE
                end

                flow(width: 1.0, height: 24, margin: 4) do
                  para "Background Downloads", fill: true
                  toggle_button tip: "Background Downloads", **BUTTON_STYLE
                end

                flow(width: 1.0, height: 24, margin: 4) do
                  para "Show FPS", fill: true
                  toggle_button tip: "Show FPS", **BUTTON_STYLE
                end
              end

              stack(width: 0.5, height: 1.0) do
                caption "Video"

                flow(width: 1.0, height: 24, margin: 4) do
                  para "Resolution", fill: true
                  list_box items: ["#{Gosu.screen_width}x#{Gosu.screen_height}"], width: 128, **BUTTON_STYLE
                end

                flow(width: 1.0, height: 24, margin: 4) do
                  para "Windowed Mode", fill: true
                  list_box items: ["Windowed", "Borderless", "Fullscreen"], width: 128, **BUTTON_STYLE
                end

                flow(width: 1.0, height: 24, margin: 4) do
                  para "Enable VSync", fill: true
                  toggle_button tip: "Enable VSync", **BUTTON_STYLE
                end

                flow(width: 1.0, height: 24, margin: 4) do
                  para "MSAA Mode", fill: true
                  list_box items: %w[0 2 4 8 16], width: 48, **BUTTON_STYLE
                end
              end
            end

            flow(width: 1.0, fill: true) do
              stack(width: 0.5, height: 1.0) do
                caption "Audio"

                flow(width: 1.0, height: 24, margin: 4) do
                  para "Sound Effects", fill: true
                  slider height: 1.0, width: 172, margin_right: 8
                  toggle_button tip: "Sound Effects", checked: true, **BUTTON_STYLE
                end

                flow(width: 1.0, height: 24, margin: 4) do
                  para "Dialogue", fill: true
                  slider height: 1.0, width: 172, margin_right: 8
                  toggle_button tip: "Dialogue", checked: true, **BUTTON_STYLE
                end

                flow(width: 1.0, height: 24, margin: 4) do
                  para "Music", fill: true
                  slider height: 1.0, width: 172, margin_right: 8
                  toggle_button tip:"Music", checked: true, **BUTTON_STYLE
                end

                flow(width: 1.0, height: 24, margin: 4) do
                  para "Cinematic", fill: true
                  slider height: 1.0, width: 172, margin_right: 8
                  toggle_button tip: "Cinematic", checked: true, **BUTTON_STYLE
                end
              end

              stack(width: 0.5, height: 1.0) do
                caption "Performance"
                flow(width: 1.0, height: 24, margin: 4) do
                  para "Texture Detail", fill: true
                  list_box items: ["Low", "Medium", "High"], width: 128, **BUTTON_STYLE
                end

                flow(width: 1.0, height: 24, margin: 4) do
                  para "Shader Detail", fill: true
                  list_box items: ["Low", "Medium", "High"], width: 128, **BUTTON_STYLE
                end

                flow(width: 1.0, height: 24, margin: 4) do
                  para "Post Proccessing Detail", fill: true
                  list_box items: ["Low", "Medium", "High"], width: 128, **BUTTON_STYLE
                end

                flow(width: 1.0, height: 24, margin: 4) do
                  para "Shadow Detail", fill: true
                  list_box items: ["Low", "Medium", "High"], width: 128, **BUTTON_STYLE
                end

                flow(width: 1.0, height: 24, margin: 4) do
                  para "High Quality Shadows", fill: true
                  toggle_button tip: "High Quality Shadows", **BUTTON_STYLE
                end
              end
            end
          end

          flow(width: 1.0, height: 0.1, padding: 8) do
            button "Cancel", width: 0.25 do
              pop_state
              @options[:cancel_callback]&.call
            end

            flow(fill: true)

            button "WWConfig", width: 0.25 do
              pop_state
              Store.application_manager.wwconfig(@options[:app_id], @options[:channel])
            end

            flow(fill: true)

            button "Save", width: 0.25 do
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
