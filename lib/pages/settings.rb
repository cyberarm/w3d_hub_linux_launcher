class W3DHub
  class Pages
    class Settings < Page
      def setup
        body.clear do
          stack(width: 1.0, height: 1.0, padding: 16, scroll: true) do
            background 0xaa_252525

            stack(width: 1.0, fill: true) do
              para "<b>Language</b>"
              para "<b>Launcher Language</b>", width: 0.249, margin_left: 32, margin_top: 12
              stack(width: 0.75) do
                @language_menu = list_box items: I18n.available_locales.map { |l| expand_language_code(l.to_s) }, choose: expand_language_code(Store.settings[:language]), width: 1.0
                para "Select the UI language you'd like to use in the W3D Hub Launcher."
              end
            end

            stack(width: 1.0, height: 144) do
              para "<b>Folder Paths</b>", margin_top: 8, padding_top: 8, border_thickness_top: 2, border_color_top: 0xee_ffffff, width: 1.0
              flow(width: 1.0, height: 0.5) do
                para "<b>App Install Folder</b>", width: 0.249, margin_left: 32, margin_top: 12

                stack(width: 0.75) do
                  @app_install_dir_input = edit_line Store.settings[:app_install_dir], width: 1.0
                  para "The folder into which new games and apps will be installed by the launcher"
                end
              end

              flow(width: 1.0, height: 256, margin_top: 16) do
                para "<b>Package Cache Folder</b>", width: 0.249, margin_left: 32, margin_top: 12

                stack(width: 0.75, height: 200) do
                  flow(width: 1.0, height: 1.0) do
                    @package_cache_dir_input = edit_line Store.settings[:package_cache_dir], fill: true
                    button "Browse...", width: 128, height: 1.0, tip: "Browse for game executable" do
                      path = W3DHub.ask_file
                    end
                  end

                  para "A folder which will be used to cache downloaded packages used to install games and apps"
                end
              end
            end

            if true # W3DHub.unix?
              stack(width: 1.0, fill: true) do
                para "<b>Wine</b>", margin_top: 8, padding_top: 8, border_thickness_top: 2, border_color_top: 0xee_ffffff, width: 1.0
                para "<b>Wine Command</b>", width: 0.249, margin_left: 32, margin_top: 12
                stack(width: 0.75) do
                  @wine_command_input = edit_line Store.settings[:wine_command], width: 1.0
                  para "Command to use to for Windows compatiblity layer"
                end
              end

              stack(width: 1.0, fill: true, margin_top: 16) do
                para "<b>Wine Prefix</b>", width: 0.249, margin_left: 32, margin_top: 12
                stack(width: 0.75) do
                  @wine_prefix_toggle = toggle_button checked: Store.settings[:wine_prefix]
                  para "Whether each game gets its own prefix. Uses global/default prefix by default."
                end
              end
            end

            button "Save" do
              old_language = Store.settings[:language]
              Store.settings[:language] = language_code(@language_menu.value)

              Store.settings[:app_install_dir] = @app_install_dir_input.value
              Store.settings[:package_cache_dir] = @package_cache_dir_input.value

              Store.settings[:wine_command] = @wine_command_input.value
              Store.settings[:wine_prefix] = @wine_prefix_toggle.value

              Store.settings.save_settings

              begin
                I18n.locale = Store.settings[:language]
              rescue I18n::InvalidLocale
                I18n.locale = :en
              end

              if old_language == Store.settings[:language]
                page(Pages::Games)
              else
                # pop back to Boot state which will immediately push a new instance of Interface
                pop_state
              end
            end
          end
        end
      end

      def language_code(string)
        case string.downcase.strip
        when "deutsch"
          "de"
        when "français"
          "fr"
        when "español"
          "es"
        else
          "en"
        end
      end

      def expand_language_code(string)
        case string.downcase.strip
        when "en"
          "English"
        when "de"
          "Deutsch"
        when "fr"
          "Français"
        when "es"
          "Español"
        else
          logger.warn("W3DHub::Settings") { "Unknown language code: #{string.inspect}" }
        end
      end
    end
  end
end
