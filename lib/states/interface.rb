module W3DHubLauncher
  class States
    class Interface < W3DHubLauncher::State
      def setup
        super

        # root container - background image
        stack(width: 1.0, height: 1.0, background_image: safe_get_image("/run/media/cyberarm/Storage/W3DHub/Launcher/package-cache/games/apb/background.png.package"), background_image_mode: :fill) do
          # root container - background image tint
          stack(width: 1.0, height: 1.0, background: ALPHA_BLACK) do
            # content container
            stack(width: 1.0, fill: true, margin: PADDING) do
              # header bar container
              flow(width: 1.0, height: 80, margin_bottom: PADDING) do |c|
                # logo + menu button
                button(safe_get_image("#{ROOT_PATH}/media/logo.png"), image_height: 1.0, background: 0, border_color: 0, hover: { background: 0 }, active: { background: 0, color: 0xff_ffffff }) do |btn|
                  menu(parent: btn) do
                    menu_item("Settings")
                    menu_item("About") do
                      dialog(Dialog::About)
                    end
                    menu_item("Exit") do
                      window.close
                    end
                  end.show
                end

                stack(fill: true, height: 1.0) do
                  stack(fill: true)
                  flow(width: 1.0) do
                    link("GAMES", text_v_align: :center, font: FONT_BLACK, margin_left: PADDING) { page(Page::Games) }
                    link("SERVERS", text_v_align: :center, font: FONT_BLACK, margin_left: PADDING) { page(Page::ServerBrowser) }
                    stack(fill: true)
                    image safe_get_image("#{ROOT_PATH}/media/icons/import.png"), height: 40, color: 0xff_bbbbbb, tip: "Downloads"
                    image safe_get_image("#{ROOT_PATH}/media/icons/information.png"), height: 40, color: 0xff_bbbbbb, tip: "Notifications"
                  end
                  stack(fill: true)
                end

                # self account container
                flow(width: 300, height: 80, margin_left: LARGE_PADDING) do
                  # self avatar container
                  stack(width: 80, height: 1.0, background_image: rounded_avatar(safe_get_image("#{ROOT_PATH}/media/default.png"))) do
                    # self online state container
                    stack(width: 20, height: 20, v_align: :bottom, h_align: :right, background_image: safe_get_image("#{ROOT_PATH}/media/ui/circle_small.png"), background_image_color: 0xff_26a269)
                  end

                  stack(fill: true, height: 1.0, margin_left: HALF_PADDING) do
                    flow(fill: true)
                    # self name
                    caption "cyberarm", font: FONT_BLACK, text_wrap: :none
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
              end

              # layout container
              flow(width: 1.0, fill: true) do
                # page host container
                @page_host = stack(fill: true, height: 1.0) do
                end

                # battleview/friends container
                @battleview_container = stack(width: 300, height: 1.0, margin_left: LARGE_PADDING, visible: true) do
                  # friend management container
                  flow(width: 1.0, height: 60) do
                    flow(width: 1.0, v_align: :center) do
                      button safe_get_image("#{ROOT_PATH}/media/icons/singleplayer.png"), image_height: 1.0
                      button safe_get_image("#{ROOT_PATH}/media/icons/gear.png"), image_height: 1.0, margin_left: HALF_PADDING
                      edit_line "", margin_left: HALF_PADDING, fill: true, height: 1.0
                    end
                  end

                  # friends/clanmates list container
                  stack(width: 1.0, fill: true, margin_top: LARGE_PADDING, scroll: true) do
                    50.times do |i|
                      # friend container
                      widget(width: 1.0, height: 48, padding_top: HALF_PADDING, padding_bottom: HALF_PADDING, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0, hover: { background_nine_slice_color: ALPHA_GRAY }, active: { background_nine_slice_color: ALPHA_BLACK }) do |w|
                        w.subscribe(:clicked_left_mouse_button) do
                          puts "HELLO THERE"
                        end


                        # friend avatar container
                        stack(width: 48, height: 1.0, margin_left: HALF_PADDING, background_image: rounded_avatar(safe_get_image("#{ROOT_PATH}/media/default.png"))) do
                          stack(width: 12, height: 12, v_align: :bottom, h_align: :right, background_image: safe_get_image("#{ROOT_PATH}/media/ui/circle_small.png"), background_image_color: 0xff_26a269)
                        end
                        # friend name and status container
                        stack(fill: true, height: 1.0, margin_left: HALF_PADDING, margin_right: HALF_PADDING) do
                          stack(v_align: :center) do
                            caption ["Silverlight", "PXD2000", "Alstar", "SteelGhost", "FRAYDO"].sample, text_wrap: :none
                            inscription "RA_Under • 13:52", text_wrap: :none, margin_top: -HALF_PADDING
                          end
                        end
                        # friend active application container
                        stack(width: 48, height: 1.0, margin_right: HALF_PADDING, background_image: safe_get_image("#{ROOT_PATH}/media/logo.png"))
                      end
                    end
                  end
                end
              end
            end
          end
        end

        page(Page::Games)
      end

      def button_up(id)
        super

        @battleview_container.toggle if id == Gosu::KB_F8
      end
    end
  end
end
