module W3DHubLauncher
  class Dialog
    class LauncherSettings < W3DHubLauncher::Dialog
      include W3DHubLauncher::Form::SettingsForm

      def setup
        super

        stack(width: 0.75, max_width: 1280, height: 0.75, max_height: 800, style_class: [:dialog], padding_left: PADDING, padding_right: PADDING) do |e|
          flow(width: 1.0, background_nine_slice: NINE_SLICE_ROUNDED_TOP, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0) do
            banner "Launcher Settings", width: 1.0, text_align: :center
          end

          form_setup

          flow(width: 1.0, padding_top: PADDING, padding_bottom: PADDING, background_nine_slice: NINE_SLICE_ROUNDED_BOTTOM, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0) do
            button "Close" do
              pop_state
            end

            flow(fill: true)

            @accept_button = button "Save", **CTA_BUTTON_THEME do |btn|
              form_commit(btn)
            end
          end
        end
      end
    end
  end
end
