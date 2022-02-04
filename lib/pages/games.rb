class W3DHub
  class Pages
    class Games < Page
      def setup
        @game_news ||= {}
        @focused_game ||= Store.applications.games.find { |g| g.id == Store.settings[:last_selected_app] }
        @focused_game ||= Store.applications.games.find { |g| g.id == "ren" }
        @focused_channel ||= @focused_game.channels.find { |c| c.id == Store.settings[:last_selected_channel] }
        @focused_channel ||= @focused_game.channels.first

        body.clear do
          # Games List
          @games_list_container = stack(width: 0.15, height: 1.0, scroll: true) do
          end

          # Game Menu
          @game_page_container = stack(width: 0.85, height: 1.0) do
          end
        end

        populate_game_page(@focused_game, @focused_channel)
        populate_games_list
      end

      def populate_games_list
        @games_list_container.clear do
          background 0xff_121920

          Store.applications.games.each do |game|
            selected = game == @focused_game

            game_button = stack(width: 1.0, border_thickness_left: 4,
                                border_color_left: selected ? 0xff_00acff : 0x00_000000,
                                hover: { background: selected ? game.color : 0xff_444444 },
                                padding_top: 4, padding_bottom: 4) do
              background game.color if selected

              flow(width: 1.0, height: 48) do
                stack(width: 0.3) do
                  image "#{GAME_ROOT_PATH}/media/ui_icons/return.png", width: 1.0, color: Gosu::Color::GRAY if Store.application_manager.updateable?(game.id, game.channels.first.id)
                  image "#{GAME_ROOT_PATH}/media/ui_icons/import.png", width: 0.5, color: 0x88_ffffff unless Store.application_manager.installed?(game.id, game.channels.first.id)
                end
                image_path = File.exist?("#{GAME_ROOT_PATH}/media/icons/#{game.id}.png") ? "#{GAME_ROOT_PATH}/media/icons/#{game.id}.png" : "#{GAME_ROOT_PATH}/media/icons/app.png"

                image image_path, height: 48, color: Store.application_manager.installed?(game.id, game.channels.first.id) ? 0xff_ffffff : 0x88_ffffff
              end
              inscription game.name, width: 1.0, text_align: :center
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
          background game.color

          # Release channel
          flow(width: 1.0, height: 0.03) do
            # background 0xff_444411

            inscription I18n.t(:"games.channel")
            list_box(items: game.channels.map(&:name), choose: channel.name, enabled: game.channels.count > 1,
                     margin_top: 0, margin_bottom: 0, width: 128,
                     padding_left: 1, padding_top: 1, padding_right: 1, padding_bottom: 1, text_size: 14) do |value|
              populate_game_page(game, game.channels.find { |c| c.name == value })
            end
          end

          # Game Stuff
          flow(width: 1.0, height: 0.88) do
            # background 0xff_9999ff

            # Game options
            stack(width: 0.25, height: 1.0, padding: 8, scroll: true) do
              # background 0xff_550055

              if Store.application_manager.installed?(game.id, channel.id)
                Hash.new.tap { |hash|
                  hash[I18n.t(:"games.game_settings")] = { icon: "gear", block: proc { Store.application_manager.settings(game.id, channel.id) } }
                  hash[I18n.t(:"games.wine_configuration")] = { icon: "gear", block: proc { Store.application_manager.wine_configuration(game.id, channel.id) } } if W3DHub.unix?
                  hash[I18n.t(:"games.game_modifications")] = { icon: "gear", enabled: true, block: proc { populate_game_modifications(game, channel) } }
                  if game.id != "ren"
                    hash[I18n.t(:"games.repair_installation")] = { icon: "wrench", block: proc { Store.application_manager.repair(game.id, channel.id) } }
                    hash[I18n.t(:"games.uninstall_game")] = { icon: "trashCan", block: proc { Store.application_manager.uninstall(game.id, channel.id) } }
                  end
                  hash[I18n.t(:"games.install_folder")] = { icon: nil, block: proc { Store.application_manager.show_folder(game.id, channel.id, :installation) } }
                  hash[I18n.t(:"games.user_data_folder")] = { icon: nil, block: proc { Store.application_manager.show_folder(game.id, channel.id, :user_data) } }
                  hash[I18n.t(:"games.view_screenshots")] = { icon: nil, block: proc { Store.application_manager.show_folder(game.id, channel.id, :screenshots) } }
                }.each do |key, hash|
                  flow(width: 1.0, height: 22, margin_bottom: 8) do
                    image "#{GAME_ROOT_PATH}/media/ui_icons/#{hash[:icon]}.png", width: 0.11 if hash[:icon]
                    image EMPTY_IMAGE, width: 0.11 unless hash[:icon]
                    link key, text_size: 18, enabled: hash.key?(:enabled) ? hash[:enabled] : true do
                      hash[:block]&.call
                    end
                  end
                end
              end

              game.web_links.each do |item|
                flow(width: 1.0, height: 22, margin_bottom: 8) do
                  image "#{GAME_ROOT_PATH}/media/ui_icons/share1.png", width: 0.11
                  link item.name, text_size: 18 do
                    Launchy.open(item.uri)
                  end
                end
              end
            end

            # Game News
            @game_news_container = flow(width: 0.75, height: 1.0, padding: 8, scroll: true) do
              # background 0xff_005500
            end
          end

          # Play buttons
          flow(width: 1.0, height: 0.09, padding_top: 6) do
            # background 0xff_551100

            if Store.application_manager.installed?(game.id, channel.id)
              if Store.application_manager.updateable?(game.id, channel.id)
                button "<b>#{I18n.t(:"interface.install_update")}</b>", margin_left: 24, **UPDATE_BUTTON do
                  Store.application_manager.update(game.id, channel.id)
                end
              else
                button "<b>#{I18n.t(:"interface.play_now")}</b>", margin_left: 24 do
                  Store.application_manager.play_now(game.id, channel.id)
                end
              end

              button "<b>#{I18n.t(:"interface.single_player")}</b>", margin_left: 24 do
                Store.application_manager.run(game.id, channel.id)
              end
            else
              installing = Store.application_manager.task?(:installer, game.id, channel.id)

              unless game.id == "ren"
                button "<b>#{I18n.t(:"interface.install")}</b>", margin_left: 24, enabled: !installing do |button|
                  button.enabled = false
                  @import_button.enabled = false
                  Store.application_manager.install(game.id, channel.id)
                end
              end

              @import_button = button "<b>#{I18n.t(:"interface.import")}</b>", margin_left: 24, enabled: !installing do
                Store.application_manager.import(game.id, channel.id)
              end
            end
          end
        end

        if @game_news[game.id]
          populate_game_news(game)
        else
          @game_news_container.clear do
            title I18n.t(:"games.fetching_news"), padding: 8
          end

          Async do
            fetch_game_news(game)
            populate_game_news(game)
          end
        end
      end

      def fetch_game_news(game)
        news = Api.news(game.id)

        if news
          news.items[0..9].each do |item|
            Cache.fetch(item.image)
          end

          @game_news[game.id] = news
        end
      end

      def populate_game_news(game)
        return unless @focused_game == game

        if (feed = @game_news[game.id])
          @game_news_container.clear do
            feed.items.sort_by { |i| i.timestamp }.reverse[0..9].each do |item|
              flow(width: 0.5, height: 128, margin: 4) do
                # background 0x88_000000

                path = Cache.path(item.image)

                if File.exist?(path)
                  image path, width: 0.4, padding: 4
                else
                  image BLACK_IMAGE, width: 0.4, padding: 4
                end

                stack(width: 0.6, height: 1.0) do
                  stack(width: 1.0, height: 112) do
                    link "<b>#{item.title}</b>", text_size: 18 do
                      Launchy.open(item.uri)
                    end
                    inscription item.blurb.gsub(/\n+/, "\n").strip[0..180]
                  end

                  flow(width: 1.0) do
                    inscription item.timestamp.strftime("%Y-%m-%d"), width: 0.5
                    link I18n.t(:"games.read_more"), width: 0.5, text_align: :right, text_size: 14 do
                      Launchy.open(item.uri)
                    end
                  end
                end
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
                  link(mod[:name]) { Launchy.open(mod[:url]) }
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