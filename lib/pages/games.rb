class W3DHub
  class Pages
    class Games < Page
      def setup
        @@game_news ||= {}
        @focused_game ||= @host.applications.games.first

        body.clear do
          # Games List
          @games_list_container = stack(width: 0.15, height: 1.0) do
          end

          # Game Menu
          @game_page_container = stack(width: 0.85, height: 1.0) do
          end
        end

        populate_game_page(@host.applications.games.first)
        populate_games_list
      end

      def populate_games_list
        @games_list_container.clear do
          background 0xff_121920

          @host.applications.games.each do |game|
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
              populate_game_page(game)
              populate_games_list
            end
          end
        end
      end

      def populate_game_page(game)
        @focused_game = game

        @game_page_container.clear do
          background game.color

          # Release channel
          flow(width: 1.0, height: 0.03) do
            # background 0xff_444411

            game.channels.each do |channel|
              button "#{channel.name}", text_size: 14, padding_top: 2, padding_bottom: 2, padding_left: 4, padding_right: 4
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

              game.web_links.each do |item|
                flow(width: 1.0, height: 22, margin_bottom: 8) do
                  image EMPTY_IMAGE, width: 0.11
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
            button "<b>Install</b>", margin_left: 24
            button "<b>Import</b>", margin_left: 24
            button "<b>Play Now</b>", margin_left: 24
            button "<b>Single Player</b>", margin_left: 24
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
            # Cache Image
            # ext = File.basename(item.image).split(".").last
            # path = "#{CACHE_PATH}/#{Digest::SHA2.hexdigest(item.image)}.#{ext}"

            # next if File.exist?(path)

            # response = Excon.get(item.image)

            # if response.status == 200
            #   File.open(path, "wb") do |f|
            #     f.write(response.body)
            #   end
            # end

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