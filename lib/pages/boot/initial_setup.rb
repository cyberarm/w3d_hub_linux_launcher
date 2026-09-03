module W3DHubLauncher
  module Page
    module Boot
      class InitialSetup < CyberarmEngine::Page
        include GuiExt

        def setup
          stack(width: 1.0, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: 8, background_nine_slice_color: 0x11_ffffff, padding: HALF_PADDING) do
            banner "Welcome to #{NAME}", width: 1.0, text_align: :center
            tagline "Your gateway to the world of W3D Hub games.", width: 1.0, text_align: :center
          end

          stack(width: 1.0, fill: true, padding: PADDING) do
            stack(width: 1.0, fill: true, scroll: true) do
              title "Initial Setup"
              caption "Please confirm launcher's default settings and make any desired adjustments. These can be changed in the launcher settings later.", font: FONT_REGULAR, margin_left: PADDING

              flow(width: 1.0, height: 40, margin_top: PADDING) do
              tagline "Nickname", height: 1.0, text_v_align: :center
              @nickname = edit_line Etc.getlogin, fill: true
              end
              inscription "Nickname to use when joining servers.", margin_left: PADDING

              flow(width: 1.0, height: 40, margin_top: HALF_PADDING) do
              tagline "Launcher package cache directory", height: 1.0, text_v_align: :center
              @launcher_package_cache_directory = edit_line DEFAULT_PACKAGE_CACHE_PATH, fill: true
              button "Browse..."
              end
              inscription "Location where the launcher will download application packages.", margin_left: PADDING

              flow(width: 1.0, height: 40, margin_top: HALF_PADDING) do
                tagline "Application installation directory", height: 1.0, text_v_align: :center
                @application_installation_directory = edit_line DEFAULT_APPLICATIONS_PATH, fill: true
                button "Browse..."
              end
              inscription "Location where the launcher will install new applications.", margin_left: PADDING

              flow(width: 1.0, height: 40, margin_top: HALF_PADDING) do
                tagline "Wine prefix path", height: 1.0, text_v_align: :center
                @wine_prefix_path = edit_line "", fill: true
                button "Browse..."
              end
              inscription "Location of wine prefix to use. Leave blank to use default.", margin_left: PADDING

              flow(width: 1.0, height: 40, margin_top: HALF_PADDING) do
                tagline "Wine command", height: 1.0, text_v_align: :center
                @wine_command = edit_line "wine", fill: true
                button "Browse..."
              end
              inscription "Path to wine executable. Use <c=f80>wine</c> for system installed wine.", margin_left: PADDING

              flow(width: 1.0, height: 40, margin_top: HALF_PADDING) do
                tagline "Winetricks command", height: 1.0, text_v_align: :center
                @winetricks_command = edit_line "winetricks", fill: true
                button "Browse..."
              end
              inscription "Path to winetricks executable. Use <c=f80>winetricks</c> for system installed winetricks.", margin_left: PADDING
            end

            flow(width: 1.0, padding_top: PADDING) do
              flow(fill: true)
              button "Accept", **CTA_BUTTON_THEME do |btn|
                btn.enabled = false

                # initialize default settings
                settings = Worker::Api::Settings.new({})

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
                       page(Page::Boot::StartUp)
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
      end
    end
  end
end
