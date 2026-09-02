module W3DHubLauncher
  class Dialog
    class Account < W3DHubLauncher::Dialog
      def setup
        super

        stack(width: 1.0, max_width: 600, height: 1.0, max_height: 600, h_align: :center, v_align: :center, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: ALPHA_BLACK) do
          flow(width: 1.0, background_nine_slice: NINE_SLICE_ROUNDED_TOP, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: ALPHA_GRAY) do
            banner "Account", width: 1.0, text_align: :center
          end

          stack(width: 1.0, fill: true, scroll: true, padding_left: PADDING, padding_right: PADDING) do
            button "Sign In", tip: "https://sso.w3d.cyberarm.dev" do
              # use SSO service
              pop_state
            end
          end

          flow(width: 1.0, padding: PADDING, background_nine_slice: NINE_SLICE_ROUNDED_BOTTOM, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: ALPHA_GRAY) do
          end
        end
      end
    end
  end
end
