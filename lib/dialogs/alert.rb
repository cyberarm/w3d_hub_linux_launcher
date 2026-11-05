module W3DHubLauncher
  class Dialog
    class Alert < W3DHubLauncher::Dialog
      def setup
        super

        stack(width: 1.0, max_width: 800, height: 1.0, max_height: 480, style_class: [:dialog]) do
          flow(width: 1.0, background_nine_slice: NINE_SLICE_ROUNDED_TOP, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0) do
            banner @options[:title] || "", width: 1.0, text_align: :center
          end

          stack(style_class: [:dialog_container]) do
            tagline @options[:message] || ""
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
