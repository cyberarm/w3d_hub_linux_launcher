class W3DHub
  class States
    class Interface < CyberarmEngine::GuiState
      def setup
        window.show_cursor = true

        @active_page = nil
        @focused_game = W3DHub::Game.games.first

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

        stack(width: 1.0, height: 1.0, border_thickness: 1, border_color: 0xff_aaaaaa) do
          background 0xff_252525

          @header_container = flow(width: 1.0, height: 0.15, padding: 4) do
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
                      link("Logout", text_size: 14) { page(:login) }
                      link "Profile", text_size: 14
                      link("Settings", text_size: 14) { page(:settings) }
                    end
                  end

                  image BLACK_IMAGE, height: 1.0
                end
              end

              @navigation_container = flow(width: 1.0, height: 0.35) do
                # background 0xff_666666

                flow(width: 0.20, height: 1.0) do
                end

                flow(width: 0.55, height: 1.0) do
                  link "Games" do
                    page(:games)
                  end

                  link "Server Browser", margin_left: 18 do
                    page(:server_browser)
                  end

                  link "Community", margin_left: 18 do
                    page(:community)
                  end
                end

                flow(width: 0.20, height: 1.0) do
                end
              end
            end
          end

          @content_container = flow(width: 1.0, height: 0.85) do
          end
        end

        page(:games)
      end

      def update
        super

        while(block = @main_thread_queue.shift)
          block&.call
        end
      end

      def page(page)
        return if page == @active_page

        send(:"#{page}_page")

        @active_page = page
      end

      def games_page
        @content_container.clear do
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

      def server_browser_page
        @content_container.clear do
          stack(width: 1.0, height: 1.0, padding: 8) do
            stack(width: 1.0, height: 0.04) do
              inscription "<b>Filters</b>"
            end

            flow(width: 1.0, height: 0.06) do
              flow(width: 0.75, height: 1.0) do
                image "#{GAME_ROOT_PATH}/media/icons/ren.png", height: 1.0
                image "#{GAME_ROOT_PATH}/media/icons/ecw.png", height: 1.0, margin_left: 32
                image "#{GAME_ROOT_PATH}/media/icons/ia.png", height: 1.0, margin_left: 32
                image "#{GAME_ROOT_PATH}/media/icons/apb.png", height: 1.0, margin_left: 32
                image "#{GAME_ROOT_PATH}/media/icons/tsr.png", height: 1.0, margin_left: 32, margin_right: 32
                para "Region"
                list_box items: ["Any", "North America", "Europe"], width: 0.25
              end

              flow(width: 0.25, height: 1.0) do
                inscription "Nickname:"
                inscription "Cyberarm"
                image EMPTY_IMAGE, height: 1.0
              end
            end

            flow(width: 1.0, height: 0.9, margin_top: 16) do
              stack(width: 0.62, height: 1.0, scroll: true) do
                para "SERVERS"
                # Icon
                # Hostname
                # Current Map
                # Players
                # Ping

                15.times do |i|
                  flow(width: 1.0, height: 48) do
                    background 0xff_333333 if i.odd?

                    image "#{GAME_ROOT_PATH}/media/icons/ecw.png", width: 0.08

                    stack(width: 0.50, height: 1.0) do
                      para "<b>[W3DHub] GAME SERVER"

                      flow(width: 1.0, height: 1.0) do
                        inscription "Release", margin_right: 64
                        inscription "North America"
                      end
                    end

                    flow(width: 0.25, height: 1.0) do
                      para "MAP NAME"
                    end

                    flow(width: 0.1, height: 1.0) do
                      para "99/127"
                    end

                    image "#{GAME_ROOT_PATH}/media/ui_icons/signal3.png", width: 0.05, color: 0xff_008000
                  end.subscribe(:clicked_left_mouse_button) do
                    populate_server_info(nil)
                  end
                end
              end

              @game_server_info_container = stack(width: 0.38, height: 1.0) do
                para "SERVER INFO"
              end
            end
          end
        end
      end

      def community_page
        @content_container.clear do
          stack(width: 1.0, height: 1.0, padding: 8) do
            stack(width: 1.0, height: 0.15) do
              tagline "<b>Welcome to the W3D Hub Launcher</b>"
              para "The W3D Hub launcher is a one-stop shop for your W3D gamings needs, providing game downloads and automatic updating, an intregrated server browser, centralized management of in-game options and many other features."
            end

            flow(width: 1.0, height: 0.1, margin_top: 24) do
              flow(width: 0.375, height: 1.0) do
              end

              flow(width: 0.25, height: 1.0) do
                image "#{GAME_ROOT_PATH}/media/icons/apb.png", height: 1.0
                image "#{GAME_ROOT_PATH}/media/icons/ren.png", height: 1.0, margin_left: 32
                image "#{GAME_ROOT_PATH}/media/icons/tsr.png", height: 1.0, margin_left: 32
                image "#{GAME_ROOT_PATH}/media/icons/w3dhub.png", height: 1.0, margin_left: 32
              end

              flow(width: 0.375, height: 1.0) do
              end
            end

            stack(width: 1.0, height: 0.6, scroll: true) do
              tagline "<b>Latest Updates</b>"
              para "<b>Beta 12</b>", margin_left: 16
              para "- Server Browser: Added detailed information for selection server", margin_left: 32

              para "<b>Beta 11.6</b>", margin_left: 16, margin_top: 16
              para "- Localisation: Added Korean translations (unknown author)", margin_left: 32
              para "- Localisation: Added Spanish translations (thanks to Silverlight and URKA)", margin_left: 32
              para "- Localisation: Added Spanish translations (thanks to darkyuri-cz)", margin_left: 32

              para "<b>Beta 11.0</b>", margin_left: 16, margin_top: 16
              para "- Localisation: Added partial Chinese (Simplified) translations and Polish (thanks to DoDoCat and TrollekPL on the W3D Hub forums for providing translations)", margin_left: 32
              para "- Performance: Reduced CPU and GPU usage during game installs and updates", margin_left: 32
              para "- Settings: Added new setting menu for the launcher - click on the [gear] icon in the titlebar. Incluudes:", margin_left: 32
              para "- Manually choose language, rather than using default based on OS", margin_left: 48
              para "- Choose package cache folder location", margin_left: 48
              para "- Choose default folder into which games are installed", margin_left: 48
              para "- Server Browser: Now receives push notifications so it shows changes to maps, player counts, etc. as soon as they are available", margin_left: 32
              para "- Server Browser: Now lists servers with players in above empty ones", margin_left: 32
              para "- Server Browser: Game filter options are now saved", margin_left: 32
            end

            stack(width: 1.0, height: 0.15) do
              tagline "<b>Help & Support</b>"
              flow(width: 1.0) do
                para "For help and support using this launcher or playing any W3D Hub game visit the"
                link("W3D Hub forums", text_size: 16) { Launchy.open("https://w3dhub.com/forum/") }
                para "or join us in"
                link("[discord]#tech-support", text_size: 16) { Launchy.open("https://w3dhub.com/forum/") }
                para "on the W3D Hub Discord server"
              end
            end
          end
        end
      end

      def login_page
        @content_container.clear do
          stack(width: 1.0, height: 1.0, padding: 32) do
            background 0xff_252535

            para "Login using your W3D Hub forum account"

            flow(width: 1.0) do
              tagline "Username", width: 0.25, text_align: :right, focus: true
              edit_line ""
            end

            flow(width: 1.0) do
              tagline "Password", width: 0.25, text_align: :right
              edit_line "", type: :password
            end

            flow(width: 1.0) do
              tagline "", width: 0.25
              button "Log In"
            end
          end
        end
      end

      def settings_page
        @content_container.clear do
          stack(width: 1.0, height: 1.0, padding: 64) do
            para "<b>Language</b>"
            para "Select the UI language you'd like to use in the W3D Hub Launcher. You should restart the launcher after changing this setting before the ui will update"
            list_box items: ["English", "French", "German"], width: 1.0

            para "<b>Folder Paths</b>", margin_top: 32
            stack(width: 1.0, height: 0.35) do
              flow(width: 1.0, height: 0.5) do
                para "<b>App Install Folder</b>", width: 0.249

                stack(width: 0.75, height: 1.0) do
                  edit_line "C:\\Program Files (x86)\\W3D Hub", width: 1.0
                  inscription "The folder into which new games and apps will be installed by the launcher"
                end
              end

              flow(width: 1.0, height: 0.5) do
                para "<b>Package Cache Folder</b>", width: 0.249

                stack(width: 0.75, height: 1.0) do
                  edit_line "C:\\Program Data\\W3D Hub\\Launcher\\package-cache", width: 1.0
                  inscription "A folder which will be used to cache downloaded packages used to install games and apps"
                end
              end
            end

            para "<b>Diagnostics</b>"
            check_box "Enable Automatic Error Reporting", text_size: 16
            inscription "If this is enabled the launcher will automatically report errors to the development team, along with basic information about your machine, such as operating system."

            button "Save", margin_top: 32
          end
        end
      end

      def populate_games_list
        @games_list_container.clear do
          background 0xff_121920

          W3DHub::Game.games.each do |game|
            selected = game == @focused_game

            stack(width: 1.0, border_thickness_left: 4, border_color_left: selected ? 0xff_00acff : 0x00_000000) do
              background game.background_color if selected

              image game.icon, height: 48
              inscription game.name
            end.subscribe(:clicked_left_mouse_button) do |e|
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
        return unless @focused_game == game

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

      def populate_server_info(server)
        @game_server_info_container.clear do
          stack(width: 1.0, height: 1.0, padding: 8) do
            stack(width: 1.0, height: 0.2) do
              tagline "[W3D Hub] GAME SERVER"
              button "Join Server"
            end

            flow(width: 1.0, height: 0.05) do
              stack(width: 0.5, height: 1.0) do
                para "<b>GDI</b>", width: 1.0, text_align: :center
              end

              stack(width: 0.5, height: 1.0) do
                para "<b>Nod</b>", width: 1.0, text_align: :center
              end
            end

            flow(width: 1.0, height: 0.75) do
              stack(width: 0.5, height: 1.0, scroll: true) do
                15.times do |i|
                  flow(width: 1.0, height: 18) do
                    stack(width: 0.6, height: 1.0) do
                      inscription "Player Name #{i}", text_size: 14
                    end

                    stack(width: 0.4, height: 1.0) do
                      inscription "#{rand(1000..100000)}", text_size: 14, width: 1.0, text_align: :right
                    end
                  end
                end
              end

              stack(width: 0.5, height: 1.0, scroll: true, border_thickness_left: 2, border_color_left: 0xff_000000) do
                45.times do |i|
                  flow(width: 1.0, height: 18) do
                    stack(width: 0.6, height: 1.0) do
                      inscription "Player Name #{i}", text_size: 14
                    end

                    stack(width: 0.4, height: 1.0) do
                      inscription "#{rand(1000..100000)}", text_size: 14, width: 1.0, text_align: :right
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
