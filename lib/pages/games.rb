class W3DHub
  class Pages
    class Games < Page
      def setup
        @@game_news ||= {}
        @focused_game ||= window.applications.games.first

        body.clear do
          # Games List
          @games_list_container = stack(width: 0.15, height: 1.0) do
          end

          # Game Menu
          @game_page_container = stack(width: 0.85, height: 1.0) do
          end
        end

        populate_game_page(window.applications.games.first, window.applications.games.first.channels.first)
        populate_games_list
      end

      def populate_games_list
        @games_list_container.clear do
          background 0xff_121920

          window.applications.games.each do |game|
            selected = game == @focused_game

            game_button = stack(width: 1.0, border_thickness_left: 4,
                                border_color_left: selected ? 0xff_00acff : 0x00_000000, hover: { background: 0xff_444444 },
                                padding_top: 4, padding_bottom: 4) do
              background game.color if selected

              flow(width: 1.0, height: 48) do
                stack(width: 0.3)
                image "#{GAME_ROOT_PATH}/media/icons/#{game.id}.png", height: 48
              end
              inscription game.name, width: 1.0, text_align: :center
            end

            def game_button.hit_element?(x, y)
              self if hit?(x, y)
            end

            game_button.subscribe(:clicked_left_mouse_button) do |e|
              populate_game_page(game, game.channels.first)
              populate_games_list
            end
          end
        end
      end

      def populate_game_page(game, channel)
        @focused_game = game

        @game_page_container.clear do
          background game.color

          # Release channel
          flow(width: 1.0, height: 0.03) do
            # background 0xff_444411

            inscription "Channel"
            list_box(items: game.channels.map { |c| c.name }, choose: channel.name, enabled: game.channels.count > 1,
                     margin_top: 0, margin_bottom: 0,
                     width: 128, padding_left: 1, padding_top: 1, padding_right: 1, padding_bottom: 1, text_size: 14) do |value|
              populate_game_page(game, game.channels.find{ |c| c.name == value })
            end
          end

          # Game Stuff
          flow(width: 1.0, height: 0.89) do
            # background 0xff_9999ff

            # Game options
            stack(width: 0.25, height: 1.0, padding: 8) do
              # background 0xff_550055

              # TODO: Show links for managing game install
              # game.menu_items.each do |item|
              #   flow(width: 1.0, height: 22, margin_bottom: 8) do
              #     image item.image, width: 0.11
              #     link item.label, text_size: 18
              #   end
              # end

              if window.application_manager.installed?(game.id, channel.name)
                Hash.new.tap { |hash|
                  hash["Game Settings"] = { icon: "gear", block: proc { window.application_manager.settings(game.id, channel.name) } }
                  if game.id != "ren"
                    hash["Repair Installation"] = { icon: "wrench", block: proc { window.application_manager.repair(game.id, channel.name) } }
                    hash["Uninstall"] = { icon: "trashCan", block: proc { window.application_manager.uninstall(game.id, channel.name) } }
                  end
                  hash["Install Folder"] = { icon: nil, block: proc { window.application_manager.show_folder(game.id, channel.name, :installation) } }
                  hash["User Data Folder"] = { icon: nil, block: proc { window.application_manager.show_folder(game.id, channel.name, :user_data) } }
                  hash["View Screenshots"] = { icon: nil, block: proc { window.application_manager.show_folder(game.id, channel.name, :screenshots) } }
                }.each do |key, hash|
                  flow(width: 1.0, height: 22, margin_bottom: 8) do
                    image "#{GAME_ROOT_PATH}/media/ui_icons/#{hash[:icon]}.png", width: 0.11 if hash[:icon]
                    image EMPTY_IMAGE, width: 0.11 unless hash[:icon]
                    link key, text_size: 18 do
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
          flow(width: 1.0, height: 0.08) do
            # background 0xff_551100

            # TODO: Determine if game is installed or not and show apporpiante options ["Play Now" and "Single Player", "Install" and "Import"]
            # game.play_items.each do |item|
            #   button "<b>#{item.label}</b>", margin_left: 24 do
            #     item.block&.call(game)
            #   end
            # end
            if window.application_manager.installed?(game.id, channel.id)
              button "<b>Play Now</b>", margin_left: 24
              button "<b>Single Player</b>", margin_left: 24
            else
              unless game.id == "ren"
                button "<b>Install</b>", margin_left: 24 do
                  window.application_manager.install(game.id, channel.name)
                end
              end

              button "<b>Import</b>", margin_left: 24 do
                window.application_manager.import(game.id, channel.name, "?")
              end
            end
          end
        end

        unless @@game_news[game.id]
          Thread.new do
            fetch_game_news(game)
            main_thread_queue << proc { populate_game_news(game) }
          end

          @game_news_container.clear do
            title "Fetching News...", padding: 8
          end
        else
          populate_game_news(game)
        end
      end

      def fetch_game_news(game)
        news = Api.news(game.id)

        if news
          news.items[0..9].each do |item|
            Cache.fetch(item.image)
          end

          @@game_news[game.id] = news
        end
      end

      def populate_game_news(game)
        return unless @focused_game == game

        if (feed = @@game_news[game.id])
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
                    link "Read More", width: 0.5, text_align: :right, text_size: 14 do
                      Launchy.open(item.uri)
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end