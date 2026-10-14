module W3DHubLauncher
  module Page
    class ServerBrowser < CyberarmEngine::Page
      include GuiExt

      def setup
        @games_filter = []

        # game bar container
        flow(width: 1.0, height: 60) do
          widget(width: 220, height: 1.0, style_class: [:all_button]) do |w|
            flow(width: 1.0, height: 40, margin_left: PADDING, v_align: :center) do
              image safe_get_image("#{ROOT_PATH}/media/icons/menuGrid.png"), height: 40, color: 0xff_bbbbbb
              link "ALL SERVERS", text_size: 24, font: FONT_BLACK, height: 1.0, text_v_align: :center
            end

            w.subscribe(:clicked_left_mouse_button) do
              @games_filter.clear
              @app_filters_container.children.each { |c| c.enabled = true }
              populate_server_list
            end
          end

          @app_filters_container = flow(fill: true, height: 1.0, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: ALPHA_GRAY, margin_left: PADDING) do
            MemCache[:applications].each do |app|
              next unless app.game?

              button(safe_get_image("#{CACHE_PATH}/icon_#{app.id}.png"), style_class: [:app_icon_button], tag: :"app_filter_#{app.id}", tip: app.name) do |btn|
                if shift_down?
                  @games_filter << app.id
                  @games_filter.uniq!
                else
                  @games_filter.clear
                  @games_filter << app.id
                end

                buttons = btn.parent.children
                filters = @games_filter.map { |f| :"app_filter_#{f}" }
                buttons.each { |e| e.enabled = !filters.include?(e.style.tag) }

                btn.enabled = false

                populate_server_list
              end
            end
          end

          button(safe_get_image("#{ROOT_PATH}/media/icons/target.png"), image_height: 1.0, tip: "Direct Connect", padding: HALF_PADDING, enabled: false, margin_left: PADDING) do
            dialog(Dialog::DirectConnect)
          end
        end

        # game content container
        @servers_container = stack(width: 1.0, fill: true, margin_top: LARGE_PADDING, scroll: true) do
        end

        # FIXME: Remember and use last used filter
        populate_server_list
      end

      def focus
        CyberarmEngine::EventBus.subscribe("game_server_pings", self, :handle_game_server_pings)

        CyberarmEngine::EventBus.subscribe("game_server_list", self, :handle_game_server_list)
        CyberarmEngine::EventBus.subscribe("game_server_added", self, :handle_game_server_updated) # <- not a typo
        CyberarmEngine::EventBus.subscribe("game_server_updated", self, :handle_game_server_updated)
        CyberarmEngine::EventBus.subscribe("game_server_removed", self, :handle_game_server_removed)

        @parent.show_server_details_panel
      end

      def blur
        CyberarmEngine::EventBus.unsubscribe("game_server_pings", self)

        CyberarmEngine::EventBus.unsubscribe("game_server_list", self)
        CyberarmEngine::EventBus.unsubscribe("game_server_added", self)
        CyberarmEngine::EventBus.unsubscribe("game_server_updated", self)
        CyberarmEngine::EventBus.unsubscribe("game_server_removed", self)

        @parent.hide_server_details_panel
      end

      def handle_game_server_pings(payload)
        addresses = payload.keys

        MemCache[:servers]&.select { |s| addresses.include?(s.address) }&.each do |server|
          w = find_element_by_tag(@servers_container, :"server_#{server.id}")
          ping_label = find_element_by_tag(w, :ping_label)
          ping_bar = find_element_by_tag(w, :ping_bar)

          ping_label&.value =  format("%ims", payload[server.address])
          ping_label&.tip =  ""

          if ping_bar
            ping_bar.style.height = server.ping_score_ratio
            ping_bar.style.background_nine_slice_color = server.ping_score_color
            ping_bar.recalculate
          end
        end

        # TODO: Sort servers?
      end

      def handle_game_server_list
        after(1_000) do
          populate_server_list
        end
      end

      def handle_game_server_updated(payload)
        game_server = Worker::Api::GameServer.new(payload)

        w = find_element_by_tag(@servers_container, :"server_#{game_server.id}")
        if w
          # update existing server widget
          name_label = find_element_by_tag(w, :name_label)
          info_label = find_element_by_tag(w, :info_label)
          map_label = find_element_by_tag(w, :map_label)
          players_label = find_element_by_tag(w, :players_label)

          name_label&.value = game_server.name
          name_label&.tip = game_server.name
          info_label&.value = "#{game_server.channel} • #{game_server.region} • #{game_server.time_elapsed} / #{game_server.match_remaining_time}"
          map_label&.value = game_server.current_map
          map_label&.tip = game_server.current_map
          players_label&.value = format("%d / %d", game_server.player_count, game_server.max_players)

        # ensure we don't add servers that are meant to be filtered out
        elsif @games_filter.empty? || @games_filter.include?(game_server.game)
          @servers_container.append do
            populate_server(game_server)
          end
        end

        # TODO: Sort servers?
      end

      def handle_game_server_removed(payload)
        w = find_element_by_tag(@servers_container, :"server_#{payload["id"]}")
        @servers_container.remove(w)
      end

      def populate_server_list
        @servers_container.clear do
          (MemCache[:servers] || []).select { |s| @games_filter.empty? ? true : @games_filter.include?(s.game) }.sort_by { |s| [s.player_count, -s.ping] }.reverse.each do |server|
            populate_server(server)
          end
        end
      end

      def populate_server(server)
        app = MemCache[:applications].find { |a| a.id == server.game }

        widget(tag: :"server_#{server.id}", width: 1.0, height: 56 + PADDING, padding_top: HALF_PADDING, padding_bottom: HALF_PADDING, margin_bottom: HALF_PADDING, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: server.channel == "release" ? ALPHA_GRAY : 0xaa_c64600, hover: { background_nine_slice_color: 0xff_5e5c64 } , active: { background_nine_slice_color: 0xaa_5e5c64 }) do |w|
          # app icon container
          image(safe_get_image("#{CACHE_PATH}/icon_#{app.id}.png"), tip: app.name, width: 56, height: 1.0, margin_left: HALF_PADDING)

          # server name, region, and times container
          stack(fill: true, height: 1.0, margin_left: HALF_PADDING) do
            stack(width: 1.0, v_align: :center) do
              # server name
              caption server.name, tag: :name_label, text_wrap: :none, tip: server.name
              # server info
              inscription "#{server.channel} • #{server.region} • #{server.time_elapsed} / #{server.match_remaining_time}", tag: :info_label, text_wrap: :none, margin_top: -HALF_PADDING
            end
          end

          # server map
          stack(width: 256, height: 1.0, margin_left: HALF_PADDING) do
            stack(width: 1.0, fill: true, v_align: :center) do
              caption server.current_map, tag: :map_label, tip: server.current_map, text_wrap: :none, width: 1.0, text_align: :center
              inscription "map", text_wrap: :none, width: 1.0, text_align: :center, margin_top: -HALF_PADDING
            end
          end

          # server player count
          stack(width: 96, height: 1.0, margin_left: HALF_PADDING) do
            stack(width: 1.0, fill: true, v_align: :center) do
              caption format("%d / %d", server.player_count, server.max_players), tag: :players_label, width: 1.0, text_align: :center
              inscription "players", text_wrap: :none, width: 1.0, text_align: :center, margin_top: -HALF_PADDING
            end
          end

          # server ping
          flow(width: 96, height: 1.0, margin_left: HALF_PADDING, margin_right: HALF_PADDING) do
            stack(fill: true, height: 1.0, v_align: :center) do
              caption server.ping == Worker::Api::GameServer::BAD_OR_UNKNOWN_PING ? "?" : format("%ims", server.ping), tag: :ping_label, width: 1.0, text_align: :center, tip: server.ping == Worker::Api::GameServer::BAD_OR_UNKNOWN_PING ? "Server has not replied yet or did not reply to ICMP Echo Request.\nPing unknown." : ""
              inscription "ping", text_wrap: :none, width: 1.0, text_align: :center, margin_top: -HALF_PADDING
            end
            stack(width: 8, height: server.ping_score_ratio, tag: :ping_bar, v_align: :center, min_height: 8, background_nine_slice: NINE_SLICE_ROUNDED_SMALL, background_nine_slice_from_edge: NINE_SLICE_EDGE_SMALL, background_nine_slice_color: server.ping_score_color)
          end

          w.subscribe(:clicked_left_mouse_button) do
            @parent.populate_server_information(server)
          end
        end
      end
    end
  end
end
