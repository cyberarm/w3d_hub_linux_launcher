module W3DHubLauncher
  class Window < CyberarmEngine::Window
    def setup
      self.show_cursor = true
      self.caption = "Cyberarm's W3D Hub Linux Launcher | v2.0.0 alpha"

      push_state(Interface)
    end
  end

  class Interface < CyberarmEngine::GuiState
    LARGE_PADDING = 40
    PADDING = 20
    HALF_PADDING = 10
    ALPHA_BLACK = 0x88_000000

    def setup
      theme({
        TextBlock: {
          text_static: true,
          font: "Noto Sans"
        },
        Link: {
          color: 0xff_dddddd,
          hover: {
            color: 0xff_ffffff
          },
          active: {
            color: 0xff_aaaaaa
          }
        }
      })

      # root container - background image
      stack(width: 1.0, height: 1.0, background_image: get_image("./media/background.png"), background_image_mode: :fill) do
        # root container - background image tint
        flow(width: 1.0, height: 1.0, background: 0x88_000000) do
          # content container
          stack(fill: true, height: 1.0, margin: PADDING, margin_right: LARGE_PADDING) do
            # header bar container
            flow(width: 1.0, height: 80, background: ALPHA_BLACK, margin_bottom: PADDING) do
              title "LOGO"
              title "GAMES"
              title "SERVERS"
              flow(fill: true)
              title "_"
              title "I"
            end

            # page content container
            stack(width: 1.0, fill: true) do
              # game bar container
              flow(width: 1.0, height: 60) do
                flow(width: 220, height: 1.0, background: ALPHA_BLACK) do
                  link "ALL GAMES"
                end

                flow(fill: true, height: 1.0, background: ALPHA_BLACK, margin_left: PADDING) do
                  image get_image("./data/cache/apb.png"), height: 1.0, padding: HALF_PADDING, background:0x88_5e5c64, border_thickness: 3, border_color_bottom: 0xff_3584e4, tip: "Red Alert: A Path Beyond"
                  image get_image("./data/cache/ren.png"), height: 1.0, padding: HALF_PADDING, tip: "Command & Conquer: Renegade"
                  image get_image("./data/cache/tsr.png"), height: 1.0, padding: HALF_PADDING, tip: "Tiberian Sun: Reborn"
                  image get_image("./data/cache/woa.png"), height: 1.0, padding: HALF_PADDING, tip: "Battle for Dune: War of Assassins"
                end
              end

              # game content container
              flow(width: 1.0, height: 1.0, margin_top: PADDING) do
                # game info container
                stack(width: 340, height: 1.0, debug: true) do
                  # logo
                  image get_image("./media/background.png"), width: 1.0, max_height: 124

                  # web links
                  stack(width: 1.0, fill: nil, padding: 0, padding_top: LARGE_PADDING, padding_bottom: nil, debug_color: 0xff_0000ff, debug: true) do
                    link "Modifications"
                    link "Bug Tracker", padding_top: LARGE_PADDING
                    link "Player Statistics"
                  end

                  # launching ta game
                  caption "Game Version"
                  list_box items: [ "Release", "Open Testing" ], width: 1.0
                  flow(width: 1.0) do
                    button "PLAY", fill: true
                    button "{}"
                    button "[]"
                  end
                  inscription "Version: 3.9.2.15"
                end

                # game events and news container
                stack(fill: true, height: 1.0, margin_left: LARGE_PADDING) do
                  flow(width: 1.0, max_height: 380, background: ALPHA_BLACK) do
                    image get_image("./media/background.png"), fill: true, aspect_ratio: 16.0 / 9.0

                    stack(fill: true, height: 1.0, margin_left: PADDING) do
                      caption "Upcoming Event", color: 0xff_22aa11
                      title "Red Alert: A Path Beyond Game Night"
                      tagline "July 11, 2028"

                      flow(fill: true)

                      button "Read More", margin_left: PADDING, margin_right: LARGE_PADDING, margin_bottom: PADDING, width: 1.0
                    end
                  end
                end
              end
            end
          end

          # battleview/friends container
          stack(width: 0.25, max_width: 300, height: 1.0, margin: PADDING, margin_left: 0, background: 0x88_888888) do
            title "FRIENDS"
          end
        end
      end
    end

    def setup
      stack(width: 1.0, height: 1.0, background: 0xff_111111) do
        button "HELLO", margin: 40
        stack(width: 50, height: 50, margin: 32, padding: 16, border_thickness: 10, border_color: 0xff424242, background: 0xff_242424) { para "HI" }
        stack(width: 0.5, height: 0.5, margin_top: 40, margin_left: 40, border_thickness: 10, border_color: 0xff424242, background: 0xff_242424) do
          stack(width: 0.5, fill: true, margin_top: 40, margin_left: 40, border_thickness: 10, border_color: 0xff424242, background: 0xff_242424) do
            stack(width: 0.5, fill: true, margin_top: 40, margin_left: 40, border_thickness: 10, border_color: 0xff424242, background: 0xff_242424) do
            end
          end
        end
      end
    end
  end
end
