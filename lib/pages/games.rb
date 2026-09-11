module W3DHubLauncher
  module Page
    class Games < CyberarmEngine::Page
      include GuiExt

      def setup
        @games = MemCache[:applications]&.select { |app| app.type.include?("game") } || []

        @current_app = @games.first
        @current_channel = @current_app&.channels&.first

        @display_mode = :all_games

        # game bar container
        flow(width: 1.0, height: 60) do
          widget(width: 220, height: 1.0, style_class: [:all_button]) do |w|
            flow(width: 1.0, height: 40, margin_left: PADDING, v_align: :center) do
              image safe_get_image("#{ROOT_PATH}/media/icons/menuGrid.png"), height: 40, color: 0xff_bbbbbb
              link "ALL GAMES", text_size: 24, font: FONT_BLACK, height: 1.0, text_v_align: :center
            end
            w.subscribe(:clicked_left_mouse_button) do
              populate_all_games
            end
          end

          @games_list_container = flow(fill: true, height: 1.0, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: ALPHA_GRAY, margin_left: PADDING) do
          end
        end

        # game content container
        @game_content_container = flow(width: 1.0, fill: true, margin_top: LARGE_PADDING) do
        end

        populate_game
      end

      def populate_game_content_container
        @game_content_container.clear do
          # game info container
          @game_info_container = stack(width: 340, height: 1.0) do
          end

          # game events and news container
          stack(fill: true, height: 1.0, margin_left: LARGE_PADDING, scroll: true) do
            @event_container = stack(width: 1.0, padding: PADDING, margin_left: HALF_PADDING, margin_right: HALF_PADDING, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0x88_26a269) do
            end

            # news container
            @news_container = flow(width: 1.0, margin_top: PADDING) do
            end

            # "dynamically" adjust news item widths
            @news_container.subscribe(:size_changed) do |event|
              @news_container.children.each do |box|
                box.style.width = 1.0 / news_item_width_ratio
              end
            end
          end
        end
      end

      def populate_all_games
        @display_mode = :all_games

        @game_content_container.clear do
          flow(fill: true, height: 1.0, scroll: true, tag: :hi_mom) do |e|
            @games.each do |app|
              image safe_get_image("#{ROOT_PATH}/media/default_game_cover.png"), aspect_ratio: 3 / 4.0, width: 1.0 / game_cover_width_ratio(e), margin_left: HALF_PADDING, margin_right: HALF_PADDING, margin_bottom: PADDING, tip: app.name
            end

            e.subscribe(:size_changed) do |e|
              e.children.each do |child|
                child.style.width = 1.0 / game_cover_width_ratio(e)
              end
            end
          end
        end
      end

      def populate_game(game = @current_app, channel = @current_channel)
        if @display_mode == :all_games
          @display_mode = :game

          populate_game_content_container
        end

        @current_app = game
        @current_channel = game&.channels&.first

        # This shouldn't be possible, but you never know...
        unless @current_app
          @games_list_container.clear
          @game_info_container.clear

          @event_container.clear
          @event_container.hide

          @news_container.clear do
            title "Something has gone wrong somewhere."
            tagline "No games to display... ¯\\_(-|-)_/¯"
          end

          return
        end

        app_id = @current_app.id
        unless MemCache[:"events_#{app_id}"]
          Worker::Api.events(app_id) do |result|
            if result.okay?
              File.write("events_#{app_id}.json", result.data)
              MemCache[:"events_#{app_id}"] = JSON.parse(result.data)&.map { |item| Worker::Api::ServerEvent.new(item) } || []

              populate_game_event if app_id == @current_app.id
            end
          end
        end

        unless MemCache[:"news_#{app_id}"]
          Worker::Api.news(app_id) do |result|
            if result.okay?
              File.write("news_#{app_id}.json", result.data)
              MemCache[:"news_#{app_id}"] = JSON.parse(result.data)["news"]&.map { |item| Worker::Api::NewsItem.new(item) } || []

              populate_game_news if app_id == @current_app.id
            end
          end
        end

        populate_games_list
        populate_game_info
        populate_game_event
        populate_game_news
      end

      def populate_games_list
        @games_list_container.clear do
          @games.each do |game|
            btn = button(safe_get_image("#{CACHE_PATH}/icon_#{game.id}.png"), tag: :"image_icon_#{game.id}", style_class: [:app_icon_button], enabled: @current_app.id != game.id, tip: game.name) do |btn|
              populate_game(game, game&.channels&.first)
            end
            remote_image("#{CACHE_PATH}/icon_#{game.id}.ico", url: "https://s3.w3d.cyberarm.dev/games/#{game.id}/#{game.id}.ico", element: btn) do |e, path|
              Worker::Api.ico_to_png(ico_path: path, png_path: path.sub(".ico", ".png")) do |result|
                e&.value = safe_get_image(result.data["path"]) if result.okay?
              end
            end
          end
        end
      end

      def populate_game_info
        # FIXME: We should be able to query an api to figure out the installation state, instead of explictly writing it out like this...
        application = MemCache[:settings].applications.find { |app| app.id == @current_app.id }
        # pp application

        @game_info_container.clear do
          # logo
          img = image safe_get_image("#{CACHE_PATH}/logo_#{@current_app.id}.png"), tag: :"image_logo_#{@current_app.id}", width: 1.0, max_height: 124
          remote_image("#{CACHE_PATH}/logo_#{@current_app.id}.png", url: "https://s3.w3d.cyberarm.dev/games/#{@current_app.id}/logo.png", element: img) do |e, path|
            e&.value = safe_get_image(path)
          end

          # web links
          stack(width: 1.0, fill: true, padding: 0, padding_top: LARGE_PADDING) do
            @current_app.web_links.each do |link|
              link link.name, text_size: 24, tip: link.uri do
                SDL.OpenURL(link.uri)
              end
            end
          end

          # launching ta game
          if (@current_app&.channels&.size || 0) > 1
            caption "Game Version"
            list_box(items: @current_app.channels.map(&:name), choose: @current_channel&.name, width: 1.0, margin_bottom: PADDING) do |item|
              @current_channel = @current_app.channels.find { |c| c.name == item }
              populate_game_info
            end
          end
          flow(width: 1.0, height: 60) do
            if application
              button "JOIN", tip: "Join most populated or lowest ping server", fill: true, height: 1.0, background_nine_slice: NINE_SLICE_ROUNDED_LEFT, **CTA_BUTTON_THEME
              button safe_get_image("#{ROOT_PATH}/media/icons/singleplayer.png"), tip: "Single player", image_height: 1.0, background_nine_slice: NINE_SLICE_SQUARE, **CTA_BUTTON_THEME
              button safe_get_image("#{ROOT_PATH}/media/icons/gear.png"), tip: "Options", image_height: 1.0, background_nine_slice: NINE_SLICE_ROUNDED_RIGHT, **CTA_BUTTON_THEME
            elsif @current_app.servicable?
              # pp @current_app
              button "Import", enabled: false, tip: "Import existing application installation", fill: true, height: 1.0, background_nine_slice: NINE_SLICE_ROUNDED_LEFT, **CTA_BUTTON_THEME
              button "Download", tip: "Download and install application", fill: true, height: 1.0, background_nine_slice: NINE_SLICE_ROUNDED_RIGHT, **CTA_BUTTON_THEME do
                Worker::Api.install_application(@current_app.id, @current_channel.id)
              end
            else
              button "Import", enabled: false, tip: "Import existing application installation", fill: true, height: 1.0, **CTA_BUTTON_THEME
            end
          end
          # FIXME: the reported version should be the _installed_ version, not the current channel version
          inscription "Version: #{@current_channel.version}", margin_top: PADDING, tip: "Installed version" if application
        end
      end

      def populate_game_event
        app_events = MemCache[:"events_#{@current_app.id}"] || []
        if app_events.empty?
          @event_container.hide
        else
          @event_container.show

          event = app_events.sort(&:start_time).last

          @event_container.clear do
            caption "Upcoming Event".upcase, color: 0xaa_ffffff
            tagline event.title # "Red Alert: A Path Beyond Game Night"
            caption event.start_time.strftime("%B %e, %Y • %T") # "July 11, 2028"
          end
        end
      end

      def populate_game_news
        app_news = MemCache[:"news_#{@current_app.id}"] || []

        @news_container.clear do
          app_news.each do |item|
            stack(width: 1.0 / news_item_width_ratio, height: 345, aspect_ratio: 1, margin_left: HALF_PADDING, margin_right: HALF_PADDING, margin_bottom: PADDING, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: ALPHA_GRAY) do
              stack(width: 1.0, height: 1.0 / 3, padding: PADDING, background_nine_slice: NINE_SLICE_ROUNDED_TOP, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: ALPHA_GRAY) do
                para item.timestamp.strftime("%B %e, %Y") #"September 29, 2026"
                tagline item.title
              end

              stack(width: 1.0, fill: true, padding: PADDING, padding_bottom: 0, scroll: false) do
                para item.blurb
              end

              button "Read More", margin: PADDING, width: 1.0, tip: item.uri do
                SDL.OpenURL(item.uri)
              end
            end
          end
        end
      end

      def game_cover_width_ratio(e)
        (e.width / 300.0).round.clamp(1..10)
      end

      def news_item_width_ratio
        (@news_container.width / 400.0).round.clamp(1..10)
      end
    end
  end
end
