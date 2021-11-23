class W3DHub
  class Pages
    class Settings < Page
      def setup
        body.clear do
          stack(width: 1.0, height: 1.0, padding: 64, scroll: true) do
            para "<b>Language</b>"
            para "Select the UI language you'd like to use in the W3D Hub Launcher. You should restart the launcher after changing this setting before the ui will update", width: 1.0
            list_box items: ["English", "French", "German"], width: 1.0

            para "<b>Folder Paths</b>", margin_top: 32
            stack(width: 1.0, height: 0.35) do
              flow(width: 1.0, height: 0.5) do
                para "<b>App Install Folder</b>", width: 0.249

                stack(width: 0.75, height: 1.0) do
                  edit_line Store.settings[:app_install_dir], width: 1.0
                  inscription "The folder into which new games and apps will be installed by the launcher"
                end
              end

              flow(width: 1.0, height: 0.5) do
                para "<b>Package Cache Folder</b>", width: 0.249

                stack(width: 0.75, height: 1.0) do
                  edit_line Store.settings[:package_cache_dir], width: 1.0
                  inscription "A folder which will be used to cache downloaded packages used to install games and apps"
                end
              end
            end

            para "<b>Diagnostics</b>"
            check_box "Enable Automatic Error Reporting", text_size: 16
            inscription "If this is enabled the launcher will automatically report errors to the development team, along with basic information about your machine, such as operating system.", width: 1.0

            button "Save", margin_top: 32 do
              Store.settings.save_settings
            end
          end
        end
      end
    end
  end
end
