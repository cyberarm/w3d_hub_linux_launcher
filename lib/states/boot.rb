module W3DHubLauncher
  class States
    class Boot < W3DHubLauncher::State
      def setup
        super

        # root container - background image
        stack(width: 1.0, height: 1.0, background_image: safe_get_image("/run/media/cyberarm/Storage/W3DHub/Launcher/package-cache/games/apb/background.png.package"), background_image_mode: :fill) do
          # root container - background image tint
          flow(width: 1.0, height: 1.0, background: 0xaa_000000) do
            # content container
            stack(fill: true, height: 1.0, margin: PADDING, margin_right: PADDING) do
              # header bar container
              flow(width: 1.0, height: 80, margin_bottom: PADDING) do |c|
                # logo image
                image(safe_get_image("./media/logo.png"), height: 1.0)

                stack(fill: true, height: 1.0) do
                  stack(fill: true)
                  title NAME
                  stack(fill: true)
                end
              end

              @page_host = stack(width: 1.0, fill: true, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: 8, background_nine_slice_color: ALPHA_GRAY) do
              end
            end
          end
        end

        page(Page::Boot::Terms)
      end
    end
  end
end
