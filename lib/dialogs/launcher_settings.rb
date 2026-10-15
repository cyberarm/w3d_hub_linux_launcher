module W3DHubLauncher
  class Dialog
    class LauncherSettings < W3DHubLauncher::Dialog
      def setup
        super

        stack(width: 0.75, max_width: 1280, height: 0.75, max_height: 800, style_class: [:dialog]) do
          flow(width: 1.0, background_nine_slice: NINE_SLICE_ROUNDED_TOP, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0) do
            banner "Launcher Settings", width: 1.0, text_align: :center
          end

          item_height = 40 + PADDING
          settings = MemCache[:settings]

          stack(width: 1.0, fill: true, scroll: true, margin_left: PADDING, margin_right: PADDING, padding: HALF_PADDING, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: ALPHA_BLACK) do
            flow(width: 1.0, height: item_height, margin_top: PADDING) do
              tagline "Nickname", height: 1.0, text_v_align: :center
              @nickname = edit_line settings&.preferences&.nickname || Etc.getlogin, fill: true
            end
            inscription "Nickname to use when joining servers.", margin_left: PADDING

            flow(width: 1.0, height: item_height, margin_top: HALF_PADDING) do
            tagline "Launcher package cache directory", height: 1.0, text_v_align: :center
            @launcher_package_cache_directory = edit_line settings&.preferences&.launcher_package_cache_directory || DEFAULT_PACKAGE_CACHE_PATH, fill: true
            button "Browse..."
            end
            inscription "Location where the launcher will download application packages.", margin_left: PADDING

            flow(width: 1.0, height: item_height, margin_top: HALF_PADDING) do
              tagline "Application installation directory", height: 1.0, text_v_align: :center
              @application_installation_directory = edit_line settings&.preferences&.application_installation_directory || DEFAULT_APPLICATIONS_PATH, fill: true
              button "Browse..."
            end
            inscription "Location where the launcher will install new applications.", margin_left: PADDING

            flow(width: 1.0, height: item_height, margin_top: HALF_PADDING) do
              tagline "Wine prefix path", height: 1.0, text_v_align: :center
              @wine_prefix_path = edit_line settings&.preferences&.wine_prefix_path || "", fill: true
              button "Browse..."
            end
            inscription "Location of wine prefix to use. Leave blank to use default.", margin_left: PADDING

            flow(width: 1.0, height: item_height, margin_top: HALF_PADDING) do
              tagline "Wine command", height: 1.0, text_v_align: :center
              @wine_command = edit_line settings&.preferences&.wine_command || "wine", fill: true
              button "Browse..."
            end
            inscription "Path to wine executable. Use <c=f80>wine</c> for system installed wine.", margin_left: PADDING

            flow(width: 1.0, height: item_height, margin_top: HALF_PADDING) do
              tagline "Winetricks command", height: 1.0, text_v_align: :center
              @winetricks_command = edit_line settings&.preferences&.winetricks_command || "winetricks", fill: true
              button "Browse..."
            end
            inscription "Path to winetricks executable. Use <c=f80>winetricks</c> for system installed winetricks.", margin_left: PADDING
          end

          flow(width: 1.0, padding: PADDING, background_nine_slice: NINE_SLICE_ROUNDED_BOTTOM, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0) do
            button "Close" do
              pop_state
            end

            flow(fill: true)

            button "Save", **CTA_BUTTON_THEME do |btn|
              btn.enabled = false

              settings = MemCache[:settings]

              # update user preferences
              settings.preferences.nickname = @nickname.value.strip
              settings.preferences.launcher_package_cache_directory = @launcher_package_cache_directory.value.strip
              settings.preferences.application_installation_directory = @application_installation_directory.value.strip
              settings.preferences.wine_prefix_path = @wine_prefix_path.value.strip
              settings.preferences.wine_command = @wine_command.value.strip
              settings.preferences.winetricks_command = @winetricks_command.value.strip

              Worker::Api.update_settings(settings) do |result|
                if result.okay?
                   on_main_thread(proc {
                     MemCache[:settings] = settings
                     pop_state
                   })
                else
                  # FIXME: Somehow something went wrong... show an error message.
                  btn.enabled = true
                end
              end
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
