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

              image game_icon(server.hostname), width: 0.08, padding: 4

              stack(width: 0.45, height: 1.0) do
                inscription "<b>#{server.hostname}</b>"

                flow(width: 1.0, height: 1.0) do
                  inscription "Release", margin_right: 64, text_size: 14
                  inscription "#{server.country}", text_size: 14
                end
              end

              flow(width: 0.30, height: 1.0) do
                inscription "#{server.map_name}"
              end

              flow(width: 0.1, height: 1.0) do
                inscription "#{server.player_count}/#{server.max_players}"
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
                image game_icon(server.hostname), width: 0.05
                tagline server.hostname, width: 0.949, text_wrap: :none
              end

              stack(width: 1.0, height: 0.25) do
                button "<b>Join Server</b>"
              end

              stack(width: 1.0, height: 0.55, margin_top: 16) do
                flow(width: 1.0, height: 0.33) do
                  inscription "<b>Game</b>", width: 0.4
                  inscription "#{game_name(server.hostname)} (branch)", width: 0.6
                end

                flow(width: 1.0, height: 0.33) do
                  inscription "<b>Map</b>", width: 0.4
                  inscription server.map_name, width: 0.6
                end

                flow(width: 1.0, height: 0.33) do
                  inscription "<b>Max Players</b>", width: 0.4
                  inscription "#{server.max_players}", width: 0.6
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
                server.players.select { |ply| ply.team == "GDI" || ply.team == "1" }.each do |player|
                  flow(width: 1.0, height: 18) do
                    stack(width: 0.6, height: 1.0) do
                      inscription player.name, text_size: 14
                    end

                    stack(width: 0.4, height: 1.0) do
                      inscription "#{player.score}", text_size: 14, width: 1.0, text_align: :right
                    end
                  end
                end
              end

              stack(width: 0.5, border_thickness_left: 2, border_color_left: 0xff_000000) do
                server.players.select { |ply| ply.team == "Nod" || ply.team == "0" }.each do |player|
                  flow(width: 1.0, height: 18) do
                    stack(width: 0.6, height: 1.0) do
                      inscription player.name, text_size: 14
                    end

                    stack(width: 0.4, height: 1.0) do
                      inscription "#{player.score}", text_size: 14, width: 1.0, text_align: :right
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
          response = Excon.get("https://api.cncnet.org/renegade?timeleft=&_players=1&website=")

          begin
            array = JSON.parse(response.body, symbolize_names: true)

            if array.size.positive?
              process_response(array)

              main_thread_queue << proc { populate_server_list }
            end
          rescue => e
            # Something went wrong!
            pp e
            @@server_list = []
          end
        end
      end

      def process_response(array)
        servers = []

        array.each do |server_data|
          players = []

          server_data[:players].each do |player_data|
            players << RenegadePlayer.new(
              player_data[:name],
              player_data[:team],
              player_data[:score],
              player_data[:kills],
              player_data[:deaths],
              player_data[:ping]
            )
          end

          servers << RenegadeServer.new(
            server_data[:country],
            server_data[:countrycode],
            server_data[:timeleft],
            server_data[:ip],
            Integer(server_data[:hostport]),
            server_data[:hostname],
            server_data[:mapname],
            server_data[:website],
            Integer(server_data[:numplayers]),
            Integer(server_data[:maxplayers]),
            server_data[:password] != "0",
            players
          )
        end

        @@server_list = servers.sort_by! { |s| s.player_count }.reverse
      end

      def game_icon(hostname)
        if hostname.include?("[W3DHub] Interim Apex")
          "#{GAME_ROOT_PATH}/media/icons/ia.png"
        elsif hostname.include?("[W3DHub] APB")
          "#{GAME_ROOT_PATH}/media/icons/apb.png"
        elsif hostname.include?("[W3DHub] TSR")
          "#{GAME_ROOT_PATH}/media/icons/tsr.png"
        elsif hostname.include?("Expansive Civilian Warfare")
          "#{GAME_ROOT_PATH}/media/icons/ecw.png"
        else
          "#{GAME_ROOT_PATH}/media/icons/ren.png"
        end
      end

      def game_name(hostname)
        if hostname.include?("[W3DHub] Interim Apex")
          "Interim Apex"
        elsif hostname.include?("[W3DHub] APB")
          "Red Alert: A Path Beyond"
        elsif hostname.include?("[W3DHub] TSR")
          "Tiberian Sun: Reborn"
        elsif hostname.include?("Expansive Civilian Warfare")
          "Expansive Civilian Warfare"
        else
          "C&C Renegade"
        end
      end
    end
  end
end
