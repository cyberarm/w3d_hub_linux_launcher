module W3DHubLauncher
  module Page
    class ServerBrowser < CyberarmEngine::Page
      include GuiExt

      def setup
        # game bar container
        flow(width: 1.0, height: 60) do
          flow(width: 220, height: 1.0, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: ALPHA_GRAY) do
            flow(width: 1.0, height: 40, margin_left: PADDING, v_align: :center, h_align: :center) do
              image safe_get_image("#{ROOT_PATH}/media/icons/menuGrid.png"), height: 40, color: 0xff_bbbbbb
              link "ALL SERVERS", text_size: 24, font: FONT_BLACK, height: 1.0, text_v_align: :center
            end
          end

          flow(fill: true, height: 1.0, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: ALPHA_GRAY, margin_left: PADDING) do
            image safe_get_image("#{ROOT_PATH}/data/cache/apb.png"), height: 1.0, padding: HALF_PADDING, background_nine_slice: NINE_SLICE_ROUNDED_TOP, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0x88_5e5c64, border_thickness_bottom: 3, border_color_bottom: 0xff_3584e4, tip: "Red Alert: A Path Beyond"
            image safe_get_image("#{ROOT_PATH}/data/cache/ren.png"), height: 1.0, padding: HALF_PADDING, background_nine_slice: NINE_SLICE_ROUNDED_TOP, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0, tip: "Command & Conquer: Renegade"
            image safe_get_image("#{ROOT_PATH}/data/cache/tsr.png"), height: 1.0, padding: HALF_PADDING, background_nine_slice: NINE_SLICE_ROUNDED_TOP, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0, tip: "Tiberian Sun: Reborn"
            image safe_get_image("#{ROOT_PATH}/data/cache/woa.png"), height: 1.0, padding: HALF_PADDING, background_nine_slice: NINE_SLICE_ROUNDED_TOP, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0, tip: "Battle for Dune: War of Assassins"
          end
        end

        # game content container
        stack(width: 1.0, fill: true, margin_top: LARGE_PADDING, scroll: true) do
          10.times do
            widget(width: 1.0, height: 48, padding_top: HALF_PADDING, padding_bottom: HALF_PADDING, margin_bottom: HALF_PADDING, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: ALPHA_GRAY, hover: { background_nine_slice_color: 0xff_5e5c64 } , active: { background_nine_slice_color: 0xaa_5e5c64 }) do
              # app icon container
              image(safe_get_image("#{ROOT_PATH}/data/cache/apb.png"), tip: "Red Alert: A Path Beyond", width: 48, height: 1.0, margin_left: HALF_PADDING)
              # friend name and status container
              stack(fill: true, height: 1.0, margin_left: HALF_PADDING) do
                stack(v_align: :center) do
                  # server name
                  server_name = ["Really Long Server Name Goes Here", "[US][W3D Hub] APB Game Night", "[US][W3D Hub] APB Co-op 3.7", "Really Long Server Name Goes Here Really Long Server Name Goes Here"].sample
                  caption server_name, text_wrap: :none, tip: server_name
                  # server info
                  a = ["North America", "South America", "Europe", "Asia", "Antarctica", "Arctica", "Oceania"]
                  inscription "#{a.sample} • 13:52 / #{rand > 0.5 ? '∞' : '30:00'}", text_wrap: :none, margin_top: -HALF_PADDING
                end
              end
              # server map
              stack(width: 256, height: 1.0, margin_left: HALF_PADDING) do
                stack(width: 1.0, fill: true, v_align: :center) do
                  server_map = ["RA_Under", "C&C Superduple Long Map Name Goes Here", "RA_NorthByNorthWest", "RA_HostileWatersParadox", "RA_PacificThreat"].sample
                  caption server_map, tip: server_map, text_wrap: :none, width: 1.0, text_align: :center
                  inscription "map", text_wrap: :none, width: 1.0, text_align: :center, margin_top: -HALF_PADDING
                end
              end

              # server player count
              stack(width: 96, height: 1.0, margin_left: HALF_PADDING) do
                stack(width: 1.0, fill: true, v_align: :center) do
                  caption format("%d / %d", rand(60), rand(60..127)), width: 1.0, text_align: :center
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
