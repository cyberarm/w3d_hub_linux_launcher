module W3DHubLauncher
  module Form
    module SettingsForm
      include GuiExt

      def form_setup(settings = MemCache[:settings])
        item_height = 40 + PADDING - HALF_PADDING

        stack(width: 1.0, fill: true, scroll: true, padding: HALF_PADDING, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: ALPHA_BLACK) do
          flow(width: 1.0, height: item_height - HALF_PADDING) do
            tagline "Nickname", height: 1.0, text_v_align: :center
            @nickname = edit_line settings&.preferences&.nickname || Etc.getlogin, fill: true, filter: method(:form_filter_nickname)
          end
          inscription "Nickname to use when joining servers. Nickname must be a least 3 characters long and no more than 40. Only A-z, 0-9, _, -, and [] characters allowed.", margin_left: PADDING

          flow(width: 1.0, height: item_height, margin_top: HALF_PADDING) do
            tagline "Launcher package cache directory", height: 1.0, text_v_align: :center
            @launcher_package_cache_directory = edit_line settings&.preferences&.launcher_package_cache_directory || DEFAULT_PACKAGE_CACHE_PATH, fill: true
            button "Browse..." do
              Gosu.choose_file do |result|
                pp result
              end
            end
          end
          inscription "Location where the launcher will download application packages.", margin_left: PADDING

          flow(width: 1.0, height: item_height, margin_top: HALF_PADDING) do
            tagline "Application installation directory", height: 1.0, text_v_align: :center
            @application_installation_directory = edit_line settings&.preferences&.application_installation_directory || DEFAULT_APPLICATIONS_PATH, fill: true
            button "Browse..." do
              Gosu.choose_file do |result|
                pp result
              end
            end
          end
          inscription "Location where the launcher will install new applications.", margin_left: PADDING

          flow(width: 1.0, height: item_height, margin_top: HALF_PADDING) do
            tagline "Wine prefix path", height: 1.0, text_v_align: :center
            @wine_prefix_path = edit_line settings&.preferences&.wine_prefix_path || "", fill: true
            button "Browse..." do
              Gosu.choose_file do |result|
                pp result
              end
            end
          end
          inscription "Location of wine prefix to use. Leave blank to use default.", margin_left: PADDING

          flow(width: 1.0, height: item_height, margin_top: HALF_PADDING) do
            tagline "Wine command", height: 1.0, text_v_align: :center
            @wine_command = edit_line settings&.preferences&.wine_command || "wine", fill: true
            button "Browse..." do
              Gosu.choose_file do |result|
                pp result
              end
            end
          end
          inscription "Path to wine executable. Use <c=f80>wine</c> for system installed wine.", margin_left: PADDING

          flow(width: 1.0, height: item_height, margin_top: HALF_PADDING) do
            tagline "Winetricks command", height: 1.0, text_v_align: :center
            @winetricks_command = edit_line settings&.preferences&.winetricks_command || "winetricks", fill: true
            button "Browse..." do
              Gosu.choose_file do |result|
                pp result
              end
            end
          end
          inscription "Path to winetricks executable. Use <c=f80>winetricks</c> for system installed winetricks.", margin_left: PADDING
        end
      end

      def form_commit(btn)
        btn.enabled = false

        @settings = MemCache[:settings]

        # update user preferences
        @settings.preferences.nickname = @nickname.value.strip
        @settings.preferences.launcher_package_cache_directory = @launcher_package_cache_directory.value.strip
        @settings.preferences.application_installation_directory = @application_installation_directory.value.strip
        @settings.preferences.wine_prefix_path = @wine_prefix_path.value.strip
        @settings.preferences.wine_command = @wine_command.value.strip
        @settings.preferences.winetricks_command = @winetricks_command.value.strip

        Worker::Api.update_settings(@settings) do |result|
          if result.okay?
             on_main_thread(proc {
               MemCache[:settings] = @settings
               pop_state
             })
          else
            # FIXME: Somehow something went wrong... show an error message.
            btn.enabled = true
          end
        end
      end

      def form_valid?
        form_valid_nickname?(@nickname.value)
      end

      def form_filter_nickname(entry)
        if @nickname.value.length + 1 <= 40 && (entry =~ /^[a-z0-9_\-\[\]]+$/i)
          entry
        else
          ""
        end
      end

      def form_valid_nickname?(value)
        value.length.between?(3, 40) && (value =~ /^[a-z0-9_\-\[\]]+$/i)
      end
    end
  end
end
