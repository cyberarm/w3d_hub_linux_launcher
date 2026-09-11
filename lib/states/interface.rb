module W3DHubLauncher
  class States
    class Interface < W3DHubLauncher::State
      def setup
        super

        # root container - background image
        stack(width: 1.0, height: 1.0, background_image: safe_get_image("#{ROOT_PATH}/media/background.png"), background_image_mode: :fill) do
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

                # navigation bar container
                stack(fill: true, height: 1.0) do
                  # stack(fill: true)

                  # navigation container
                  flow(width: 1.0) do
                    link("GAMES", text_v_align: :center, font: FONT_BLACK, margin_left: PADDING) { page(Page::Games) }
                    link("SERVERS", text_v_align: :center, font: FONT_BLACK, margin_left: PADDING) { page(Page::ServerBrowser) }
                    stack(fill: true)
                    image safe_get_image("#{ROOT_PATH}/media/icons/import.png"), height: 40, color: 0xff_bbbbbb, tip: "Downloads" do |img|
                      dialog(Dialog::Downloads)
                    end
                    image safe_get_image("#{ROOT_PATH}/media/icons/information.png"), height: 40, color: 0xff_bbbbbb, tip: "Notifications"
                  end
                  # application task status bar container
                  stack(width: 1.0, fill: true, margin_left: PADDING) do
                    flow(width: 1.0) do
                      para "Updating Red Alert: A Path Beyond (Release)"
                      stack(fill: true)
                      para "Fetching manifests..."
                    end
                    progress(width: 1.0, fraction: 0.75)
                  end
                end

                # self account container
                flow(width: 300, height: 80, margin_left: LARGE_PADDING) do
                  # self avatar container
                  stack(width: 80, height: 1.0, background_image: rounded_avatar(safe_get_image("#{ROOT_PATH}/media/default.png"))) do |i|
                    i.subscribe(:clicked_left_mouse_button) do
                      dialog(Dialog::Account)
                    end
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

                # server details container
                @server_details_container = stack(width: 400, height: 1.0, margin_left: HALF_PADDING, padding: PADDING, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: ALPHA_GRAY) do
                  tagline "SERVER NAME HERE SERVER NAME HERE SERVER NAME HERE", text_wrap: :none
                  image safe_get_image("#{ROOT_PATH}/media/default_map_preview.png"), width: 1.0, tip: "MAP NAME APPEARS HERE", margin_bottom: PADDING

                  flow(width: 1.0) do
                    stack(fill: true)
                    button "JOIN", **CTA_BUTTON_THEME
                    stack(fill: true)
                  end

                  stack(width: 1.0, fill: true, scroll: true, margin_top: PADDING) do
                    # misc. server details
                    stack(width: 1.0, padding: HALF_PADDING, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: ALPHA_GRAY) do
                      flow(width: 1.0) do
                        stack(width: 1.0 / 3) do
                          caption "Map"
                          para "TheBacon.mix"
                        end
                        stack(width: 1.0 / 3) do
                          caption "Ping"
                          para "9945ms"
                        end
                        stack(width: 1.0 / 3) do
                          caption "Players"
                          para "127/127"
                        end
                      end

                      flow(width: 1.0) do
                        stack(width: 1.0 / 3) do
                          caption "Next Map"
                          para "Bacon.mix"
                        end
                        stack(width: 1.0 / 3) do
                          caption "Time"
                          para "00:00:00"
                        end
                        stack(width: 1.0 / 3) do
                          caption "Time Left"
                          para "00:00:00"
                        end
                      end

                      flow(width: 1.0) do
                        stack(width: 1.0 / 3) do
                          caption "Region"
                          para "North America"
                        end
                        stack(width: 1.0 / 3) do
                          caption "Channel"
                          para "Release"
                        end
                        stack(width: 1.0 / 3) do
                          caption "Version"
                          para "3.8.1.0"
                        end
                      end
                    end

                    # team data
                    2.times do |i|
                      stack(width: 1.0, margin_top: PADDING, padding: HALF_PADDING, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: ALPHA_GRAY) do
                        tagline "TEAM #{i}"

                        flow(width: 1.0) do
                          stack(width: 1 / 4.0) do
                            caption "Score"
                            para "450,000"
                          end
                          stack(width: 1 / 4.0) do
                            caption "Kills"
                            para "4,500"
                          end
                          stack(width: 1 / 4.0) do
                            caption "Deaths"
                            para "450"
                          end
                          stack(width: 1 / 4.0) do
                            caption "Players"
                            para "45/127"
                          end
                        end

                        flow(width: 1.0, height: 2, background: 0xaa_000000)

                        flow(width: 1.0) do
                          stack(fill: true) do
                            caption "Name"
                          end
                          stack(width: 1 / 6.0) do
                            caption "Score"
                          end
                          stack(width: 1 / 8.0) do
                            caption "Kills"
                          end
                          stack(width: 1 / 6.0) do
                            caption "Deaths"
                          end
                          stack(width: 1 / 8.0) do
                            caption "Ping"
                          end
                          stack(width: 1 / 6.0) do
                            caption "Time"
                          end
                        end

                        24.times do |i|
                          flow(width: 1.0, background: i.odd? ? 0 : 0xaa_000000) do
                            stack(fill: true, margin_right: HALF_PADDING) do
                              inscription ["[Dragon]rufeng", "PXD2000", "SteelGhost", "Winter_Spyder", "ChopBam", "cyberarm", "ChAoS", "Silverlight", "moonsense715test", "Name Goes Here Yall"].sample, text_wrap: :none
                            end
                            stack(width: 1 / 6.0) do
                              inscription "5,232", text_wrap: :none
                            end
                            stack(width: 1 / 8.0) do
                              inscription "341", text_wrap: :none
                            end
                            stack(width: 1 / 6.0) do
                              inscription "123", text_wrap: :none
                            end
                            stack(width: 1 / 8.0) do
                              inscription "431", text_wrap: :none
                            end
                            stack(width: 1 / 6.0) do
                              inscription "00:00:00", text_wrap: :none
                            end
                          end
                        end
                      end
                    end
                  end
                end

                # battleview/friends container
                @battleview_container = stack(width: 300, height: 1.0, margin_left: LARGE_PADDING, visible: false) do
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
