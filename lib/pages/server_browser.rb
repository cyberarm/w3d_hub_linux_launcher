class W3DHub
  class Pages
    class ServerBrowser < Page
      def setup
        @server_locked_icons = {}
        @refresh_server_list = false
        refresh_server = false

        @selected_server ||= nil
        @selected_server_container ||= nil
        @selected_color = 0xff_666655

        @filters = Store.settings[:server_list_filters] || {}
        @filter_region = Store.settings[:server_list_region] || "Any" # "Any", "North America", "Europe"

        Store.applications.games.each { |game| @filters[game.id.to_sym] = true if @filters[game.id.to_sym].nil? }

        body.clear do
          stack(width: 1.0, height: 1.0, padding: 8) do
            stack(width: 1.0, height: 18) do
              inscription "<b>#{I18n.t(:"server_browser.filters")}</b>"
            end

            flow(width: 1.0, height: 32) do
              flow(width: 128, height: 1.0) do
                # para I18n.t(:"server_browser.region"), width: 0.5
                list_box items: ["Any", "North America", "Europe"], choose: Store.settings[:server_list_region], width: 1.0, height: 1.0, padding_top: 4, padding_bottom: 4 do |value|
                  @filter_region = value
                  Store.settings[:server_list_region] = @filter_region
                  Store.settings.save_settings

                  populate_server_list
                end
              end

              flow(fill: true, height: 1.0) do
                @filters.each do |app_id, enabled|
                  app = Store.applications.games.find { |a| a.id == app_id.to_s }
                  next unless app

                  image_path = File.exist?("#{GAME_ROOT_PATH}/media/icons/#{app_id}.png") ? "#{GAME_ROOT_PATH}/media/icons/#{app_id}.png" : "#{GAME_ROOT_PATH}/media/icons/default_icon.png"

                  image image_path, tip: "#{app.name}", height: 1.0,
                        border_thickness_bottom: 1, border_color_bottom: 0x00_000000,
                        color: enabled ? 0xff_ffffff : 0xff_444444, hover: { border_color_bottom: 0xff_aaaaaa }, margin_left: 16 do |img|
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

                # button get_image("#{GAME_ROOT_PATH}/media/ui_icons/return.png"), tip: I18n.t(:"server_browser.refresh"), image_height: 1.0, margin_left: 16, padding_left: 2, padding_right: 2, padding_top: 2, padding_bottom: 2 do
                #   fetch_server_list
                # end
              end

              flow(min_width: 372, width: 0.38, max_width: 512, height: 1.0) do
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

            flow(width: 1.0, fill: true, margin_top: 16) do
              stack(fill: true, height: 1.0) do
                # Icon
                # Hostname
                # Current Map
                # Players
                # Ping
                flow(width: 1.0, height: 24) do
                  stack(width: 48, padding: 4) do
                  end

                  stack(width: 0.45, height: 1.0) do
                    para "<b>#{I18n.t(:"server_browser.hostname")}</b>", text_wrap: :none, width: 1.0
                  end

                  flow(fill: true, height: 1.0) do
                    para "<b>#{I18n.t(:"server_browser.current_map")}</b>", text_wrap: :none, width: 1.0
                  end

                  flow(width: 0.11, height: 1.0) do
                    para "<b>#{I18n.t(:"server_browser.players")}</b>", text_wrap: :none, width: 1.0
                  end

                  stack(width: 48) do
                    para "<b>#{I18n.t(:"server_browser.ping")}</b>", text_wrap: :none, width: 1.0
                  end
                end

                @server_list_container = stack(width: 1.0, fill: true, scroll: true) do
                  para I18n.t(:"server_browser.fetching_server_list")
                end
              end

              @game_server_info_container = stack(min_width: 372, width: 0.38, max_width: 512, height: 1.0) do
                para I18n.t(:"server_browser.no_server_selected"), width: 1.0, text_align: :center
              end
            end
          end
        end

        populate_server_list
        populate_server_info(@selected_server) if @selected_server
      end

      def update
        super

        if @refresh_server_list && Gosu.milliseconds >= @refresh_server_list
          @refresh_server_list = nil

          populate_server_list

          if @selected_server&.id == @refresh_server&.id
            if @refresh_server
              BackgroundWorker.foreground_job(
                -> { fetch_server_details(@refresh_server) },
                ->(result) {
                  populate_server_info(@refresh_server) if @refresh_server == @selected_server
                  @refresh_server = nil
                }
              )
            end
          end
        end
      end

      def refresh_server_list(server)
        @refresh_server_list = Gosu.milliseconds + 3_000
        @refresh_server = server if @selected_server&.id == server.id
      end

      def stylize_selected_server(server_container)
        server_container.style.server_item_background = server_container.style.default[:background]
        server_container.style.server_item_hover_background = server_container.style.hover[:background]
        server_container.style.server_item_active_background = server_container.style.active[:background]

        server_container.style.background = @selected_color

        server_container.style.default[:background] = @selected_color
        server_container.style.hover[:background] = @selected_color
        server_container.style.active[:background] = @selected_color
      end

      def populate_server_list
        Store.server_list = Store.server_list.sort_by! { |s| [s&.status&.player_count, s&.id] }.reverse if Store.server_list

        @server_list_container.clear do
          i = -1

          Store.server_list.each do |server|
            next unless @filters[server.game.to_sym]
            next unless server.region == @filter_region || @filter_region == "Any"
            # next unless server.channel == "release"

            i += 1

            server_container = flow(width: 1.0, height: 48, hover: { background: 0xff_555566 }, active: { background: 0xff_555588 }) do
              background 0xff_333333 if i.even?

              flow(width: 48, height: 1.0, padding: 4) do
                image game_icon(server), height: 1.0
              end

              stack(width: 0.45, height: 1.0) do
                inscription "<b>#{server&.status&.name}</b>"

                flow(width: 1.0, height: 1.0) do
                  inscription server.channel, margin_right: 64, text_size: 14
                  inscription server.region, text_size: 14
                end
              end

              flow(fill: true, height: 1.0) do
                inscription "#{server&.status&.map}"
              end

              flow(width: 0.11, height: 1.0) do
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

              flow(width: 48, height: 1.0, padding: 4) do
                image "#{GAME_ROOT_PATH}/media/ui_icons/question.png", height: 1.0, color: 0xff_444444
              end
            end

            def server_container.hit_element?(x, y)
              self if hit?(x, y)
            end

            server_container.subscribe(:clicked_left_mouse_button) do
              if @selected_server_container
                @selected_server_container.style.background = @selected_server_container.style.server_item_background
                @selected_server_container.style.default[:background] = @selected_server_container.style.server_item_background
                @selected_server_container.style.hover[:background] = @selected_server_container.style.server_item_hover_background
                @selected_server_container.style.active[:background] = @selected_server_container.style.server_item_active_background
              end

              stylize_selected_server(server_container)

              @selected_server_container = server_container

              @selected_server = server

              BackgroundWorker.foreground_job(
                -> { fetch_server_details(server) },
                ->(result) { populate_server_info(server) if server == @selected_server }
              )
            end

            stylize_selected_server(server_container) if server.id == @selected_server&.id
          end
        end
      end

      def populate_server_info(server)
        @game_server_info_container.clear do
          stack(width: 1.0, height: 1.0, padding: 8) do
            stack(width: 1.0, height: 220) do
              flow(width: 1.0, height: 0.2) do
                image game_icon(server), width: 0.05
                tagline server.status.name, width: 0.949, text_wrap: :none
              end

              stack(width: 1.0, height: 0.2) do
                game_installed = Store.application_manager.installed?(server.game, server.channel)
                game_updatable = Store.application_manager.updateable?(server.game, server.channel)
                style = server.channel != "release" ? TESTING_BUTTON : {}

                button "<b>#{I18n.t(:"server_browser.join_server")}</b>", margin_left: 96, enabled: (game_installed && !game_updatable), **style do
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

              # Server Info
              stack(width: 1.0, fill: true, margin_top: 16) do
                flow(width: 1.0) do
                  inscription "<b>#{I18n.t(:"server_browser.game")}</b>", width: 0.28, text_wrap: :none
                  inscription "#{game_name(server.game)} (#{server.channel})", width: 0.71, text_wrap: :none
                end

                flow(width: 1.0) do
                  inscription "<b>#{I18n.t(:"server_browser.map")}</b>", width: 0.28, text_wrap: :none
                  inscription server.status.map, width: 0.71, text_wrap: :none
                end

                flow(width: 1.0) do
                  inscription "<b>#{I18n.t(:"server_browser.max_players")}</b>", width: 0.28, text_wrap: :none
                  inscription "#{server.status.max_players}", width: 0.71, text_wrap: :none
                end

                flow(width: 1.0) do
                  inscription "<b>#{I18n.t(:"server_browser.time")}</b>", width: 0.28, text_wrap: :none
                  inscription formatted_rentime(server.status.started), width: 0.71, text_wrap: :none
                end

                flow(width: 1.0) do
                  inscription "<b>#{I18n.t(:"server_browser.remaining")}</b>", width: 0.28, text_wrap: :none
                  inscription "#{server.status.remaining}", width: 0.71, text_wrap: :none
                end
              end
            end

            game_balance = server_game_balance(server)

            # Game score and balance display
            flow(width: 1.0, height: 48, border_thickness_bottom: 2, border_color_bottom: 0x44_ffffff) do
              stack(width: 0.4, height: 1.0) do
                para "<b>#{server.status.teams[0].name} (#{server.status.players.select { |pl| pl.team == 0 }.count})</b>", width: 1.0, text_align: :center
                para formatted_score(game_balance[:team_0_score].to_i), width: 1.0, text_align: :center
              end

              stack(width: 0.2, height: 1.0) do
                image game_balance[:icon], height: 0.5, margin_left: 20, tip: game_balance[:message], color: game_balance[:color]
                para game_balance[:ratio].round(2).to_s, width: 1.0, text_align: :center
              end

              stack(width: 0.4, height: 1.0) do
                para "<b>#{server.status.teams[1].name} (#{server.status.players.select { |pl| pl.team == 1 }.count})</b>", width: 1.0, text_align: :center
                para formatted_score(game_balance[:team_1_score].to_i), width: 1.0, text_align: :center
              end
            end

            # Team roster
            flow(width: 1.0, fill: true, scroll: true) do
              stack(width: 0.499) do
                server.status.players.select { |ply| ply.team == 0 }.sort_by { |ply| ply.score }.reverse.each_with_index do |player, i|
                  flow(width: 1.0, height: 18) do
                    background 0xff_333333 if i.even?

                    stack(width: 0.6, height: 1.0) do
                      inscription player.nick, text_size: 14, text_wrap: :none
                    end

                    stack(width: 0.4, height: 1.0) do
                      inscription formatted_score(player.score), text_size: 14, width: 1.0, text_align: :right, text_wrap: :none
                    end
                  end
                end
              end

              stack(width: 0.5, border_thickness_left: 2, border_color_left: 0xff_000000) do
                server.status.players.select { |ply| ply.team == 1 }.sort_by { |ply| ply.score }.reverse.each_with_index do |player, i|
                  flow(width: 1.0, height: 18) do
                    background 0xff_333333 if i.even?

                    stack(width: 0.6, height: 1.0) do
                      inscription player.nick, text_size: 14, text_wrap: :none
                    end

                    stack(width: 0.4, height: 1.0) do
                      inscription formatted_score(player.score), text_size: 14, width: 1.0, text_align: :right, text_wrap: :none
                    end
                  end
                end
              end
            end
          end
        end
      end

      def fetch_server_details(server)
        BackgroundWorker.foreground_job(
          -> { Api.server_details(server.id, 2) },
          ->(server_data) { server.update(server_data) if server_data }
        )
      end

      def game_icon(server)
        image_path = File.exist?("#{GAME_ROOT_PATH}/media/icons/#{server.game.nil? ? 'ren' : server.game}.png") ? "#{GAME_ROOT_PATH}/media/icons/#{server.game.nil? ? 'ren' : server.game}.png" : "#{GAME_ROOT_PATH}/media/icons/default_icon.png"

        if server.status.password
          @server_locked_icons[server.game] ||= Gosu.render(96, 96) do
            i = get_image(image_path)
            lock = get_image("#{GAME_ROOT_PATH}/media/ui_icons/locked.png")
            scale = [96.0 / i.width, 96.0 / i.height].min

            i.draw(0, 0, 0, scale, scale)
            lock.draw(96 - lock.width * 0.5, 96 - lock.height * 0.5, 0, 0.5, 0.5, 0xff_ff8800)
          end
        else
          image_path
        end
      end

      def game_name(game)
        Store.applications.games.detect { |g| g.id == game }&.name
      end

      def server_game_balance(server)
        data = {
          icon: BLACK_IMAGE,
          color: 0xff_ffffff,
          message: "Estimate of game balance based on score"
        }

        # team 0 is left side
        team_0_score = server.status.teams[0].score
        team_0_score = nil if team_0_score.zero?
        team_0_score ||= server.status.players.select { |ply| ply.team == 0 }.map(&:score).sum
        team_0_score = team_0_score.to_f

        # team 1 is right side
        team_1_score = server.status.teams[1].score
        team_1_score = nil if team_1_score.zero?
        team_1_score ||= server.status.players.select { |ply| ply.team == 1 }.map(&:score).sum
        team_1_score = team_1_score.to_f

        ratio = 1.0 / (team_0_score / team_1_score)
        ratio = 1.0 if ratio.to_s == "NaN"

        data[:ratio] = ratio
        data[:team_0_score] = team_0_score
        data[:team_1_score] = team_1_score

        data[:icon] = if server.status.players.size < 20 && server.game != "ren"
                        data[:color] = 0xff_600000
                        data[:message] = "Too few players for a balanced game"
                        "#{GAME_ROOT_PATH}/media/ui_icons/cross.png"
                      elsif team_0_score + team_1_score < 2_500
                        data[:message] = "Score to low to estimate game balance"
                        data[:color] = 0xff_444444
                        "#{GAME_ROOT_PATH}/media/ui_icons/question.png"
                      elsif ratio.between?(0.75, 1.25)
                        data[:message] = "Game seems balanced based on score"
                        data[:color] = 0xff_008000
                        "#{GAME_ROOT_PATH}/media/ui_icons/checkmark.png"
                      elsif ratio < 0.75
                        data[:color] = 0xff_dd8800
                        data[:message] = "#{server.status.teams[0].name} is winning significantly"
                        "#{GAME_ROOT_PATH}/media/ui_icons/arrowRight.png"
                      else
                        data[:color] = 0xff_dd8800
                        data[:message] = "#{server.status.teams[1].name} is winning significantly"
                        "#{GAME_ROOT_PATH}/media/ui_icons/arrowLeft.png"
                      end

        data
      end

      def prompt_for_nickname(accept_callback: nil, cancel_callback: nil)
        push_state(
          W3DHub::States::PromptDialog,
          title: I18n.t(:"server_browser.set_nickname"),
          message: I18n.t(:"server_browser.set_nickname_message"),
          prefill: Store.settings[:server_list_username],
          accept_callback: accept_callback,
          cancel_callback: cancel_callback,
          # See: https://gitlab.com/danpaul88/brenbot/-/blob/master/Source/renlog.pm#L136-175
          valid_callback: proc do |entry|
            entry.length > 1 && entry.length < 30 && (entry =~ /(:|!|&|%| )/i).nil? &&
              (entry =~ /[\001\002\037]/).nil? && (entry =~ /\\/).nil?
          end
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
            server.channel, server, password
          )
        else
          window.push_state(W3DHub::States::MessageDialog, type: "?", title: "?", message: "?")
        end
      end

      def formatted_score(int)
        int.to_s.reverse.scan(/.{1,3}/).join(",").reverse
      end

      def formatted_rentime(time)
        range = Time.now - Time.parse(time)

        hours   = range / 60.0 / 60.0 / 24.0
        minutes = (range / 60.0) % 59
        seconds = range % 59

        format("%02d:%02d:%02d", hours, minutes, seconds)
      end
    end
  end
end
