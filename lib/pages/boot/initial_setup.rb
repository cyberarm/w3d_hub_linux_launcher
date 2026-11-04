module W3DHubLauncher
  module Page
    module Boot
      class InitialSetup < CyberarmEngine::Page
        include GuiExt
        include W3DHubLauncher::Form::SettingsForm

        def setup
          # initialize default settings
          @settings = Worker::Api::Settings.new({})

          stack(width: 1.0, background_nine_slice: NINE_SLICE_ROUNDED_TOP, background_nine_slice_from_edge: 8, background_nine_slice_color: 0x11_ffffff, padding: HALF_PADDING) do
            banner "Welcome to #{NAME}", width: 1.0, text_align: :center
            tagline "Your gateway to the world of W3D Hub games.", width: 1.0, text_align: :center
          end

          stack(width: 1.0, fill: true, padding: PADDING) do |e|
            title "Initial Setup"
            caption "Please confirm launcher's default settings and make any desired adjustments. These can be changed in the launcher settings later.", font: FONT_REGULAR, margin_left: PADDING

            form_setup(nil)

            flow(width: 1.0, padding_top: PADDING) do
              flow(fill: true)
              @accept_button = button "Accept", **CTA_BUTTON_THEME do |btn|
                form_commit(btn)
              end
            end
          end
        end
      end
    end
  end
end
