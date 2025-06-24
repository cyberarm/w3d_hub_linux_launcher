class W3DHub
  class Pages
    class Settings < Page
      def setup
        body.clear do
          stack(width: 1.0, height: 1.0, padding: 16) do
            background 0xaa_252525

            stack(width: 1.0, fill: true, max_width: 720, h_align: :center, scroll: true) do
              stack(width: 1.0, height: 112) do
                tagline "Launcher Language"
                @language_menu = list_box items: I18n.available_locales.map { |l| expand_language_code(l.to_s) }, choose: expand_language_code(Store.settings[:language]), width: 1.0, margin_left: 16
                para "Select the UI language you'd like to use in the W3D Hub Launcher.", margin_left: 16
              end


              stack(width: 1.0, height: 200, margin_top: 16) do
                tagline "Launcher Directories"
                caption "Applications Install Directory", margin_left: 16
                flow(width: 1.0, fill: true, margin_left: 16) do
                  @app_install_dir_input = edit_line Store.settings[:app_install_dir], fill: true
                  button "Browse...", width: 128, tip: "Browse for applications install directory" do
                    path = W3DHub.ask_folder
                    @app_install_dir_input.value = path unless path.empty?
                  end
                end

                caption "Package Cache Directory", margin_left: 16, margin_top: 16
                flow(width: 1.0, fill: true, margin_left: 16) do
                  @package_cache_dir_input = edit_line Store.settings[:package_cache_dir], fill: true
                  button "Browse...", width: 128, tip: "Browse for package cache directory" do
                    path = W3DHub.ask_folder
                    @package_cache_dir_input.value = path unless path.empty?
                  end
                end
              end

              if W3DHub.unix?
                stack(width: 1.0, height: 224, margin_top: 16) do
                  tagline "Wine - Windows compatibility layer"
                  caption "Wine Command", margin_left: 16
                  @wine_command_input = edit_line Store.settings[:wine_command], width: 1.0, margin_left: 16
                  para "Command to use to for Windows compatiblity layer.", margin_left: 16

                  caption "Wine Prefix", margin_left: 16, margin_top: 16
                  flow(width: 1.0, height: 48, margin_left: 16) do
                    @wine_prefix_toggle = toggle_button checked: Store.settings[:wine_prefix], enabled: false
                    para "Whether each game gets its own prefix. Uses global/default prefix by default."
                  end
                end
              end
            end

            stack(width: 128, height: 48, h_align: :center, margin_top: 16) do
              button "Save", width: 1.0 do
                save_settings!
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
          raise "Unknown language error"
        end
      end

      def save_settings!
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
