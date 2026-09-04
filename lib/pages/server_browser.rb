module W3DHubLauncher
  module Page
    class ServerBrowser < CyberarmEngine::Page
      include GuiExt

      def setup
        @games_filter = []

        # game bar container
        flow(width: 1.0, height: 60) do
          widget(width: 220, height: 1.0, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: ALPHA_GRAY, hover: { background_nine_slice_color: ALPHA_BLACK }, active: { background_nine_slice_color: ALPHA_GRAY }) do |w|
            flow(width: 1.0, height: 40, margin_left: PADDING, v_align: :center, h_align: :center) do
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

              image(safe_get_image("#{ROOT_PATH}/data/cache/#{app.id}.png"), height: 1.0, padding: HALF_PADDING, background_nine_slice: NINE_SLICE_ROUNDED_TOP, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0x88_5e5c64, border_thickness_bottom: 3, border_color_bottom: 0xff_3584e4, tip: app.name) do |btn|
                if shift_down?
                  @games_filter << app.id
                  @games_filter.uniq!
                else
                  @games_filter.clear
                  @games_filter << app.id
                end

                populate_server_list
              end
              # image safe_get_image("#{ROOT_PATH}/data/cache/ren.png"), height: 1.0, padding: HALF_PADDING, background_nine_slice: NINE_SLICE_ROUNDED_TOP, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0, tip: "Command & Conquer: Renegade"
              # image safe_get_image("#{ROOT_PATH}/data/cache/tsr.png"), height: 1.0, padding: HALF_PADDING, background_nine_slice: NINE_SLICE_ROUNDED_TOP, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0, tip: "Tiberian Sun: Reborn"
              # image safe_get_image("#{ROOT_PATH}/data/cache/woa.png"), height: 1.0, padding: HALF_PADDING, background_nine_slice: NINE_SLICE_ROUNDED_TOP, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0, tip: "Battle for Dune: War of Assassins"
            end
          end
        end

        # game content container
        @servers_container = stack(width: 1.0, fill: true, margin_top: LARGE_PADDING, scroll: true) do
        end

        # FIXME: Remember and use last used filter
        populate_server_list
      end

      def populate_server_list
        @servers_container.clear do
          (MemCache[:servers] || []).select { |s| @games_filter.empty? ? true : @games_filter.include?(s.game) }.sort_by { |s| s.player_count }.reverse.each do |server|
            app = MemCache[:applications].find { |a| a.id == server.game }

            widget(width: 1.0, height: 48, padding_top: HALF_PADDING, padding_bottom: HALF_PADDING, margin_bottom: HALF_PADDING, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: server.channel == "release" ? ALPHA_GRAY : 0xaa_c64600, hover: { background_nine_slice_color: 0xff_5e5c64 } , active: { background_nine_slice_color: 0xaa_5e5c64 }) do
              # app icon container
              image(safe_get_image("#{ROOT_PATH}/data/cache/#{app.id}.png"), tip: app.name, width: 48, height: 1.0, margin_left: HALF_PADDING)

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
                  caption rand > 0.85 ? "?" : format("%d ms", rand(16..360)), width: 1.0, text_align: :center
                  inscription "ping", text_wrap: :none, width: 1.0, text_align: :center, margin_top: -HALF_PADDING
                end
                stack(width: 8, height: rand(0.25..1.0), v_align: :center, min_height: 8, background_nine_slice: NINE_SLICE_ROUNDED_SMALL, background_nine_slice_from_edge: NINE_SLICE_EDGE_SMALL, background_nine_slice_color: [0xff_26a269, 0xff_e5a50a, 0xff_a51d2d, 0xff_3d3846].sample)
              end
            end
          end
        end
      end
    end
  end
end
