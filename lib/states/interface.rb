class W3DHub
  class States
    class Interface < CyberarmEngine::GuiState
      def setup
        window.show_cursor = true

        @main_thread_queue = []

        theme({
          TextBlock: {
            text_border: false,
            text_shadow: true,
            text_shadow_size: 1,
            text_shadow_color: 0x88_000000,
          },
          Link: {
            color: 0xff_cdcdcd,
            hover: {
              color: Gosu::Color::WHITE
            },
            active: {
              color: 0xff_eeeeee
            }
          },
          Button: {
            text_size: 18,
            padding_top: 8,
            padding_left: 32,
            padding_right: 32,
            padding_bottom: 8,
            border_color: Gosu::Color::NONE,
            background: 0xff_00acff,
            hover: {
              background: 0xff_bee6fd
            },
            active: {
              background: 0xff_add5ec
            }
          }
        })

        @game_news = {}

        stack(width: 1.0, height: 1.0) do
          @header_container = flow(width: 1.0, height: 0.15, padding: 4) do
            background 0xff_252525

            image "#{GAME_ROOT_PATH}/media/icons/w3dhub.png", width: 0.11

            stack(width: 0.89, height: 1.0) do
              # background 0xff_885500

              @app_info_container = flow(width: 1.0, height: 0.65) do
                # background 0xff_8855ff

                stack(width: 0.75, height: 1.0) do
                  title "<b>W3D Hub Launcher</b>"
                  caption "Version 0.14.0.0", margin_left: 32
                end

                @account_container = flow(width: 0.25, height: 1.0) do
                  # background 0xff_22ff00

                  stack(width: 0.7, height: 1.0) do
                    # background 0xff_222222
                    tagline "<b>Cyberarm</b>"

                    flow(width: 1.0) do
                      link "Logout", text_size: 14
                      link "Profile", text_size: 14
                    end
                  end

                  image EMPTY_IMAGE, height: 1.0
                end
              end

              @navigation_container = flow(width: 1.0, height: 0.35) do
                # background 0xff_666666

                flow(width: 0.20, height: 1.0) do
                end

                flow(width: 0.55, height: 1.0) do
                  link "Games"
                  link "Server Browser", margin_left: 18
                  link "Community", margin_left: 18
                end

                flow(width: 0.20, height: 1.0) do
                end
              end
            end
          end

          @content_container = flow(width: 1.0, height: 0.85) do
            # background 0xff_44aa00

            # Games List
            stack(width: 0.15, height: 1.0) do
              background 0xff_121920

              W3DHub::Game.games.each do |game|
                stack(width: 1.0, border_thickness_left: 4, border_color_left: 0xff_000000) do
                  background game.background_color

                  image game.icon, height: 48
                  inscription game.name
                end.subscribe(:clicked_left_mouse_button) do |e|
                  populate_game_page(game)
                end
              end
            end

            # Game Menu
            @game_page_container = stack(width: 0.85, height: 1.0) do
            end
          end
        end

        populate_game_page(W3DHub::Game.games.first)
      end

      def update
        super

        while(block = @main_thread_queue.shift)
          block&.call
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

        unless @game_news[game.slot]
          Thread.new do
            fetch_game_news(game)
            @main_thread_queue << proc { populate_game_news(game) }
          end

          @game_news_container.clear do
            title "Fetching News...", padding: 8
          end
        else
          populate_game_news(game)
        end
      end

      # FIXME: Do actual gui update on main thread
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

        @game_news[game.slot] = RSS::Parser.parse(feed_uri.body) if feed_uri.status == 200
      end

      def populate_game_news(game)
        if (feed = @game_news[game.slot])
          @game_news_container.clear do
            feed.items.sort_by { |i| i.pubDate }.reverse[0..9].each do |item|
              flow(width: 0.5, height: 128, margin: 4) do
                # background 0x88_000000

                image game.icon, width: 0.4

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
