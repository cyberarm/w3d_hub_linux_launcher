module W3DHubLauncher
  module Page
    class Games < CyberarmEngine::Page
      include GuiExt

      def setup
        @games = MemCache[:applications]&.select { |app| app.type.include?("game") } || []

        @current_app = @games.first
        @current_channel = @current_app&.channels&.first

        # game bar container
        flow(width: 1.0, height: 60) do
          widget(width: 220, height: 1.0, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: ALPHA_GRAY, hover: { background_nine_slice_color: ALPHA_BLACK }, active: { background_nine_slice_color: ALPHA_GRAY }) do
            flow(width: 1.0, height: 40, margin_left: PADDING, v_align: :center, h_align: :center) do
              image safe_get_image("#{ROOT_PATH}/media/icons/menuGrid.png"), height: 40, color: 0xff_bbbbbb
              link "ALL GAMES", text_size: 24, font: FONT_BLACK, height: 1.0, text_v_align: :center
            end
          end

          @games_list_container = flow(fill: true, height: 1.0, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: ALPHA_GRAY, margin_left: PADDING) do
          end
        end

        # game content container
        flow(width: 1.0, fill: true, margin_top: LARGE_PADDING) do
          # game info container
          @game_info_container = stack(width: 340, height: 1.0) do
          end

          # game events and news container
          stack(fill: true, height: 1.0, margin_left: LARGE_PADDING, scroll: true) do
            @event_container = flow(width: 1.0, height: 1.0, max_height: 380, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: ALPHA_GRAY) do
            end

            # news container
            @news_container = flow(width: 1.0, margin_top: PADDING) do
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
          @games.each_with_index do |game, i|
            if i.zero?
              image(safe_get_image("#{ROOT_PATH}/data/cache/#{game.id}.png"), height: 1.0, padding: HALF_PADDING, background_nine_slice: NINE_SLICE_ROUNDED_TOP, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0x88_5e5c64, border_thickness_bottom: 3, border_color_bottom: 0xff_3584e4, tip: game.name)do
                @current_app = game
                @current_channel = game&.channels&.first

                populate_games_list
                populate_game_info
                populate_game_event
                populate_game_news
              end
            else
              image(safe_get_image("#{ROOT_PATH}/data/cache/#{game.id}.png"), height: 1.0, padding: HALF_PADDING, background_nine_slice: NINE_SLICE_ROUNDED_TOP, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0, tip: game.name)do
                @current_app = game
                @current_channel = game&.channels&.first

                populate_games_list
                populate_game_info
                populate_game_event
                populate_game_news
              end
            end
          end
        end
      end

      def populate_game_info
        @game_info_container.clear do
          # logo
          image safe_get_image("#{ROOT_PATH}/media/#{@current_app.id}.png"), width: 1.0, max_height: 124

          # web links
          stack(width: 1.0, fill: true, padding: 0, padding_top: LARGE_PADDING) do
            @current_app.web_links.each do |link|
              link link.name, text_size: 24, tip: link.uri
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
            button "JOIN", tip: "Join most populated or lowest ping server", fill: true, height: 1.0, background_nine_slice: NINE_SLICE_ROUNDED_LEFT, **CTA_BUTTON_THEME
            button safe_get_image("#{ROOT_PATH}/media/icons/singleplayer.png"), tip: "Single player", image_height: 1.0, background_nine_slice: NINE_SLICE_SQUARE, **CTA_BUTTON_THEME
            button safe_get_image("#{ROOT_PATH}/media/icons/gear.png"), tip: "Options", image_height: 1.0, background_nine_slice: NINE_SLICE_ROUNDED_RIGHT, **CTA_BUTTON_THEME
          end
          # FIXME: the reported version should be the _installed_ version, not the current channel version
          inscription "Version: #{@current_channel.version}", margin_top: PADDING, tip: "Installed version"
        end
      end

      def populate_game_event
        # TODO: Hide event container if there is no event
        @event_container.show if false
        @event_container.hide if true

        @event_container.clear do
          image safe_get_image("#{ROOT_PATH}/media/background.png"), fill: true, aspect_ratio: 16.0 / 9.0

          stack(fill: true, height: 1.0, margin_left: PADDING) do
            caption "Upcoming Event".upcase, color: 0xff_22aa11
            title "Red Alert: A Path Beyond Game Night"
            tagline "July 11, 2028"

            flow(fill: true)

            button "Read More", margin_left: PADDING, margin_right: LARGE_PADDING, margin_bottom: PADDING, width: 1.0
          end
        end
      end

      def populate_game_news
        @news_container.clear do
          9.times do
            stack(width: 1.0 / 3, min_width: 345, height: 345, aspect_ratio: 1, margin_left: HALF_PADDING, margin_right: HALF_PADDING, margin_bottom: PADDING) do
              stack(width: 1.0, fill: true, background_image: safe_get_image("#{ROOT_PATH}/media/background.png"), background_image_mode: :fill)
              stack(width: 1.0, height: 1.0 / 3, padding: PADDING, v_align: :bottom, background_nine_slice: NINE_SLICE_ROUNDED_BOTTOM, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: ALPHA_GRAY, border_thickness_top: 1, border_color_top: Gosu::Color::BLACK) do
                caption "NEWS", color: 0x88_ffffff
                tagline "A News Item Post A News Item Post"
              end
            end
          end
        end
      end
    end
  end
end
