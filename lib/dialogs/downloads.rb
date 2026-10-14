module W3DHubLauncher
  class Dialog
    class Downloads < W3DHubLauncher::Dialog
      def setup
        super

        stack(width: 1.0, max_width: 600, height: 1.0, max_height: 600, style_class: [:dialog]) do
          flow(width: 1.0, background_nine_slice: NINE_SLICE_ROUNDED_TOP, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0) do
            banner "Downloads", width: 1.0, text_align: :center
          end

          stack(style_class: [:dialog_container]) do
            50.times do
              stack(width: 1.0, margin_top: HALF_PADDING, margin_bottom: HALF_PADDING) do
                flow(width: 1.0) do
                  para "PACKAGE_NAME.mix"
                  flow(fill: true)
                  para ["Downloading...", "Pending...", "Done.", "Patching...", "Unpacking..."].sample
                end
                progress(width: 1.0, fraction: rand)
              end
            end
          end

          flow(width: 1.0, padding: PADDING, background_nine_slice: NINE_SLICE_ROUNDED_BOTTOM, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0) do
            flow(fill: true)

            button "Close", **CTA_BUTTON_THEME do
              pop_state
            end

            flow(fill: true)
          end
        end
      end
    end
  end
end
