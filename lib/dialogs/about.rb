module W3DHubLauncher
  module Dialog
    class About < CyberarmEngine::Dialog
      def setup
        # application name and version
        # authorship
        # special thanks
        # used gems and libraries
        # useful links
        theme(THEME)
        background 0xee_222222

        stack(width: 1.0, max_width: 600, height: 1.0, max_height: 600, h_align: :center, v_align: :center, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0x88_000000) do
          flow(width: 1.0, background_nine_slice: NINE_SLICE_ROUNDED_TOP, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0xaa_000000) do
            banner "About", width: 1.0, text_align: :center
          end

          stack(width: 1.0, fill: true, scroll: true, padding_left: PADDING, padding_right: PADDING) do
            title NAME
            para "© 2026 cyberarm", margin_left: PADDING
            link "MIT licence", margin_left: PADDING

            title "Thanks", margin_top: LARGE_PADDING
            10.times do
              tagline "NAME", margin_left: PADDING
              para "REASON", margin_left: LARGE_PADDING
            end

            title "Libraries", margin_top: LARGE_PADDING
            10.times do
              tagline "LIBRARY", margin_left: PADDING
              para "LEGAL TEXT", margin_left: LARGE_PADDING
              link "ABREV licence", margin_left: LARGE_PADDING
            end
          end

          flow(width: 1.0, background_nine_slice: NINE_SLICE_ROUNDED_BOTTOM, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0xaa_000000) do
            button "Close" do
              pop_state
            end
          end
        end
      end
    end
  end
end
