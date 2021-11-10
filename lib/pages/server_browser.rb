class W3DHub
  class Pages
    class ServerBrowser < Page
      def setup
        body.clear do
          stack(width: 1.0, height: 1.0, padding: 8) do
            stack(width: 1.0, height: 0.04) do
              inscription "<b>Filters</b>"
            end

            flow(width: 1.0, height: 0.06) do
              flow(width: 0.75, height: 1.0) do
                image "#{GAME_ROOT_PATH}/media/icons/ren.png", height: 1.0 do |img|
                  if img.style.color == 0xff_444444
                    img.style.color = 0xff_ffffff
                    img.style.default[:color] = 0xff_ffffff
                  else
                    img.style.color = 0xff_444444
                    img.style.default[:color] = 0xff_444444
                  end
                end
                image "#{GAME_ROOT_PATH}/media/icons/ecw.png", height: 1.0, margin_left: 32 do |img|
                  if img.style.color == 0xff_444444
                    img.style.color = 0xff_ffffff
                    img.style.default[:color] = 0xff_ffffff
                  else
                    img.style.color = 0xff_444444
                    img.style.default[:color] = 0xff_444444
                  end                end
                image "#{GAME_ROOT_PATH}/media/icons/ia.png", height: 1.0, margin_left: 32 do |img|
                  if img.style.color == 0xff_444444
                    img.style.color = 0xff_ffffff
                    img.style.default[:color] = 0xff_ffffff
                  else
                    img.style.color = 0xff_444444
                    img.style.default[:color] = 0xff_444444
                  end                end
                image "#{GAME_ROOT_PATH}/media/icons/apb.png", height: 1.0, margin_left: 32 do |img|
                  if img.style.color == 0xff_444444
                    img.style.color = 0xff_ffffff
                    img.style.default[:color] = 0xff_ffffff
                  else
                    img.style.color = 0xff_444444
                    img.style.default[:color] = 0xff_444444
                  end                end
                image "#{GAME_ROOT_PATH}/media/icons/tsr.png", height: 1.0, margin_left: 32, margin_right: 32 do |img|
                  if img.style.color == 0xff_444444
                    img.style.color = 0xff_ffffff
                    img.style.default[:color] = 0xff_ffffff
                  else
                    img.style.color = 0xff_444444
                    img.style.default[:color] = 0xff_444444
                  end                end
                para "Region"
                list_box items: ["Any", "North America", "Europe"], width: 0.25
              end

              flow(width: 0.249, height: 1.0) do
                inscription "Nickname:"
                inscription "Cyberarm"
                image "#{GAME_ROOT_PATH}/media/ui_icons/wrench.png", height: 16
              end
            end

            flow(width: 1.0, height: 0.9, margin_top: 16) do
              stack(width: 0.62, height: 1.0) do
                # Icon
                # Hostname
                # Current Map
                # Players
                # Ping
                flow(width: 1.0, height: 0.05) do
                  stack(width: 0.08) do
                  end

                  stack(width: 0.50, height: 1.0) do
                    para "<b>Hostname</b>", text_wrap: :none, width: 1.0
                  end

                  flow(width: 0.24, height: 1.0) do
                    para "<b>Current Map</b>", text_wrap: :none, width: 1.0
                  end

                  flow(width: 0.11, height: 1.0) do
                    para "<b>Players</b>", text_wrap: :none, width: 1.0
                  end

                  stack(width: 0.06) do
                    para "<b>Ping</b>", text_wrap: :none, width: 1.0
                  end
                end

                stack(width: 1.0, height: 0.95, scroll: true) do
                  15.times do |i|
                    server_container = flow(width: 1.0, height: 48, hover: { background: 0xff_555566 }, active: { background: 0xff_555588 }) do
                      background 0xff_333333 if i.odd?

                      image "#{GAME_ROOT_PATH}/media/icons/ren.png", width: 0.08, padding: 4

                      stack(width: 0.45, height: 1.0) do
                        inscription "<b>[W3DHub] GAME SERVER"

                        flow(width: 1.0, height: 1.0) do
                          inscription "Release", margin_right: 64, text_size: 14
                          inscription "North America", text_size: 14
                        end
                      end

                      flow(width: 0.30, height: 1.0) do
                        inscription "C&C_Vile_Facility_D3.mix"
                      end

                      flow(width: 0.1, height: 1.0) do
                        inscription "127/127"
                      end

                      image "#{GAME_ROOT_PATH}/media/ui_icons/signal3.png", width: 0.05, color: 0xff_008000
                    end

                    def server_container.hit_element?(x, y)
                      self if hit?(x, y)
                    end

                    server_container.subscribe(:clicked_left_mouse_button) do
                      populate_server_info(nil)
                    end
                  end
                end
              end

              @game_server_info_container = stack(width: 0.38, height: 1.0) do
                para "No server selected", width: 1.0, text_align: :center
              end
            end
          end
        end
      end

      def populate_server_info(server)
        @game_server_info_container.clear do
          stack(width: 1.0, height: 1.0, padding: 8) do
            stack(width: 1.0, height: 0.3) do
              flow(width: 1.0, height: 0.2) do
                image "#{GAME_ROOT_PATH}/media/icons/ia.png", height: 24
                tagline "[W3D Hub] GAME SERVER"
              end

              stack(width: 1.0, height: 0.25) do
                button "<b>Join Server</b>"
              end

              stack(width: 1.0, height: 0.55, margin_top: 16) do
                flow(width: 1.0, height: 0.33) do
                  inscription "<b>Game</b>", width: 0.4
                  inscription "GAME (branch)", width: 0.6
                end

                flow(width: 1.0, height: 0.33) do
                  inscription "<b>Map</b>", width: 0.4
                  inscription "C&C_Islands.mix", width: 0.6
                end

                flow(width: 1.0, height: 0.33) do
                  inscription "<b>Max Players</b>", width: 0.4
                  inscription "127", width: 0.6
                end
              end
            end

            flow(width: 1.0, height: 0.05) do
              stack(width: 0.5, height: 1.0) do
                para "<b>GDI</b>", width: 1.0, text_align: :center
              end

              stack(width: 0.5, height: 1.0) do
                para "<b>Nod</b>", width: 1.0, text_align: :center
              end
            end

            flow(width: 1.0, height: 0.65, scroll: true) do
              stack(width: 0.5) do
                15.times do |i|
                  flow(width: 1.0, height: 18) do
                    stack(width: 0.6, height: 1.0) do
                      inscription "Player Name #{i}", text_size: 14
                    end

                    stack(width: 0.4, height: 1.0) do
                      inscription "#{rand(1000..100000)}", text_size: 14, width: 1.0, text_align: :right
                    end
                  end
                end
              end

              stack(width: 0.5, border_thickness_left: 2, border_color_left: 0xff_000000) do
                45.times do |i|
                  flow(width: 1.0, height: 18) do
                    stack(width: 0.6, height: 1.0) do
                      inscription "Player Name #{i}", text_size: 14
                    end

                    stack(width: 0.4, height: 1.0) do
                      inscription "#{rand(1000..100000)}", text_size: 14, width: 1.0, text_align: :right
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
end
