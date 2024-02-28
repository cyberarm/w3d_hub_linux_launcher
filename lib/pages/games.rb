class W3DHub
  class Pages
    class Games < Page
      def setup
        @game_news ||= {}
        @game_events ||= {}

        @focused_game ||= Store.applications.games.find { |g| g.id == Store.settings[:last_selected_app] }
        @focused_game ||= Store.applications.games.find { |g| g.id == "ren" }
        @focused_channel ||= @focused_game.channels.find { |c| c.id == Store.settings[:last_selected_channel] }
        @focused_channel ||= @focused_game.channels.first

        body.clear do
          stack(width: 1.0, height: 1.0) do
            # Games List
            @games_list_container = flow(width: 1.0, height: 64, scroll: true, border_thickness_bottom: 1, border_color_bottom: W3DHub::BORDER_COLOR, padding_left: 32, padding_right: 32) do
            end

            # Game Menu
            @game_page_container = stack(width: 1.0, fill: true, background_image: "#{GAME_ROOT_PATH}/media/textures/noiseb.png", background_image_mode: :tiled) do
              # , background_image: "C:/Users/cyber/Downloads/vlcsnap-2022-04-24-22h24m15s854.png"
            end
          end
        end

        # return if Store.offline_mode

        populate_game_page(@focused_game, @focused_channel)
        populate_games_list
      end

      def populate_games_list
        @games_list_container.clear do
          background 0xaa_121920

          stack(width: 128, height: 1.0) do
            flow(fill: true)

            button "All Games" do
              populate_all_games_view
            end

            flow(fill: true)
          end

          has_favorites = Store.settings[:favorites].size.positive?

          Store.applications.games.each do |game|
            next if has_favorites && !Store.application_manager.favorite?(game.id)

            selected = game == @focused_game

            game_button = stack(width: 64, height: 1.0, border_thickness_bottom: 4,
                                border_color_bottom: selected ? 0xff_0074e0 : 0x00_000000,
                                hover: { background: selected ? game.color : 0xff_444444 },
                                padding_left: 4, padding_right: 4, tip: game.name) do
              background game.color if selected

              image_path = File.exist?("#{GAME_ROOT_PATH}/media/icons/#{game.id}.png") ? "#{GAME_ROOT_PATH}/media/icons/#{game.id}.png" : "#{GAME_ROOT_PATH}/media/icons/default_icon.png"
              image_color = Store.application_manager.installed?(game.id, game.channels.first.id) ? 0xff_ffffff : 0x66_ffffff

              flow(width: 1.0, height: 1.0, margin: 8, background_image: image_path, background_image_color: image_color, background_image_mode: :fill_height) do
                image "#{GAME_ROOT_PATH}/media/ui_icons/import.png", width: 24, margin_left: -4, margin_top: -6, color: 0xff_ff8800 if Store.application_manager.updateable?(game.id, game.channels.first.id)
              end

              # inscription game.name, width: 1.0, text_align: :center, text_size: 16
            end

            def game_button.hit_element?(x, y)
              self if hit?(x, y)
            end

            game_button.subscribe(:clicked_left_mouse_button) do
              populate_game_page(game, game.channels.first)
              populate_games_list
            end
          end
        end
      end

      def populate_game_page(game, channel)
        @focused_game = game
        @focused_channel = channel

        Store.settings[:last_selected_app] = game.id
        Store.settings[:last_selected_channel] = channel.id

        @game_page_container.clear do
          game_color = Gosu::Color.new(game.color)
          game_color.alpha = 0x88

          background game_color
          @game_page_container.style.background_image_color = game_color
          @game_page_container.style.default[:background_image_color] = game_color
          @game_page_container.update_background_image

          # Game Stuff
          flow(width: 1.0, fill: true) do
            # background 0xff_9999ff

            # Game options
            stack(width: 360, height: 1.0, padding: 8, scroll: true, border_thickness_right: 1, border_color_right: W3DHub::BORDER_COLOR) do
              background 0x55_000000

              # Game Banner
              image_path = "#{GAME_ROOT_PATH}/media/banners/#{game.id}.png"

              if File.exist?(image_path)
                image image_path, width: 1.0
              else
                banner game.name unless File.exist?(image_path)
              end

              stack(width: 1.0, fill: true, scroll: true, margin_top: 32) do
                if Store.application_manager.installed?(game.id, channel.id)
                  Hash.new.tap { |hash|
                    # hash[I18n.t(:"games.game_settings")] = { icon: "gear", block: proc { Store.application_manager.settings(game.id, channel.id) } }
                    # hash[I18n.t(:"games.wine_configuration")] = { icon: "gear", block: proc { Store.application_manager.wine_configuration(game.id, channel.id) } } if W3DHub.unix?
                    # hash[I18n.t(:"games.game_modifications")] = { icon: "gear", enabled: true, block: proc { populate_game_modifications(game, channel) } }
                    # if game.id != "ren"
                    #   hash[I18n.t(:"games.repair_installation")] = { icon: "wrench", block: proc { Store.application_manager.repair(game.id, channel.id) } }
                    #   hash[I18n.t(:"games.uninstall_game")] = { icon: "trashCan", block: proc { Store.application_manager.uninstall(game.id, channel.id) } }
                    # end
                    hash[I18n.t(:"games.install_folder")] = { icon: nil, block: proc { Store.application_manager.show_folder(game.id, channel.id, :installation) } }
                    hash[I18n.t(:"games.user_data_folder")] = { icon: nil, block: proc { Store.application_manager.show_folder(game.id, channel.id, :user_data) } }
                    hash[I18n.t(:"games.view_screenshots")] = { icon: nil, block: proc { Store.application_manager.show_folder(game.id, channel.id, :screenshots) } }
                  }.each do |key, hash|
                    flow(width: 1.0, height: 22, margin_bottom: 8) do
                      image "#{GAME_ROOT_PATH}/media/ui_icons/#{hash[:icon]}.png", width: 24 if hash[:icon]
                      image EMPTY_IMAGE, width: 24 unless hash[:icon]
                      link key, text_size: 18, enabled: hash.key?(:enabled) ? hash[:enabled] : true do
                        hash[:block]&.call
                      end
                    end
                  end
                end

                game.web_links.each do |item|
                  flow(width: 1.0, height: 22, margin_bottom: 8) do
                    image "#{GAME_ROOT_PATH}/media/ui_icons/share1.png", width: 24
                    link item.name, text_size: 18 do
                      W3DHub.url(item.uri)
                    end
                  end
                end
              end

              if game.channels.count > 1
                # Release channel

                inscription I18n.t(:"games.game_version"), width: 1.0, text_align: :center

                flow(width: 1.0, height: 48) do
                  # background 0xff_444411
                  list_box(width: 1.0, items: game.channels.map(&:name), choose: channel.name, enabled: game.channels.count > 1) do |value|
                    populate_game_page(game, game.channels.find { |c| c.name == value })
                  end
                end
              end

              # Play buttons
              flow(width: 1.0, height: 52, padding_top: 6) do
                # background 0xff_551100

                if Store.application_manager.installed?(game.id, channel.id)
                  if Store.application_manager.updateable?(game.id, channel.id)
                    button "<b>#{I18n.t(:"interface.install_update")}</b>", fill: true, text_size: 30, **UPDATE_BUTTON do
                      Store.application_manager.update(game.id, channel.id)
                    end
                  else
                    play_now_server = Store.application_manager.play_now_server(game.id, channel.id)
                    play_now_button = button "<b>#{I18n.t(:"interface.play")}</b>", fill: true, text_size: 30, enabled: !play_now_server.nil? do
                      Store.application_manager.play_now(game.id, channel.id)
                    end

                    play_now_button.subscribe(:enter) do |btn|
                      server = Store.application_manager.play_now_server(game.id, channel.id)
                      btn.enabled = !server.nil?
                      btn.instance_variable_set(:"@tip", server ? "#{server.status.name} [#{server.status.player_count}/#{server.status.max_players}]" : "")
                    end
                  end

                  button get_image("#{GAME_ROOT_PATH}/media/ui_icons/singleplayer.png"), tip: I18n.t(:"interface.single_player"), image_height: 32, margin_left: 0 do
                    Store.application_manager.run(game.id, channel.id)
                  end

                  button get_image("#{GAME_ROOT_PATH}/media/ui_icons/gear.png"), tip: I18n.t(:"games.game_options"), image_height: 32, margin_left: 0 do |btn|
                    items = []

                    items << { label: I18n.t(:"games.game_settings"), block: proc { push_state(States::GameSettingsDialog, app_id: game.id, channel: channel.id) } } #, block: proc { Store.application_manager.wwconfig(game.id, channel.id) } }
                    # items << { label: I18n.t(:"games.game_settings"), block: proc { Store.application_manager.settings(game.id, channel.id) } }
                    items << { label: I18n.t(:"games.wine_configuration"), block: proc { Store.application_manager.wine_configuration(game.id, channel.id) } } if W3DHub.unix?
                    items << { label: I18n.t(:"games.game_modifications"), block: proc { populate_game_modifications(game, channel) } } unless Store.offline_mode
                    if game.id != "ren"
                      items << { label: I18n.t(:"games.repair_installation"), block: proc { Store.application_manager.repair(game.id, channel.id) } } unless Store.offline_mode
                      items << { label: I18n.t(:"games.uninstall_game"), block: proc { Store.application_manager.uninstall(game.id, channel.id) } } unless Store.offline_mode
                    end

                    # From gui_state_ext.rb
                    # TODO: Implement in engine proper
                    menu(btn, items: items)
                  end

                else
                  installing = Store.application_manager.task?(:installer, game.id, channel.id)

                  unless game.id == "ren"
                    button "<b>#{I18n.t(:"interface.install")}</b>", fill: true, margin_right: 8, text_size: 32, enabled: !installing do |button|
                      button.enabled = false
                      @import_button.enabled = false
                      Store.application_manager.install(game.id, channel.id)
                    end
                  end

                  @import_button = button "<b>#{I18n.t(:"interface.import")}</b>", fill: true, margin_left: 8, text_size: 32, enabled: !installing do
                    Store.application_manager.import(game.id, channel.id)
                  end
                end
              end
            end

            stack(fill: true, height: 1.0) do
              # Game Description
              if false # description
                # Height should match Game Banner container height
                stack(width: 1.0, padding: 16) do
                  title "About #{game.name}", border_bottom_color: 0xff_666666, border_bottom_thickness: 1, width: 1.0
                  para "Command & Conquer: Tiberian Sun is a 1999 real-time stretegy video game by Westwood Studios, published by Electronic Arts, releaseed exclusively for Microsoft Windows on August 27th, 1999. The game is the sequel to the 1995 game Command & Conquer. It featured new semi-3D graphics, a more futuristic sci-fi setting, and new gameplay features such as vehicles capable of hovering and burrowing.", width: 1.0, text_size: 20
                end
              end

              # Game Events
              @game_events_container = flow(width: 1.0, height: 128, padding: 8, visible: false) do
              end

              # Game News
              @game_news_container = flow(width: 1.0, fill: true, padding: 8, scroll: true) do
                # background 0xff_005500
              end
            end
          end
        end

        return if Store.offline_mode

        unless Cache.net_lock?("game_news_#{game.id}")
          if @game_events[game.id]
            populate_game_events(game)
          else
            BackgroundWorker.foreground_job(
              -> { fetch_game_events(game) },
              lambda do |result|
                if result
                  populate_game_events(game)
                  Cache.release_net_lock(result)
                end
              end
            )
          end
        end

        unless Cache.net_lock?("game_events_#{game.id}")
          if @game_news[game.id]
            populate_game_news(game)
          else
            @game_news_container.clear do
              title I18n.t(:"games.fetching_news"), padding: 8
            end

            BackgroundWorker.foreground_job(
              -> { fetch_game_news(game) },
              lambda do |result|
                if result
                  populate_game_news(game)
                  Cache.release_net_lock(result)
                end
              end
            )
          end
        end
      end

      def populate_all_games_view
        @game_page_container.clear do
          background 0x88_353535
          @game_page_container.style.background_image_color = 0x88_353535
          @game_page_container.style.default[:background_image_color] = 0x88_353535
          @game_page_container.update_background_image

          @focused_game = nil
          @focused_channel = nil

          populate_games_list

          flow(width: 1.0, height: 1.0) do
            games_view_container = nil
            # Options
            stack(width: 360, height: 1.0, padding: 8, scroll: true, border_thickness_right: 1, border_color_right: W3DHub::BORDER_COLOR) do
              background 0x55_000000

              flow(width: 1.0, height: 48) do
                button "All Games", width: 280 do
                  # games_view_container.clear
                end
                tagline Store.applications.games.count.to_s, fill: true, text_align: :right
              end

              flow(width: 1.0, height: 48, margin_top: 8) do
                button "Installed", enabled: false, width: 280
                tagline "0", fill: true, text_align: :right
              end

              flow(width: 1.0, height: 48, margin_top: 8) do
                button "Favorites", enabled: false, width: 280
                tagline Store.settings[:favorites].count, fill: true, text_align: :right
              end
            end

            # Games list
            games_view_container = stack(fill: true, height: 1.0, padding: 8, margin: 8) do
              title "All Games"

              flow(width: 1.0, fill: true, scroll: true) do
                Store.applications.games.each do |game|
                  stack(width: 166, height: 224, margin: 8, background: 0x88_151515, border_color: game.color, border_thickness: 1) do
                    flow(width: 1.0, height: 24, padding: 8) do
                      para "Favorite", fill: true
                      toggle_button checked: Store.application_manager.favorite?(game.id), text_size: 18, padding_top: 3, padding_right: 3, padding_bottom: 3, padding_left: 3 do |btn|
                        Store.application_manager.favorive(game.id, btn.value)
                        Store.settings.save_settings

                        populate_games_list
                      end
                    end

                    container = stack(fill: true, width: 1.0, padding: 8) do
                      image_path = File.exist?("#{GAME_ROOT_PATH}/media/icons/#{game.id}.png") ? "#{GAME_ROOT_PATH}/media/icons/#{game.id}.png" : "#{GAME_ROOT_PATH}/media/icons/default_icon.png"
                      flow(width: 1.0, margin_top: 8) do
                        flow(fill: true)
                        image image_path, width: 0.5
                        flow(fill: true)
                      end

                      caption game.name, margin_top: 8
                    end

                    def container.hit_element?(x, y)
                      return unless hit?(x, y)

                      self
                    end

                    container.subscribe(:clicked_left_mouse_button) do |element|
                      populate_game_page(game, game.channels.first)
                      populate_games_list
                    end

                    container.subscribe(:enter) do |element|
                      element.background = 0x88_454545
                    end
                  end
                end
              end
            end
          end
        end
      end

      def fetch_game_news(game)
        lock = Cache.acquire_net_lock("game_news_#{game.id}")
        return false unless lock

        news = Api.news(game.id)
        Cache.release_net_lock("game_news_#{game.id}") unless news

        return false unless news

        news.items[0..15].each do |item|
          Cache.fetch(uri: item.image, async: false)
        end

        @game_news[game.id] = news

        "game_news_#{game.id}"
      end

      def populate_game_news(game)
        return unless @focused_game == game

        if (feed = @game_news[game.id])
          @game_news_container.clear do
            # Patch Notes
            if false # Patch notes
              flow(width: 1.0, max_width: 346 * 3 + (8 * 4), height: 346, margin: 8, margin_right: 32, border_thickness: 1, border_color: darken(Gosu::Color.new(game.color))) do
                background darken(Gosu::Color.new(game.color), 10)

                stack(width: 346, height: 1.0, padding: 8) do
                  background 0xff_181d22

                  para "Patch Notes"

                  tagline "<b>Patch 2.0 is now out!</b>"

                  para "words go here " * 20

                  flow(fill: true)

                  button "Read More", width: 1.0
                end

                flow(fill: true)

                title "Eye Candy Banner Goes Here."
              end
            end

            feed.items.sort_by { |i| i.timestamp }.reverse[0..9].each do |item|
              image_path = Cache.path(item.image)

              flow(width: 1.0, max_width: 869, height: 200, margin: 8, border_thickness: 1, border_color: lighten(Gosu::Color.new(game.color))) do
                background 0x44_000000

                image image_path, height: 1.0

                stack(fill: true, height: 1.0, padding: 4, border_thickness_left: 1, border_color_left: lighten(Gosu::Color.new(game.color))) do
                  tagline "<b>#{item.title}</b>", width: 1.0
                  inscription item.blurb.gsub(/\n+/, "\n").strip[0..1024], fill: true

                  flow(width: 1.0, height: 32, margin_top: 8) do
                    stack(fill: true, height: 1.0) do
                      flow(fill: true)
                      inscription "#{item.author} • #{item.timestamp.strftime("%Y-%m-%d")}"
                    end

                    button I18n.t(:"games.read_more"), width: 1.0, max_width: 128, padding_top: 4, padding_bottom: 4, margin_left: 0, margin_top: 0, margin_bottom: 0, margin_right: 0 do
                      W3DHub.url(item.uri)
                    end
                  end
                end
              end
            end
          end
        end
      end

      def fetch_game_events(game)
        lock = Cache.acquire_net_lock("game_events_#{game.id}")
        return false unless lock

        events = Api.events(game.id)
        Cache.release_net_lock("game_events_#{game.id}") unless events

        return false unless events

        @game_events[game.id] = events

        "game_events_#{game.id}"
      end

      def populate_game_events(game)
        return unless @focused_game == game

        if (events = @game_events[game.id])
          events = events.select { |e| e.end_time > Time.now.utc }

          @game_events_container.show unless events.empty?
          @game_events_container.hide if events.empty?

          @game_events_container.clear do
            events.flatten.each do |event|
              stack(fill: true, height: 1.0, margin_left: 8, margin_right: 8, border_thickness: 1, border_color: lighten(Gosu::Color.new(game.color))) do
                background 0x44_000000

                title event.title, width: 1.0, text_align: :center
                tagline event.start_time.strftime("%A"), text_size: 36, width: 1.0, text_align: :center
                caption event.start_time.strftime("%B %e, %Y %l:%M %p"), width: 1.0, text_align: :center
              end
            end
          end
        end
      end

      def populate_game_modifications(application, channel)
        @game_news_container.clear do
          ([
            {
              id: "4E4CB0548029FF234E289B4B8B3E357A",
              name: "HD Purchase Terminal Icons",
              author: "username",
              description: "Replaces them blurry low res icons with juicy hi-res ones.",
              icon: nil,
              type: "Textures",
              subtype: "Purchase Terminal",
              multiplayer_approved: true,
              games: ["ren", "ia"],
              versions: ["0.0.1", "0.0.2", "0.1.0"],
              url: "https://w3dhub.com/mods/username/hd_purchase_terminal_icons"
            }
          ] * 10).flatten.each do |mod|
            flow(width: 1.0, height: 128, margin: 4, border_bottom_thickness: 1, border_bottom_color: 0xff_ffffff) do
              stack(width: 128, height: 128, padding: 4) do
                image BLACK_IMAGE, height: 1.0
              end

              stack(width: 0.75, height: 1.0) do
                stack(width: 1.0, height: 128 - 28) do
                  link(mod[:name]) { W3DHub.url(mod[:url]) }
                  inscription "Author: #{mod[:author]} | #{mod[:type]} | #{mod[:subtype]}"
                  para mod[:description][0..180]
                end

                flow(width: 1.0, height: 28, padding: 4) do
                  inscription "Version", width: 0.25, text_align: :center
                  list_box items: mod[:versions], width: 0.5, enabled: mod[:versions].size > 1, padding_top: 0, padding_bottom: 0
                  button "Install", width: 0.25, padding_top: 0, padding_bottom: 0
                end
              end
            end
          end
        end
      end
    end
  end
end