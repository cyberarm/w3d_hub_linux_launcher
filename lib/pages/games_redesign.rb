class W3DHub
  class Pages
    class Games < Page
      def setup
        @game_news ||= {}

        # unless Store.offline_mode
          @focused_game ||= Store.applications.games.find { |g| g.id == Store.settings[:last_selected_app] }
          @focused_game ||= Store.applications.games.find { |g| g.id == "ren" }
          @focused_channel ||= @focused_game.channels.find { |c| c.id == Store.settings[:last_selected_channel] }
          @focused_channel ||= @focused_game.channels.first
        # end

        body.clear do
          stack(width: 1.0, height: 1.0) do
            # Games List
            @games_list_container = flow(width: 1.0, height: 64, scroll: true, border_thickness_bottom: 1, border_color_bottom: 0xff_656565, padding_left: 32, padding_right: 32) do
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
          background 0xff_121920

          Store.applications.games.each do |game|
            selected = game == @focused_game

            game_button = stack(width: 64, height: 1.0, border_thickness_bottom: 4,
                                border_color_bottom: selected ? 0xff_00acff : 0x00_000000,
                                hover: { background: selected ? game.color : 0xff_444444 },
                                padding_left: 4, padding_right: 4, tip: game.name) do
              background game.color if selected

              image_path = File.exist?("#{GAME_ROOT_PATH}/media/icons/#{game.id}.png") ? "#{GAME_ROOT_PATH}/media/icons/#{game.id}.png" : "#{GAME_ROOT_PATH}/media/icons/default_icon.png"
              image_color = Store.application_manager.installed?(game.id, game.channels.first.id) ? 0xff_ffffff : 0x66_ffffff

              flow(width: 1.0, height: 1.0, margin: 8, background_image: image_path, background_image_color: image_color, background_image_mode: :fill_height) do
                image "#{GAME_ROOT_PATH}/media/ui_icons/import.png", width: 24, margin_left: -4, margin_top: -6, color: 0xff_ff8800 if Store.application_manager.updateable?(game.id, game.channels.first.id)
              end

              # inscription game.name, width: 1.0, text_align: :center, text_size: 14
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
          @game_page_container.style.background_image_color = game.color
          @game_page_container.style.default[:background_image_color] = game.color
          @game_page_container.update_background_image

          # Game Stuff
          flow(width: 1.0, fill: true) do
            # background 0xff_9999ff

            # Game options
            stack(width: 360, height: 1.0, padding: 8, scroll: true) do
              # background 0xff_550055

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
                      Launchy.open(item.uri)
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
              flow(width: 1.0, height: 48, padding_top: 6, margin_bottom: 16) do
                # background 0xff_551100

                if Store.application_manager.installed?(game.id, channel.id)
                  if Store.application_manager.updateable?(game.id, channel.id)
                    button "<b>#{I18n.t(:"interface.install_update")}</b>", fill: true, text_size: 32, **UPDATE_BUTTON do
                      Store.application_manager.update(game.id, channel.id)
                    end
                  else
                    button "<b>#{I18n.t(:"interface.play")}</b>", fill: true, text_size: 32 do
                      Store.application_manager.play_now(game.id, channel.id)
                    end
                  end

                  button get_image("#{GAME_ROOT_PATH}/media/ui_icons/singleplayer.png"), tip: I18n.t(:"interface.single_player"), image_height: 32, margin_left: 0 do
                    Store.application_manager.run(game.id, channel.id)
                  end

                  button get_image("#{GAME_ROOT_PATH}/media/ui_icons/gear.png"), tip: I18n.t(:"games.game_options"), image_height: 32, margin_left: 0 do |btn|
                    items = []

                    items << { label: I18n.t(:"games.game_settings"), block: proc { Store.application_manager.settings(game.id, channel.id) } }
                    items << { label: I18n.t(:"games.wine_configuration"), block: proc { Store.application_manager.wine_configuration(game.id, channel.id) } } if W3DHub.unix?
                    items << { label: I18n.t(:"games.game_modifications"), block: proc { populate_game_modifications(game, channel) } }
                    if game.id != "ren"
                      items << { label: I18n.t(:"games.repair_installation"), block: proc { Store.application_manager.repair(game.id, channel.id) } }
                      items << { label: I18n.t(:"games.uninstall_game"), block: proc { Store.application_manager.uninstall(game.id, channel.id) } }
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

              # Game News
              @game_news_container = flow(width: 1.0, fill: true, padding: 8, scroll: true) do
                # background 0xff_005500
              end
            end
          end
        end

        return if Cache.net_lock?("game_news_#{game.id}")

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
              news_blurb_container = nil
              news_title_container = nil

              news_container = stack(width: 346, height: 346, margin: 8, background_image: image_path, border_thickness: 1, border_color: lighten(Gosu::Color.new(game.color))) do
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