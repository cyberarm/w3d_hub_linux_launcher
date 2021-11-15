class W3DHub
  class Pages
    class ServerBrowser < Page
      def setup
        @@server_list ||= []

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

                @server_list_container = stack(width: 1.0, height: 0.95, scroll: true) do
                  para "Fetching server list..."
                end
              end

              @game_server_info_container = stack(width: 0.38, height: 1.0) do
                para "No server selected", width: 1.0, text_align: :center
              end
            end
          end
        end

        fetch_server_list
      end

      def populate_server_list
        @server_list_container.clear do
          @@server_list.each_with_index do |server, i|
            server_container = flow(width: 1.0, height: 48, hover: { background: 0xff_555566 }, active: { background: 0xff_555588 }) do
              background 0xff_333333 if i.odd?

              image game_icon(server.game), width: 0.08, padding: 4

              stack(width: 0.45, height: 1.0) do
                inscription "<b>#{server&.status&.name}</b>"

                flow(width: 1.0, height: 1.0) do
                  inscription "Release", margin_right: 64, text_size: 14
                  inscription "#{server.region}", text_size: 14
                end
              end

              flow(width: 0.30, height: 1.0) do
                inscription "#{server&.status&.map}"
              end

              flow(width: 0.1, height: 1.0) do
                inscription "#{server&.status&.player_count}/#{server&.status&.max_players}"
              end

              case rand(0..478)
              when 0..60
                image "#{GAME_ROOT_PATH}/media/ui_icons/signal3.png", width: 0.05, color: 0xff_008000
              when 61..160
                image "#{GAME_ROOT_PATH}/media/ui_icons/signal2.png", width: 0.05, color: 0xff_804000
              else
                image "#{GAME_ROOT_PATH}/media/ui_icons/signal1.png", width: 0.05, color: 0xff_800000
              end
            end

            def server_container.hit_element?(x, y)
              self if hit?(x, y)
            end

            server_container.subscribe(:clicked_left_mouse_button) do
              populate_server_info(server)
            end
          end
        end
      end

      def populate_server_info(server)
        @game_server_info_container.clear do
          stack(width: 1.0, height: 1.0, padding: 8) do
            stack(width: 1.0, height: 0.3) do
              flow(width: 1.0, height: 0.2) do
                image game_icon(server.game), width: 0.05
                tagline server.status.name, width: 0.949, text_wrap: :none
              end

              stack(width: 1.0, height: 0.25) do
                button "<b>Join Server</b>", enabled: window.application_manager.installed?(server.game)
              end

              stack(width: 1.0, height: 0.55, margin_top: 16) do
                flow(width: 1.0, height: 0.33) do
                  inscription "<b>Game</b>", width: 0.28, text_wrap: :none
                  inscription "#{game_name(server.game)} (branch)", width: 0.71, text_wrap: :none
                end

                flow(width: 1.0, height: 0.33) do
                  inscription "<b>Map</b>", width: 0.28, text_wrap: :none
                  inscription server.status.map, width: 0.71, text_wrap: :none
                end

                flow(width: 1.0, height: 0.33) do
                  inscription "<b>Max Players</b>", width: 0.28, text_wrap: :none
                  inscription "#{server.status.max_players}", width: 0.71, text_wrap: :none
                end
              end
            end

            flow(width: 1.0, height: 0.05) do
              stack(width: 0.5, height: 1.0) do
                para "<b>#{server.status.teams[0].name}</b>", width: 1.0, text_align: :center
              end

              stack(width: 0.5, height: 1.0) do
                para "<b>#{server.status.teams[1].name}</b>", width: 1.0, text_align: :center
              end
            end

            flow(width: 1.0, height: 0.65, scroll: true) do
              stack(width: 0.5) do
                server.status.players.select { |ply| ply.team == 0 }.each do |player|
                  flow(width: 1.0, height: 18) do
                    stack(width: 0.6, height: 1.0) do
                      inscription player.nick, text_size: 14, text_wrap: :none
                    end

                    stack(width: 0.4, height: 1.0) do
                      inscription "#{player.score}", text_size: 14, width: 1.0, text_align: :right, text_wrap: :none
                    end
                  end
                end
              end

              stack(width: 0.5, border_thickness_left: 2, border_color_left: 0xff_000000) do
                server.status.players.select { |ply| ply.team == 1 }.each do |player|
                  flow(width: 1.0, height: 18) do
                    stack(width: 0.6, height: 1.0) do
                      inscription player.nick, text_size: 14, text_wrap: :none
                    end

                    stack(width: 0.4, height: 1.0) do
                      inscription "#{player.score}", text_size: 14, width: 1.0, text_align: :right, text_wrap: :none
                    end
                  end
                end
              end
            end
          end
        end
      end

      def fetch_server_list
        Thread.new do
          begin
            list = Api.server_list(2)

            if list
              @@server_list = list.sort_by! { |s| s&.status&.players.size }.reverse


              main_thread_queue << proc { populate_server_list }
            end
          rescue => e
            # Something went wrong!
            pp e
            @@server_list = []
          end
        end
      end

      def game_icon(game)
        "#{GAME_ROOT_PATH}/media/icons/#{game.nil? ? 'ren' : game}.png"
      end

      def game_name(game)
        case game
        when "ia"
          "Interim Apex"
        when "apb"
          "Red Alert: A Path Beyond"
        when "tsr"
          "Tiberian Sun: Reborn"
        when "ecw"
          "Expansive Civilian Warfare"
        else
          "C&C Renegade"
        end
      end
    end
  end
end
