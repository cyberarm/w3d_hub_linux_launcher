class W3DHub
  class Pages
    class ServerBrowser < Page
      def setup
        @server_locked_icons = {}

        @selected_server ||= nil
        @selected_color = 0xff_666655

        @filters = Store.settings[:server_list_filters] || {}
        @filter_region = Store.settings[:server_list_region] || "Any" # "Any", "North America", "Europe"

        Store.applications.games.each { |game| @filters[game.id.to_sym] = true if @filters[game.id.to_sym].nil? }

        body.clear do
          stack(width: 1.0, height: 1.0, padding: 8) do
            stack(width: 1.0, height: 0.04) do
              inscription "<b>#{I18n.t(:"server_browser.filters")}</b>"
            end

            flow(width: 1.0, height: 0.06) do
              flow(width: 0.75, height: 1.0) do
                @filters.each do |app_id, enabled|
                  app = Store.applications.games.find { |a| a.id == app_id.to_s }

                  image "#{GAME_ROOT_PATH}/media/icons/#{app_id}.png", tip: "#{app.name}", height: 1.0,
                        border_thickness_bottom: 1, border_color_bottom: 0x00_000000,
                        color: enabled ? 0xff_ffffff : 0xff_444444, hover: { border_color_bottom: 0xff_aaaaaa }, margin_right: 32 do |img|
                    @filters[app_id] = !@filters[app_id]
                    Store.settings[:server_list_filters] = @filters
                    Store.settings.save_settings

                    if @filters[app_id]
                      img.style.color = 0xff_ffffff
                      img.style.default[:color] = 0xff_ffffff
                    else
                      img.style.color = 0xff_444444
                      img.style.default[:color] = 0xff_444444
                    end

                    populate_server_list
                  end
                end

                para I18n.t(:"server_browser.region")
                list_box items: ["Any", "North America", "Europe"], choose: Store.settings[:server_list_region], width: 0.25 do |value|
                  @filter_region = value
                  Store.settings[:server_list_region] = @filter_region
                  Store.settings.save_settings

                  populate_server_list
                end
              end

              flow(width: 0.249, height: 1.0) do
                inscription "#{I18n.t(:"server_browser.nickname")}:", width: 0.32
                @nickname_label = inscription "#{Store.settings[:server_list_username]}", width: 0.6
                image "#{GAME_ROOT_PATH}/media/ui_icons/wrench.png", height: 16, hover: { color: 0xaa_ffffff }, tip: I18n.t(:"server_browser.set_nickname") do
                  # Prompt for player name
                  prompt_for_nickname(
                    accept_callback: proc do |entry|
                      @nickname_label.value = entry
                      Store.settings[:server_list_username] = entry
                      Store.settings.save_settings
                    end
                  )
                end
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
                    para "<b>#{I18n.t(:"server_browser.hostname")}</b>", text_wrap: :none, width: 1.0
                  end

                  flow(width: 0.24, height: 1.0) do
                    para "<b>#{I18n.t(:"server_browser.current_map")}</b>", text_wrap: :none, width: 1.0
                  end

                  flow(width: 0.11, height: 1.0) do
                    para "<b>#{I18n.t(:"server_browser.players")}</b>", text_wrap: :none, width: 1.0
                  end

                  stack(width: 0.06) do
                    para "<b>#{I18n.t(:"server_browser.ping")}</b>", text_wrap: :none, width: 1.0
                  end
                end

                @server_list_container = stack(width: 1.0, height: 0.95, scroll: true) do
                  para I18n.t(:"server_browser.fetching_server_list")
                end
              end

              @game_server_info_container = stack(width: 0.38, height: 1.0) do
                para I18n.t(:"server_browser.no_server_selected"), width: 1.0, text_align: :center
              end
            end
          end
        end

        if Store.server_list.empty?
          fetch_server_list
        else
          populate_server_list
        end
      end

      def populate_server_list
        @server_list_container.scroll_top = 0

        @server_list_container.clear do
          i = -1

          Store.server_list.each do |server|
            next unless @filters[server.game.to_sym]
            next unless server.region == @filter_region || @filter_region == "Any"

            i += 1

            server_container = flow(width: 1.0, height: 48, hover: { background: 0xff_555566 }, active: { background: 0xff_555588 }) do
              background 0xff_333333 if i.odd?

              image game_icon(server), width: 0.08, padding: 4

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

              # case rand(0..478)
              # when 0..60
              #   image "#{GAME_ROOT_PATH}/media/ui_icons/signal3.png", width: 0.05, color: 0xff_008000
              # when 61..160
              #   image "#{GAME_ROOT_PATH}/media/ui_icons/signal2.png", width: 0.05, color: 0xff_804000
              # else
              #   image "#{GAME_ROOT_PATH}/media/ui_icons/signal1.png", width: 0.05, color: 0xff_800000
              # end

              image "#{GAME_ROOT_PATH}/media/ui_icons/question.png", width: 0.05, color: 0xff_444444
            end

            def server_container.hit_element?(x, y)
              self if hit?(x, y)
            end

            server_container.subscribe(:clicked_left_mouse_button) do
              if @selected_server
                @selected_server.style.background = @selected_server.style.server_item_background
                @selected_server.style.default[:background] = @selected_server.style.server_item_background
                @selected_server.style.hover[:background] = @selected_server.style.server_item_hover_background
                @selected_server.style.active[:background] = @selected_server.style.server_item_active_background
              end

              server_container.style.server_item_background = server_container.style.default[:background]
              server_container.style.server_item_hover_background = server_container.style.hover[:background]
              server_container.style.server_item_active_background = server_container.style.active[:background]
              server_container.style.background = @selected_color
              server_container.style.default[:background] = @selected_color
              server_container.style.hover[:background] = @selected_color
              server_container.style.active[:background] = @selected_color

              @selected_server = server_container

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
                image game_icon(server), width: 0.05
                tagline server.status.name, width: 0.949, text_wrap: :none
              end

              stack(width: 1.0, height: 0.25) do
                game_installed = Store.application_manager.installed?(server.game, Store.applications.games.find { |g| g.id == server.game }.channels.first.id)

                button "<b>#{I18n.t(:"server_browser.join_server")}</b>", enabled: !game_installed.nil? do
                  # Check for nickname
                  #   prompt for nickname
                  # !abort unless nickname set
                  # Check if password needed
                  #   prompt for password
                  # Launch game
                  if Store.settings[:server_list_username].to_s.length.zero?
                    prompt_for_nickname(
                      accept_callback: proc do |entry|
                        @nickname_label.value = entry
                        Store.settings[:server_list_username] = entry
                        Store.settings.save_settings

                        if server.status.password
                          prompt_for_password(
                            accept_callback: proc do |password|
                              join_server(server, password)
                            end
                          )
                        else
                          join_server(server, nil)
                        end
                      end
                    )
                  else
                    if server.status.password
                      prompt_for_password(
                        accept_callback: proc do |password|
                          join_server(server, password)
                        end
                      )
                    else
                      join_server(server, nil)
                    end
                  end
                end
              end

              stack(width: 1.0, height: 0.55, margin_top: 16) do
                flow(width: 1.0, height: 0.33) do
                  inscription "<b>#{I18n.t(:"server_browser.game")}</b>", width: 0.28, text_wrap: :none
                  inscription "#{game_name(server.game)} (branch)", width: 0.71, text_wrap: :none
                end

                flow(width: 1.0, height: 0.33) do
                  inscription "<b>#{I18n.t(:"server_browser.map")}</b>", width: 0.28, text_wrap: :none
                  inscription server.status.map, width: 0.71, text_wrap: :none
                end

                flow(width: 1.0, height: 0.33) do
                  inscription "<b>#{I18n.t(:"server_browser.max_players")}</b>", width: 0.28, text_wrap: :none
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
                server.status.players.select { |ply| ply.team == 0 }.sort_by { |ply| ply.score }.reverse.each do |player|
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
                server.status.players.select { |ply| ply.team == 1 }.sort_by { |ply| ply.score }.reverse.each do |player|
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
              Store.server_list = list.sort_by! { |s| s&.status&.players&.size }.reverse


              main_thread_queue << proc { populate_server_list }
            end
          rescue => e
            # Something went wrong!
            pp e
            Store.server_list = []
          end
        end
      end

      def game_icon(server)
        if server.status.password
          @server_locked_icons[server.game] ||= Gosu.render(96, 96) do
            i = get_image("#{GAME_ROOT_PATH}/media/icons/#{server.game.nil? ? 'ren' : server.game}.png")
            lock = get_image("#{GAME_ROOT_PATH}/media/ui_icons/locked.png")
            scale = [96.0 / i.width, 96.0 / i.height].min

            i.draw(0, 0, 0, scale, scale)
            lock.draw(96 - lock.width * 0.5, 96 - lock.height * 0.5, 0, 0.5, 0.5, 0xff_ff8800)
          end
        else
          "#{GAME_ROOT_PATH}/media/icons/#{server.game.nil? ? 'ren' : server.game}.png"
        end
      end

      def game_name(game)
        Store.applications.games.detect { |g| g.id == game }&.name
      end

      def prompt_for_nickname(accept_callback: nil, cancel_callback: nil)
        push_state(
          W3DHub::States::PromptDialog,
          title: I18n.t(:"server_browser.set_nickname"),
          message: I18n.t(:"server_browser.set_nickname_message"),
          prefill: Store.settings[:server_list_username],
          accept_callback: accept_callback,
          cancel_callback: cancel_callback,
          valid_callback: proc { |entry| entry.length.positive? }
        )
      end

      def prompt_for_password(accept_callback: nil, cancel_callback: nil)
        push_state(
          W3DHub::States::PromptDialog,
          title: I18n.t(:"server_browser.enter_password"),
          message: I18n.t(:"server_browser.enter_password_message"),
          input_type: :password,
          accept_callback: accept_callback,
          cancel_callback: cancel_callback,
          valid_callback: proc { |entry| entry.length.positive? }
        )
      end

      def join_server(server, password)
        if (
          (server.status.password && password.length.positive?) ||
          !server.status.password) &&
           Store.settings[:server_list_username].to_s.length.positive?

          Store.application_manager.join_server(
            server.game,
            Store.applications.games.find { |g| g.id == server.game }.channels.first.id, server, password
          )
        else
          window.push_state(W3DHub::States::MessageDialog, type: "?", title: "?", message: "?")
        end
      end
    end
  end
end
