module W3DHubLauncher
  module Page
    class Games < CyberarmEngine::Page
      include GuiExt

      def setup
        # game bar container
        flow(width: 1.0, height: 60) do
          flow(width: 220, height: 1.0, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: ALPHA_BLACK) do
            flow(width: 1.0, height: 40, margin_left: PADDING, v_align: :center, h_align: :center) do
              image safe_get_image("./media/icons/menuGrid.png"), height: 40, color: 0xff_bbbbbb
              link "ALL GAMES", text_size: 24, font: FONT_BLACK, height: 1.0, text_v_align: :center
            end
          end

          flow(fill: true, height: 1.0, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: ALPHA_BLACK, margin_left: PADDING) do
            image safe_get_image("./data/cache/apb.png"), height: 1.0, padding: HALF_PADDING, background_nine_slice: NINE_SLICE_ROUNDED_TOP, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0x88_5e5c64, border_thickness_bottom: 3, border_color_bottom: 0xff_3584e4, tip: "Red Alert: A Path Beyond"
            image safe_get_image("./data/cache/ren.png"), height: 1.0, padding: HALF_PADDING, background_nine_slice: NINE_SLICE_ROUNDED_TOP, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0, tip: "Command & Conquer: Renegade"
            image safe_get_image("./data/cache/tsr.png"), height: 1.0, padding: HALF_PADDING, background_nine_slice: NINE_SLICE_ROUNDED_TOP, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0, tip: "Tiberian Sun: Reborn"
            image safe_get_image("./data/cache/woa.png"), height: 1.0, padding: HALF_PADDING, background_nine_slice: NINE_SLICE_ROUNDED_TOP, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0, tip: "Battle for Dune: War of Assassins"
          end
        end

        # game content container
        flow(width: 1.0, fill: true, margin_top: LARGE_PADDING) do
          # game info container
          stack(width: 340, height: 1.0) do
            # logo
            image safe_get_image("/run/media/cyberarm/Storage/W3DHub/Launcher/package-cache/games/apb/logo.png.package"), width: 1.0, max_height: 124

            # web links
            stack(width: 1.0, fill: true, padding: 0, padding_top: LARGE_PADDING) do
              link "Modifications", text_size: 24
              link "Bug Tracker", text_size: 24
              link "Player Statistics", text_size: 24
            end

            # launching ta game
            caption "Game Version"
            list_box items: [ "Release", "Open Testing" ], width: 1.0, margin_bottom: PADDING
            flow(width: 1.0, height: 60) do
              button "PLAY", fill: true, height: 1.0, background_nine_slice: NINE_SLICE_ROUNDED_LEFT, **CTA_BUTTON_THEME
              button safe_get_image("./media/icons/singleplayer.png"), image_height: 1.0, background_nine_slice: NINE_SLICE_SQUARE, **CTA_BUTTON_THEME
              button safe_get_image("./media/icons/gear.png"), image_height: 1.0, background_nine_slice: NINE_SLICE_ROUNDED_RIGHT, **CTA_BUTTON_THEME
            end
            inscription "Version: 3.9.2.15", margin_top: PADDING
          end

          # game events and news container
          stack(fill: true, height: 1.0, margin_left: LARGE_PADDING, scroll: true) do
            flow(width: 1.0, height: 1.0, max_height: 380, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: ALPHA_BLACK) do
              image safe_get_image("./media/background.png"), fill: true, aspect_ratio: 16.0 / 9.0

              stack(fill: true, height: 1.0, margin_left: PADDING) do
                caption "Upcoming Event".upcase, color: 0xff_22aa11
                title "Red Alert: A Path Beyond Game Night"
                tagline "July 11, 2028"

                flow(fill: true)

                button "Read More", margin_left: PADDING, margin_right: LARGE_PADDING, margin_bottom: PADDING, width: 1.0
              end
            end

            # news container
            flow(width: 1.0, margin_top: PADDING) do
              9.times do
                stack(width: 1.0 / 3, height: 345, aspect_ratio: 1, margin_left: HALF_PADDING, margin_right: HALF_PADDING, margin_bottom: PADDING) do
                  stack(width: 1.0, fill: true, background_image: safe_get_image("./media/background.png"), background_image_mode: :fill)
                  stack(width: 1.0, height: 1.0 / 3, padding: PADDING, v_align: :bottom, background_nine_slice: NINE_SLICE_ROUNDED_BOTTOM, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: ALPHA_BLACK, border_thickness_top: 1, border_color_top: Gosu::Color::BLACK) do
                    caption "NEWS", color: 0x88_ffffff
                    tagline "A News Item Post A News Item Post"
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
