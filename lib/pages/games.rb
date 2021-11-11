class W3DHub
  class Pages
    class Games < Page
      def setup
        @@game_news ||= {}
        @focused_game ||= W3DHub::Game.games.first

        body.clear do
          # Games List
          @games_list_container = stack(width: 0.15, height: 1.0) do
          end

          # Game Menu
          @game_page_container = stack(width: 0.85, height: 1.0) do
          end
        end

        populate_game_page(W3DHub::Game.games.first)
        populate_games_list
      end

      def populate_games_list
        @games_list_container.clear do
          background 0xff_121920

          W3DHub::Game.games.each do |game|
            selected = game == @focused_game

            game_button = stack(width: 1.0, border_thickness_left: 4,
                                border_color_left: selected ? 0xff_00acff : 0x00_000000, hover: { background: 0xff_444444 },
                                padding_top: 4, padding_bottom: 4) do
              background game.background_color if selected

              flow(width: 1.0, height: 48) do
                stack(width: 0.3)
                image game.icon, height: 48
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
          background game.background_color

          # Release channel
          flow(width: 1.0, height: 0.03) do
            # background 0xff_444411

            inscription "Release"
          end

          # Game Stuff
          flow(width: 1.0, height: 0.89) do
            # background 0xff_9999ff

            # Gane options
            stack(width: 0.25, height: 1.0, padding: 8) do
              # background 0xff_550055

              game.menu_items.each do |item|
                flow(width: 1.0, height: 22, margin_bottom: 8) do
                  image item.image, width: 0.11
                  link item.label, text_size: 18
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

            game.play_items.each do |item|
              button "<b>#{item.label}</b>", margin_left: 24 do
                item.block&.call(game)
              end
            end
          end
        end

        unless @@game_news[game.slot]
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
        feed_uri = Excon.get(
          game.news_feed,
          headers: {
            "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:94.0) Gecko/20100101 Firefox/94.0",
            "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
            "Accept-Encoding" => "deflate",
            "Accept-Language" => "en-US,en;q=0.5",
            "Host" => "w3dhub.com",
            "DNT" => "1"
          }
        )

        @@game_news[game.slot] = RSS::Parser.parse(feed_uri.body) if feed_uri.status == 200
      end

      def populate_game_news(game)
        return unless @focused_game == game

        if (feed = @@game_news[game.slot])
          @game_news_container.clear do
            feed.items.sort_by { |i| i.pubDate }.reverse[0..9].each do |item|
              flow(width: 0.5, height: 128, margin: 4) do
                # background 0x88_000000

                image game.icon, width: 0.4, padding: 4

                stack(width: 0.6, height: 1.0) do
                  stack(width: 1.0, height: 112) do
                    para "<b>#{item.title}</b>"
                    inscription "#{Sanitize.fragment(item.description[0...180]).strip}"
                  end

                  flow(width: 1.0) do
                    inscription item.pubDate.strftime("%Y-%m-%d"), width: 0.5
                    link "Read More", width: 0.5, text_align: :right, text_size: 14 do
                      Launchy.open(item.link)
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