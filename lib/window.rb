module W3DHubLauncher
  class Window < CyberarmEngine::Window
    def setup
      self.show_cursor = true
      self.caption = format("%s | v%s (%s)", NAME, VERSION, VERSION_NAME) # "Cyberarm's W3D Hub Linux Launcher | v2.0.0 alpha"

      push_state(Interface)
    end
  end

  class Interface < CyberarmEngine::GuiState
    include W3DHubLauncher::GuiExt

    def setup
      theme(THEME)

      # root container - background image
      stack(width: 1.0, height: 1.0, background_image: safe_get_image("/run/media/cyberarm/Storage/W3DHub/Launcher/package-cache/games/apb/background.png.package"), background_image_mode: :fill) do
        # root container - background image tint
        flow(width: 1.0, height: 1.0, background: 0xaa_000000) do
          # content container
          stack(fill: true, height: 1.0, margin: PADDING, margin_right: LARGE_PADDING) do
            # header bar container
            flow(width: 1.0, height: 80, margin_bottom: PADDING) do |c|
              # logo + menu button
              button(safe_get_image("./media/logo.png"), image_height: 1.0, background: 0, border_color: 0, hover: { background: 0 }, active: { background: 0, color: 0xff_ffffff }) do |btn|
                menu(parent: btn) do
                  menu_item("Settings")
                  menu_item("About")
                  menu_item("Exit") do
                    window.close
                  end
                end.show
              end

              stack(fill: true, height: 1.0) do
                stack(fill: true)
                flow(width: 1.0) do
                  link "GAMES", text_v_align: :center, font: FONT_BLACK, margin_left: PADDING
                  link "SERVERS", text_v_align: :center, font: FONT_BLACK, margin_left: PADDING
                  stack(fill: true)
                  image safe_get_image("./media/icons/import.png"), height: 40, color: 0xff_bbbbbb
                  image safe_get_image("./media/icons/information.png"), height: 40, color: 0xff_bbbbbb
                end
                stack(fill: true)
              end
            end

            # page content container
            stack(width: 1.0, fill: true) do
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
                      caption "Upcoming Event", color: 0xff_22aa11, font: FONT_BOLD
                      title "Red Alert: A Path Beyond Game Night", font: FONT_BOLD
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
                          caption "NEWS", color: 0x88_ffffff, font: FONT_BOLD
                          tagline "A News Item Post A News Item Post", font: FONT_BOLD
                        end
                      end
                    end
                  end
                end
              end
            end
          end

          # battleview/friends container
          stack(width: 300, height: 1.0, margin: PADDING, margin_left: 0) do
            # self account container
            flow(width: 1.0, height: 80) do
              # self avatar container
              stack(width: 80, height: 1.0, background_image: rounded_avatar(safe_get_image("./media/default.png"))) do
                # self online state container
                stack(width: 20, height: 20, v_align: :bottom, h_align: :right, background_image: safe_get_image("./media/ui/circle_small.png"), background_image_color: 0xff_26a269)
              end

              stack(fill: true, height: 1.0, margin_left: HALF_PADDING) do
                flow(fill: true)
                # self name
                caption "moonsense715test", font: FONT_BLACK, text_wrap: :none
                # self set online state
                link "Online ▼", text_size: 18 do |l|
                  menu(parent: l) do
                    menu_item("Online")
                    menu_item("Do Not Disturb")
                    menu_item("Away")
                    menu_item("Invisible")
                    menu_item("Sign Out")
                  end.show
                end
                flow(fill: true)
              end
            end

            # friend management container
            flow(width: 1.0, height: 60, margin_top: PADDING) do
              flow(width: 1.0, v_align: :center) do
                button safe_get_image("./media/icons/singleplayer.png"), image_height: 1.0
                button safe_get_image("./media/icons/gear.png"), image_height: 1.0, margin_left: HALF_PADDING
                edit_line "", margin_left: HALF_PADDING, fill: true, height: 1.0
              end
            end

            # friends/clanmates list container
            stack(width: 1.0, fill: true, margin_top: LARGE_PADDING, scroll: true) do
              50.times do |i|
                # friend container
                flow(width: 1.0, height: 48, padding_top: HALF_PADDING, padding_bottom: HALF_PADDING, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_color: 0, hover: { background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0x44_000000 }) do
                  # friend avatar container
                  stack(width: 48, height: 1.0, margin_left: HALF_PADDING, background_image: rounded_avatar(safe_get_image("./media/default.png"))) do
                    stack(width: 12, height: 12, v_align: :bottom, h_align: :right, background_image: safe_get_image("./media/ui/circle_small.png"), background_image_color: 0xff_26a269)
                  end
                  # friend name and status container
                  stack(fill: true, height: 1.0, margin_left: HALF_PADDING, margin_right: HALF_PADDING) do
                    stack(v_align: :center) do
                      caption "moonsense#{715 * (i + 1) % 1000}test", font: FONT_BOLD, text_wrap: :none, text_size: 20
                      inscription "RA_Under • 13:52", text_wrap: :none, text_size: 14, margin_top: -HALF_PADDING
                    end
                  end
                  # friend active application container
                  stack(width: 48, height: 1.0, margin_right: HALF_PADDING, background_image: safe_get_image("./media/logo.png"))
                end
              end
            end
          end
        end
      end
    end
  end
end
