class W3DHub
  class Pages
    class Settings < Page
      def setup
        body.clear do
          stack(width: 1.0, height: 1.0, padding: 16) do
            background 0xaa_252525

            stack(width: 1.0, fill: true, max_width: 720, h_align: :center, scroll: true) do
              tagline "Launcher Language"
              @language_menu = list_box items: I18n.available_locales.map { |l| expand_language_code(l.to_s) }, choose: expand_language_code(Store.settings[:language]), width: 1.0, margin_left: 16
              para "Select the UI language you'd like to use in the W3D Hub Launcher.", margin_left: 16


              tagline "Launcher Directories", margin_top: 16
              caption "Applications Install Directory", margin_left: 16
              flow(width: 1.0, margin_left: 16) do
                @app_install_dir_input = edit_line Store.settings[:app_install_dir], fill: true
                button "Browse...", width: 128, tip: "Browse for applications install directory" do
                  path = W3DHub.ask_folder
                  @app_install_dir_input.value = path unless path.empty?
                end
              end

              caption "Package Cache Directory", margin_left: 16, margin_top: 16
              flow(width: 1.0, margin_left: 16) do
                @package_cache_dir_input = edit_line Store.settings[:package_cache_dir], fill: true
                button "Browse...", width: 128, tip: "Browse for package cache directory" do
                  path = W3DHub.ask_folder
                  @package_cache_dir_input.value = path unless path.empty?
                end
              end

              if W3DHub.unix?
                tagline "Wine - Windows compatibility layer", margin_top: 16
                caption "Wine Command", margin_left: 16
                flow(width: 1.0, margin_left: 16) do
                  @wine_command_input = edit_line Store.settings[:wine_command], fill: true
                  button "Browse...", width: 128, tip: "Browse for wine executable" do
                    path = W3DHub.ask_file(filters: %w[wine proton])
                    @wine_command_input.value = path unless path.empty?
                  end
                end
                para "Command to use to for Windows compatiblity layer.", margin_left: 16

                caption "Wine Prefix", margin_left: 16, margin_top: 16
                flow(width: 1.0, margin_left: 16) do
                  @wine_prefix_input = edit_line Store.settings[:wine_prefix], fill: true
                  button "Browse...", width: 128, tip: "Browse for wine prefix directory" do
                    path = W3DHub.ask_folder
                    @wine_prefix_input.value = path unless path.empty?
                  end
                end
                para "Leave empty to use default global prefix.", margin_left: 16

                # TODO: support winetricks stuff
                # tagline "Winetricks", margin_top: 16
                # caption "Winetricks Command", margin_left: 16
                # flow(width: 1.0, margin_left: 16) do
                #   @winetricks_command_input = edit_line Store.settings[:winetricks_command], fill: true, enabled: false
                #   button "Browse...", width: 128, tip: "Browse for winetricks executable", enabled: false do
                #     path = W3DHub.ask_file(filters: %w[winetricks protontricks])
                #     @winetricks_command_input.value = path unless path.empty?
                #   end
                # end

                # caption "Fixups", margin_left: 16, margin_top: 16
                # button "Install d3dcompiler_47", margin_left: 16, enabled: false
                # para "Fixes games instantly crashing at startup due to not being able to compile shaders.", margin_left: 16

                # button "Install DXVK", margin_left: 16, margin_top: 16, enabled: false
                # para "Use Vulkan-based DirectX translation layers.", margin_left: 16
                # para "WARNING: Games will stop working if your hardware does not support Vulkan!", margin_left: 16
              end
            end

            flow(width: 256, height: 64, h_align: :center, margin_top: 16) do
              button "Save", width: 1.0 do
                save_settings!
              end
              flow(fill: true)
            end

            button("Clear package cache: #{W3DHub.format_size(Dir.glob("#{Store.settings[:package_cache_dir]}/**/**").map { |f| File.file?(f) ? File.size(f) : 0}.sum)}", tip: "Purge #{Store.settings[:package_cache_dir]}", **DANGEROUS_BUTTON) do |btn|
              logger.info(LOG_TAG) { "Purging cache (#{Store.settings[:package_cache_dir]})..." }
              FileUtils.remove_dir(Store.settings[:package_cache_dir], force: true)
              btn.value = "Clear package cache: #{W3DHub.format_size(Dir.glob("#{Store.settings[:package_cache_dir]}/**/**").map { |f| File.file?(f) ? File.size(f) : 0}.sum)}"
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

          "UNKNOWN"
        end
      end

      def save_settings!
        old_language = Store.settings[:language]
        Store.settings[:language] = language_code(@language_menu.value)

        Store.settings[:app_install_dir] = @app_install_dir_input.value
        Store.settings[:package_cache_dir] = @package_cache_dir_input.value

        Store.settings[:wine_command] = @wine_command_input.value
        Store.settings[:wine_prefix] = @wine_prefix_input.value

        Store.settings[:winetricks_command] = @winetricks_command_input.value

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
