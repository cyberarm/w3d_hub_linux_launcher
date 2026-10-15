module W3DHubLauncher
  class Dialog
    class Server < W3DHubLauncher::Dialog
      def setup
        super

        application = @options[:application]
        server = @options[:server]

        stack(width: 1.0, max_width: 600, height: 1.0, max_height: 600, style_class: [:dialog]) do
          flow(width: 1.0, background_nine_slice: NINE_SLICE_ROUNDED_TOP, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0) do
            banner "Join Server", width: 1.0, text_align: :center
            title  server.name, width: 1.0, text_align: :center
          end

          stack(style_class: [:dialog_container]) do
            caption "Ping: #{server.ping}ms"
            caption "Region: #{server.region}"
            caption "Players: #{server.player_count} / #{server.max_players}", margin_bottom: HALF_PADDING

            caption "Current Map: #{server.current_map}"
            caption "Next Map: #{server.next_map}", margin_bottom: HALF_PADDING

            caption "Time Elapsed: #{server.time_elapsed}"
            caption "Time Remaining: #{server.time_remaining}"
          end

          flow(width: 1.0, padding: PADDING, background_nine_slice: NINE_SLICE_ROUNDED_BOTTOM, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0) do
            button "Cancel" do
              pop_state
            end

            flow(fill: true)

            button "Join", **CTA_BUTTON_THEME do
              pop_state
              ApplicationHelper.join_server(application, server)
            end
          end
        end
      end
    end
  end
end
