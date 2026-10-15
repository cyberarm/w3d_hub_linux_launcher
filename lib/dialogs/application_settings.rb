module W3DHubLauncher
  class Dialog
    class ApplicationSettings < W3DHubLauncher::Dialog
      def setup
        super

        # settings application
        @application = @options[:application]
        # mannifest application
        @app = @options[:app]

        @channel = @app.channels.find { |c| c.id == @application.channel }

        stack(width: 0.75, max_width: 1280, height: 0.75, max_height: 600, style_class: [:dialog]) do
          flow(width: 1.0, background_nine_slice: NINE_SLICE_ROUNDED_TOP, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0) do
            banner "Application Settings", width: 1.0, text_align: :center
            title "#{@app.name} (#{@channel.name})", width: 1.0, text_align: :center
          end

          item_height = 40 + PADDING

          stack(width: 1.0, fill: true, scroll: true, margin_left: PADDING, margin_right: PADDING, padding: HALF_PADDING, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: ALPHA_BLACK) do
            flow(width: 1.0, height: item_height, margin_top: HALF_PADDING) do
              tagline "Wine prefix path", height: 1.0, text_v_align: :center
              @wine_prefix_path = edit_line @application.wine_prefix_path, fill: true
              button "Browse..."
            end
            inscription "Location of wine prefix to use. Leave blank to use default.", margin_left: PADDING

            flow(width: 1.0, height: item_height, margin_top: PADDING) do
              tagline "Launch Command", height: 1.0, text_v_align: :center
              @launch_command = edit_line @application.launch_command, fill: true
            end
            inscription "Command arguments to use when launching application. Use <c=f80>%COMMAND%</c> for default.", margin_left: PADDING
          end

          flow(width: 1.0, padding: PADDING, background_nine_slice: NINE_SLICE_ROUNDED_BOTTOM, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0) do
            button "Close" do
              pop_state
            end

            flow(fill: true)

            button "Save", **CTA_BUTTON_THEME do |btn|
              btn.enabled = false

              settings = MemCache[:settings]

              # TODO: Save the things!
              # update user preferences
              # settings.preferences.nickname = @nickname.value.strip
              # settings.preferences.launcher_package_cache_directory = @launcher_package_cache_directory.value.strip
              # settings.preferences.application_installation_directory = @application_installation_directory.value.strip
              # settings.preferences.wine_prefix_path = @wine_prefix_path.value.strip
              # settings.preferences.wine_command = @wine_command.value.strip
              # settings.preferences.winetricks_command = @winetricks_command.value.strip
              #
              # Worker::Api.update_settings(settings) do |result|
              #   if result.okay?
              #      on_main_thread(proc {
              #        MemCache[:settings] = settings
              #        pop_state
              #      })
              #   else
              #     # FIXME: Somehow something went wrong... show an error message.
              #     btn.enabled = true
              #   end
              # end
            end
          end
        end
      end

      # FIXME: Check settings for validity before saving
      def valid?
        true
      end
    end
  end
end
