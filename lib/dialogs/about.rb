module W3DHubLauncher
  class Dialog
    class About < W3DHubLauncher::Dialog
      def setup
        super

        stack(width: 1.0, max_width: 600, height: 1.0, max_height: 600, h_align: :center, v_align: :center, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: ALPHA_BLACK) do
          flow(width: 1.0, background_nine_slice: NINE_SLICE_ROUNDED_TOP, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: ALPHA_GRAY) do
            banner "About", width: 1.0, text_align: :center
          end

          stack(width: 1.0, fill: true, scroll: true, padding_left: PADDING, padding_right: PADDING) do
            title NAME
            tagline format("v%s (%s)", VERSION, VERSION_NAME), margin_left: PADDING
            para "© 2021 - #{Time.now.year} cyberarm", margin_left: PADDING
            link "MIT licence", margin_left: PADDING

            title "Special Thanks", margin_top: LARGE_PADDING
            W3DHubLauncher::Attribution::SPECIAL_THANKS.each do |item|
              present_item(item)
            end

            title "Software / Libraries", margin_top: LARGE_PADDING
            W3DHubLauncher::Attribution::LIBRARIES.each do |item|
              present_item(item)
            end
          end

          flow(width: 1.0, padding: PADDING, background_nine_slice: NINE_SLICE_ROUNDED_BOTTOM, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: ALPHA_GRAY) do
            flow(fill: true)

            button "Close" do
              pop_state
            end

            flow(fill: true)
          end
        end
      end

      def present_item(item)
        unless item.url.empty?
          link item.name, tip: item.url, margin_left: PADDING, font: FONT_BOLD
        else
          tagline item.name, margin_left: PADDING
        end
        para item.description, margin_left: LARGE_PADDING
        link item.license, tip: item.license_url, margin_left: PADDING + LARGE_PADDING unless item.license.empty?
      end
    end
  end
end
