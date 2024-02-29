class W3DHub
  class States
    class GameSettingsDialog < Dialog
      BUTTON_STYLE = { text_size: 18, padding_top: 3, padding_bottom: 3, padding_left: 3, padding_right: 3, height: 18 }

      def setup
        window.show_cursor = true

        theme(THEME)

        @app_id = @options[:app_id]
        @channel = @options[:channel]

        @game_settings = GameSettings.new(@app_id, @channel)

        background 0xaa_525252

        stack(width: 1.0, max_width: 760, height: 1.0, max_height: 720, v_align: :center, h_align: :center, background: 0xee_222222, border_thickness: 2, border_color: 0xee_222222, padding: 10) do
          flow(width: 1.0, height: 36, padding: 8) do
            background Store.application_manager.color(@app_id)

            title @options[:title] || Store.application_manager.name(@app_id) || "Game Settings", fill: true, text_align: :center, font: BOLD_FONT
          end

          stack(width: 1.0, fill: true, padding: 16, margin_top: 10) do
            flow(width: 1.0, fill: true) do
              stack(width: 0.5, height: 1.0, margin_right: 8) do
                tagline "General"

                flow(width: 1.0, height: 28, margin: 4, margin_left: 10) do
                  para "Default to First Person", fill: true, text_wrap: :none
                  toggle_button tip: "Default to First Person", checked: @game_settings.get_value(:default_to_first_person), **BUTTON_STYLE do |btn|
                    @game_settings.set_value(:default_to_first_person, btn.value)
                  end
                end

                flow(width: 1.0, height: 28, margin: 4, margin_left: 10) do
                  para "Background Downloads", fill: true, text_wrap: :none
                  toggle_button tip: "Background Downloads", checked: @game_settings.get_value(:background_downloads), **BUTTON_STYLE do |btn|
                    @game_settings.set_value(:background_downloads, btn.value)
                  end
                end

                flow(width: 1.0, height: 28, margin: 4, margin_left: 10) do
                  para "Enable Hints", fill: true, text_wrap: :none
                  toggle_button tip: "Enable Hints", checked: @game_settings.get_value(:hints_enabled), **BUTTON_STYLE do |btn|
                    @game_settings.set_value(:hints_enabled, btn.value)
                  end
                end

                flow(width: 1.0, height: 28, margin: 4, margin_left: 10) do
                  para "Enable Chat Log", fill: true, text_wrap: :none
                  toggle_button tip: "Enable Chat Log", checked: @game_settings.get_value(:chat_log), **BUTTON_STYLE do |btn|
                    @game_settings.set_value(:chat_log, btn.value)
                  end
                end

                flow(width: 1.0, height: 28, margin: 4, margin_left: 10) do
                  para "Show FPS", fill: true, text_wrap: :none
                  toggle_button tip: "Show FPS", checked: @game_settings.get_value(:show_fps), **BUTTON_STYLE do |btn|
                    @game_settings.set_value(:show_fps, btn.value)
                  end
                end

                flow(width: 1.0, height: 28, margin: 4, margin_left: 10) do
                  para "Show Velocity", fill: true, text_wrap: :none
                  toggle_button tip: "Show Velocity", checked: @game_settings.get_value(:show_velocity), **BUTTON_STYLE do |btn|
                    @game_settings.set_value(:show_velocity, btn.value)
                  end
                end

                flow(width: 1.0, height: 28, margin: 4, margin_left: 10) do
                  para "Show Damage Numbers", fill: true, text_wrap: :none
                  toggle_button tip: "Show Damage Numbers", checked: @game_settings.get_value(:show_damage_numbers), **BUTTON_STYLE do |btn|
                    @game_settings.set_value(:show_damage_numbers, btn.value)
                  end
                end
              end

              stack(width: 0.5, height: 1.0, margin_left: 8) do
                tagline "Video"

                flow(width: 1.0, height: 28, margin: 4, margin_left: 10) do
                  res_options = @game_settings.get(:resolution_width).options.each_with_index.map do |w, i|
                    "#{w[0]}x#{@game_settings.get(:resolution_height).options[i][0]}"
                  end

                  current_res = "#{@game_settings.get_value(:resolution_width)}x#{@game_settings.get_value(:resolution_height)}"

                  para "Resolution", fill: true, text_wrap: :none
                  list_box items: res_options, choose: current_res, width: 172, **BUTTON_STYLE do |value|
                    w, h = value.split("x", 2)

                    @game_settings.set_value(:resolution_width, w.to_i)
                    @game_settings.set_value(:resolution_height, h.to_i)
                  end
                end

                flow(width: 1.0, height: 28, margin: 4, margin_left: 10) do
                  para "Windowed Mode", fill: true, text_wrap: :none
                  list_box items: @game_settings.get(:windowed_mode).options.map { |v| v[0] }, choose: @game_settings.get_value(:windowed_mode), width: 172, **BUTTON_STYLE do |value|
                    @game_settings.set_value(:windowed_mode, value)
                  end
                end

                flow(width: 1.0, height: 28, margin: 4, margin_left: 10) do
                  para "Enable VSync", fill: true, text_wrap: :none
                  toggle_button tip: "Enable VSync", checked: @game_settings.get_value(:vsync), **BUTTON_STYLE do |btn|
                    @game_settings.set_value(:vsync, btn.value)
                  end
                end

                flow(width: 1.0, height: 28, margin: 4, margin_left: 10) do
                  para "Anti-aliasing", fill: true, text_wrap: :none
                  list_box items: @game_settings.get(:anti_aliasing).options.map { |v| v[0] }, choose: @game_settings.get_value(:anti_aliasing), width: 72, **BUTTON_STYLE do |value|
                    @game_settings.set_value(:anti_aliasing, value)
                  end
                end
              end
            end

            flow(width: 1.0, fill: true, margin_top: 16) do
              stack(width: 0.5, height: 1.0, margin_right: 8) do
                tagline "Audio"

                flow(width: 1.0, height: 28, margin: 4, margin_left: 10) do
                  para "Master Volume", fill: true, text_wrap: :none
                  slider(height: 1.0, width: 172, value: @game_settings.get_value(:master_volume), margin_right: 8).subscribe(:changed) do |slider|
                    @game_settings.set_value(:master_volume, slider.value)
                  end

                  toggle_button tip: "Sound Effects", checked: @game_settings.get(:master_enabled), **BUTTON_STYLE do |btn|
                    @game_settings.set_value(:master_enabled, btn.value)
                  end
                end

                flow(width: 1.0, height: 28, margin: 4, margin_left: 10) do
                  para "Sound Effects", fill: true, text_wrap: :none
                  slider(height: 1.0, width: 172, value: @game_settings.get_value(:sound_effects_volume), margin_right: 8).subscribe(:changed) do |slider|
                    @game_settings.set_value(:sound_effects_volume, slider.value)
                  end

                  toggle_button tip: "Sound Effects", checked: @game_settings.get(:sound_effects_enabled), **BUTTON_STYLE do |btn|
                    @game_settings.set_value(:sound_effects_enabled, btn.value)
                  end
                end

                flow(width: 1.0, height: 28, margin: 4, margin_left: 10) do
                  para "Dialogue", fill: true, text_wrap: :none
                  slider(height: 1.0, width: 172, value: @game_settings.get_value(:sound_dialog_volume), margin_right: 8).subscribe(:changed) do |slider|
                    @game_settings.set_value(:sound_dialog_volume, slider.value)
                  end

                  toggle_button tip: "Dialogue", checked: @game_settings.get_value(:sound_dialog_enabled), **BUTTON_STYLE do |btn|
                    @game_settings.set_value(:sound_dialog_enabled, btn.value)
                  end
                end

                flow(width: 1.0, height: 28, margin: 4, margin_left: 10) do
                  para "Music", fill: true, text_wrap: :none
                  slider(height: 1.0, width: 172, value: @game_settings.get_value(:sound_music_volume), margin_right: 8).subscribe(:changed) do |slider|
                    @game_settings.set_value(:sound_music_volume, slider.value)
                  end

                  toggle_button tip: "Music", checked: @game_settings.get_value(:sound_music_enabled), **BUTTON_STYLE do |btn|
                    @game_settings.set_value(:sound_music_enabled, btn.value)
                  end
                end

                flow(width: 1.0, height: 28, margin: 4, margin_left: 10) do
                  para "Cinematic", fill: true, text_wrap: :none
                  slider(height: 1.0, width: 172, value: @game_settings.get_value(:sound_cinematic_volume), margin_right: 8).subscribe(:changed) do |slider|
                    @game_settings.set_value(:sound_cinematic_volume, slider.value)
                  end

                  toggle_button tip: "Cinematic", checked: @game_settings.get_value(:sound_cinematic_enabled), **BUTTON_STYLE do |btn|
                    @game_settings.set_value(:sound_cinematic_enabled, btn.value)
                  end
                end

                flow(width: 1.0, height: 28, margin: 4, margin_left: 10) do
                  para "Play Sound with Game in Background", fill: true, text_wrap: :none
                  toggle_button tip: "Play Sound with Game in Background", checked: @game_settings.get_value(:sound_in_background), **BUTTON_STYLE do |btn|
                    @game_settings.set_value(:sound_in_background, btn.value)
                  end
                end
              end

              stack(width: 0.5, height: 1.0, margin_left: 8) do
                tagline "Performance"

                flow(width: 1.0, height: 28, margin: 4, margin_left: 10) do
                  para "Texture Detail", fill: true, text_wrap: :none
                  list_box items: @game_settings.get(:texture_detail).options.map { |v| v[0] }, choose: @game_settings.get_value(:texture_detail), width: 172, **BUTTON_STYLE do |value|
                    @game_settings.set_value(:texture_detail, value)
                  end
                end

                flow(width: 1.0, height: 28, margin: 4, margin_left: 10) do
                  para "Texture Filtering", fill: true, text_wrap: :none
                  list_box items: @game_settings.get(:texture_filtering).options.map { |v| v[0] }, choose: @game_settings.get_value(:texture_filtering), width: 172, **BUTTON_STYLE do |value|
                    @game_settings.set_value(:texture_filtering, value)
                  end
                end

                # flow(width: 1.0, height: 28, margin: 4, margin_left: 10) do
                #   para "Shader Detail", fill: true
                #   list_box items: @game_settings.get(:texture_filtering).options.map { |v| v[0] }, choose: @game_settings.get_value(:texture_filtering), width: 172, **BUTTON_STYLE do |value|
                #     @game_settings.set_value(:texture_filtering, value)
                #   end
                # end

                # flow(width: 1.0, height: 28, margin: 4, margin_left: 10) do
                #   para "Post Processing Detail", fill: true
                #   list_box items: @game_settings.get(:texture_filtering).options.map { |v| v[0] }, choose: @game_settings.get_value(:texture_filtering), width: 172, **BUTTON_STYLE do |value|
                #     @game_settings.set_value(:texture_filtering, value)
                #   end
                # end

                flow(width: 1.0, height: 28, margin: 4, margin_left: 10) do
                  para "Shadow Resolution", fill: true, text_wrap: :none
                  list_box items: @game_settings.get(:shadow_resolution).options.map { |v| v[0] }, choose: @game_settings.get_value(:shadow_resolution), width: 172, **BUTTON_STYLE do |value|
                    @game_settings.set_value(:shadow_resolution, value)
                  end
                end

                flow(width: 1.0, height: 28, margin: 4, margin_left: 10) do
                  para "High Quality Shadows", fill: true, text_wrap: :none
                  toggle_button tip: "High Quality Shadows", checked: @game_settings.get_value(:background_downloads), **BUTTON_STYLE do |btn|
                    @game_settings.set_value(:background_downloads, btn.value)
                  end
                end

                flow(width: 1.0, height: 28, margin: 4, margin_left: 10) do
                  para "FPS Limit", fill: true, text_wrap: :none
                  list_box items: @game_settings.get(:fps).options.map { |v| v[0] }, choose: @game_settings.get_value(:fps), width: 172, **BUTTON_STYLE do |value|
                    @game_settings.set_value(:fps, value.to_i)
                  end
                end
              end
            end
          end

          flow(width: 1.0, height: 46, padding: 8) do
            button "Cancel", width: 0.25 do
              pop_state
              @options[:cancel_callback]&.call
            end

            flow(fill: true)

            button "Save", width: 0.25 do
              pop_state
              @game_settings.save_settings!

              @options[:accept_callback]&.call
            end
          end
        end
      end
    end
  end
end
