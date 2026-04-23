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
              caption "Please confirm launcher's default settings and make any desired tweaks.", font: FONT_REGULAR

              flow(width: 1.0, height: 40, margin_top: HALF_PADDING) do
              tagline "Launcher package cache directory", height: 1.0, text_v_align: :center
              edit_line DEFAULT_PACKAGE_CACHE_PATH, fill: true
              button "Browse..."
              end
              inscription "Location where the launcher will download application packages."

              flow(width: 1.0, height: 40, margin_top: HALF_PADDING) do
                tagline "Application installation directory", height: 1.0, text_v_align: :center
                edit_line DEFAULT_APPLICATIONS_PATH, fill: true
                button "Browse..."
              end
              inscription "Location where the launcher will install new applications."

              flow(width: 1.0, height: 40, margin_top: HALF_PADDING) do
                tagline "Wine context", height: 1.0, text_v_align: :center
                edit_line "", fill: true
                button "Browse..."
              end
              inscription "Location of wine context to use. Leave blank to use default."

              flow(width: 1.0, height: 40, margin_top: HALF_PADDING) do
                tagline "Wine command", height: 1.0, text_v_align: :center
                edit_line "wine", fill: true
                button "Browse..."
              end
              inscription "Path to wine executable. Use `wine` for system installed wine."
            end

            flow(width: 1.0, padding_top: PADDING) do
              flow(fill: true)
              button "Accept" do |btn|
                btn.enabled = false

                Worker::Api.update_settings({}) do |result|
                  if result.okay?
                    page(Page::Boot::StartUp)
                  else
                    btn.enabled = true
                  end

                  puts "NOW!"
                end
              end
            end
          end
        end
      end
    end
  end
end
