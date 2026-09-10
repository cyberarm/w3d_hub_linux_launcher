module W3DHubLauncher
  module Page
    class ServerBrowser < CyberarmEngine::Page
      include GuiExt

      def setup
        @games_filter = []

        CyberarmEngine::EventBus.subscribe("game_server_pings", self, :handle_game_server_pings)

        # game bar container
        flow(width: 1.0, height: 60) do
          widget(width: 220, height: 1.0, style_class: [:all_button]) do |w|
            flow(width: 1.0, height: 40, margin_left: PADDING, v_align: :center) do
              image safe_get_image("#{ROOT_PATH}/media/icons/menuGrid.png"), height: 40, color: 0xff_bbbbbb
              link "ALL SERVERS", text_size: 24, font: FONT_BLACK, height: 1.0, text_v_align: :center
            end

            w.subscribe(:clicked_left_mouse_button) do
              @games_filter.clear
              populate_server_list
            end
          end

          flow(fill: true, height: 1.0, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: ALPHA_GRAY, margin_left: PADDING) do
            MemCache[:applications].each do |app|
              next unless app.game?

              button(safe_get_image("#{CACHE_PATH}/icon_#{app.id}.png"), style_class: [:app_icon_button], tip: app.name) do |btn|
                if shift_down?
                  @games_filter << app.id
                  @games_filter.uniq!
                else
                  @games_filter.clear
                  @games_filter << app.id
                end

                btn.enabled = false

                populate_server_list
              end
            end
          end
        end

        # game content container
        @servers_container = stack(width: 1.0, fill: true, margin_top: LARGE_PADDING, scroll: true) do
        end

        # FIXME: Remember and use last used filter
        populate_server_list
      end

      def blur
        CyberarmEngine::EventBus.unsubscribe("game_server_pings", self)
      end

      def handle_game_server_pings(payload)
        # TODO: Update displayed server ping
      end

      def populate_server_list
        @servers_container.clear do
          (MemCache[:servers] || []).select { |s| @games_filter.empty? ? true : @games_filter.include?(s.game) }.sort_by { |s| [s.player_count, -s.ping] }.reverse.each do |server|
            app = MemCache[:applications].find { |a| a.id == server.game }

            widget(width: 1.0, height: 48, padding_top: HALF_PADDING, padding_bottom: HALF_PADDING, margin_bottom: HALF_PADDING, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: server.channel == "release" ? ALPHA_GRAY : 0xaa_c64600, hover: { background_nine_slice_color: 0xff_5e5c64 } , active: { background_nine_slice_color: 0xaa_5e5c64 }) do
              # app icon container
              image(safe_get_image("#{CACHE_PATH}/icon_#{app.id}.png"), tip: app.name, width: 48, height: 1.0, margin_left: HALF_PADDING)

              # server name, region, and times container
              stack(fill: true, height: 1.0, margin_left: HALF_PADDING) do
                stack(v_align: :center) do
                  # server name
                  caption server.name, text_wrap: :none, tip: server.name
                  # server info
                  inscription "#{server.channel} • #{server.region} • #{server.time_elapsed} / #{server.match_remaining_time}", text_wrap: :none, margin_top: -HALF_PADDING
                end
              end

              # server map
              stack(width: 256, height: 1.0, margin_left: HALF_PADDING) do
                stack(width: 1.0, fill: true, v_align: :center) do
                  caption server.current_map, tip: server.current_map, text_wrap: :none, width: 1.0, text_align: :center
                  inscription "map", text_wrap: :none, width: 1.0, text_align: :center, margin_top: -HALF_PADDING
                end
              end

              # server player count
              stack(width: 96, height: 1.0, margin_left: HALF_PADDING) do
                stack(width: 1.0, fill: true, v_align: :center) do
                  caption format("%d / %d", server.player_count, server.max_players), width: 1.0, text_align: :center
                  inscription "players", text_wrap: :none, width: 1.0, text_align: :center, margin_top: -HALF_PADDING
                end
              end

              # server ping
              flow(width: 96, height: 1.0, margin_left: HALF_PADDING, margin_right: HALF_PADDING) do
                stack(fill: true, height: 1.0, v_align: :center) do
                  caption server.ping == Worker::Api::GameServer::BAD_OR_UNKNOWN_PING ? "?" : format("%ims", server.ping), width: 1.0, text_align: :center, tip: server.ping == Worker::Api::GameServer::BAD_OR_UNKNOWN_PING ? "Server has not replied yet or did not reply to ICMP Echo Request.\nPing unknown." : ""
                  inscription "ping", text_wrap: :none, width: 1.0, text_align: :center, margin_top: -HALF_PADDING
                end
                stack(width: 8, height: server.ping_score_ratio, v_align: :center, min_height: 8, background_nine_slice: NINE_SLICE_ROUNDED_SMALL, background_nine_slice_from_edge: NINE_SLICE_EDGE_SMALL, background_nine_slice_color: server.ping_score_color)
              end
            end
          end
        end
      end
    end
  end
end
