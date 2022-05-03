class W3DHub
  class Pages
    class Community < Page
      def setup
        @w3dhub_news ||= nil

        body.clear do
          stack(width: 1.0, height: 1.0, padding: 8) do
            stack(width: 1.0) do
              tagline "<b>Welcome to #{I18n.t(:app_name)}</b>"
              para "The #{I18n.t(:app_name_simple)} is a one-stop shop for your W3D gaming needs, providing game downloads, automatic updating, an integrated server browser, and centralized management of in-game options."
            end

            flow(width: 1.0, height: 64, margin_bottom: 24) do
              flow(fill: true, height: 1.0)

              flow(width: 64 * 4 + (3 * 32), height: 1.0) do
                image "#{GAME_ROOT_PATH}/media/icons/app.png", hover: { color: 0xaa_ffffff }, height: 1.0, tip: "#{I18n.t(:app_name)} Github Repository" do
                  Launchy.open("https://github.com/cyberarm/w3d_hub_linux_launcher")
                end
                image "#{GAME_ROOT_PATH}/media/icons/w3dhub.png", hover: { color: 0xaa_ffffff }, height: 1.0, margin_left: 32, tip: "W3D Hub Forums" do
                  Launchy.open("https://w3dhub.com/forum/")
                end
                image "#{GAME_ROOT_PATH}/media/social_media_icons/discord.png", hover: { color: 0xaa_ffffff }, height: 1.0, margin_left: 32, tip: "W3D Hub Discord Server" do
                  Launchy.open("https://discord.com/invite/GYhW7eV")
                end
                image "#{GAME_ROOT_PATH}/media/social_media_icons/facebook.png", hover: { color: 0xaa_ffffff }, height: 1.0, margin_left: 32, tip: "W3D Hub Facebook Page" do
                  Launchy.open("https://www.facebook.com/w3dhub")
                end
              end

              flow(fill: true, height: 1.0)
            end

            stack(width: 1.0, fill: true) do
              tagline "<b>Latest Updates</b>"

              @wd3hub_news_container = flow(width: 1.0, fill: true, padding: 8, scroll: true) do
              end
            end

            stack(width: 1.0, height: 72, margin_top: 16) do
              tagline "<b>Help & Support</b>"
              flow(width: 1.0) do
                para "For help and support using this launcher or playing any W3D Hub game visit the"
                link("W3D Hub forums", text_size: 16, tip: "https://w3dhub.com/forum/") { Launchy.open("https://w3dhub.com/forum/") }
                para "or join us in"
                image "#{GAME_ROOT_PATH}/media/social_media_icons/discord.png", height: 16, padding_top: 4
                link("#tech-support", text_size: 16, tip: "https://discord.com/invite/GYhW7eV") { Launchy.open("https://discord.com/invite/GYhW7eV") }
                para "on the W3D Hub Discord server"
              end
            end
          end
        end

        return if Cache.net_lock?("w3dhub_news")

        if @w3dhub_news
          populate_w3dhub_news
        else
          @wd3hub_news_container.clear do
            para I18n.t(:"games.fetching_news"), padding: 8
          end

          BackgroundWorker.foreground_job(
            -> { fetch_w3dhub_news },
            lambda do |result|
              if result
                populate_w3dhub_news
                Cache.release_net_lock(result)
              end
            end
          )
        end
      end

      def fetch_w3dhub_news
        lock = Cache.acquire_net_lock("w3dhub_news")
        return false unless lock

        news = Api.news("launcher-home")
        Cache.release_net_lock("w3dhub_news") unless news

        return unless news

        news.items[0..15].each do |item|
          Cache.fetch(uri: item.image, async: false)
        end

        @w3dhub_news = news

        "w3dhub_news"
      end

      def populate_w3dhub_news
        return unless @w3dhub_news

        if (feed = @w3dhub_news)
          @wd3hub_news_container.clear do
            # feed.items.sort_by { |i| i.timestamp }.reverse[0..9].each do |item|
            #   flow(width: 0.5, max_width: 312, height: 128, margin: 4) do
            #     # background 0x88_000000

            #     path = Cache.path(item.image)

            #     if File.exist?(path)
            #       image path, height: 1.0, padding: 4
            #     else
            #       image BLACK_IMAGE, height: 1.0, padding: 4
            #     end

            #     stack(width: 0.6, height: 1.0) do
            #       stack(width: 1.0, height: 112) do
            #         link "<b>#{item.title}</b>", text_size: 18 do
            #           Launchy.open(item.uri)
            #         end
            #         inscription item.blurb.gsub(/\n+/, "\n").strip[0..180]
            #       end

            #       flow(width: 1.0) do
            #         inscription item.timestamp.strftime("%Y-%m-%d"), width: 0.499
            #         link I18n.t(:"games.read_more"), width: 0.5, text_align: :right, text_size: 14 do
            #           Launchy.open(item.uri)
            #         end
            #       end
            #     end
            #   end
            # end

            feed.items.sort_by { |i| i.timestamp }.reverse[0..9].each do |item|
              image_path = Cache.path(item.image)
              news_blurb_container = nil
              news_title_container = nil

              news_container = stack(width: 300, height: 300, margin: 8, background_image: image_path, border_thickness: 1, border_color: lighten(Gosu::Color.new(0xff_252525))) do
                background 0x88_000000

                # Detailed view
                news_blurb_container = stack(width: 1.0, height: 1.0, background: 0xaa_000000, padding: 4) do
                  tagline "<b>#{item.title}</b>", width: 1.0
                  inscription "#{item.author} • #{item.timestamp.strftime("%Y-%m-%d")}"
                  inscription item.blurb.gsub(/\n+/, "\n").strip[0..1024], fill: true

                  button I18n.t(:"games.read_more"), width: 1.0, margin_top: 8, margin_bottom: 0, padding_top: 4, padding_bottom: 4 do
                    Launchy.open(item.uri)
                  end
                end

                # Just title
                news_title_container = stack(width: 1.0, height: 1.0) do
                  flow(fill: true)

                  tagline "<b>#{item.title}</b>", width: 1.0, background: 0xaa_000000, padding: 4
                end
              end

              news_blurb_container.hide

              def news_container.hit_element?(x, y)
                return unless hit?(x, y)

                if @children.first.visible? && (btn = @children.first.children.find { |child| child.visible? && child.is_a?(CyberarmEngine::Element::Button) && child.hit?(x, y) })
                  btn
                else
                  self
                end
              end

              news_container.subscribe(:enter) do
                news_title_container.hide
                news_blurb_container.show
              end

              news_container.subscribe(:leave) do
                unless news_container.hit?(window.mouse_x, window.mouse_y)
                  news_title_container.show
                  news_blurb_container.hide
                end
              end
            end
          end
        end
      end
    end
  end
end
