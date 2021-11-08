class W3DHub
  class States
    class Interface < CyberarmEngine::GuiState
      def setup
        window.show_cursor = true

        stack(width: 1.0, height: 1.0) do
          @header_container = flow(width: 1.0, height: 0.15, padding: 4) do
            background 0xff_888888

            image "#{GAME_ROOT_PATH}/media/icons/w3dhub.png", width: 0.11

            stack(width: 0.89, height: 1.0) do
              background 0xff_885500

              @app_info_container = flow(width: 1.0, height: 0.65) do
                background 0xff_8855ff

                stack(width: 0.75, height: 1.0) do
                  title "W3D Hub Launcher"
                  caption "Version 0.13.0.4", margin_left: 32
                end

                @account_container = flow(width: 0.25, height: 1.0) do
                  background 0xff_22ff00

                  stack(width: 0.7, height: 1.0) do
                    background 0xff_222222
                    tagline "Cyberarm"

                    flow(width: 1.0) do
                      link "Logout", text_size: 14
                      link "Profile", text_size: 14
                    end
                  end

                  image "#{GAME_ROOT_PATH}/media/icons/ia.png", height: 1.0
                end
              end

              @navigation_container = flow(width: 1.0, height: 0.35) do
                background 0xff_666666

                flow(width: 0.25, height: 1.0) do
                end

                flow(width: 0.5, height: 1.0) do
                link "Games"
                link "Server Browser"
                link "Community"
                end

                flow(width: 0.25, height: 1.0) do
                end
              end
            end
          end

          @content_container = flow(width: 1.0, height: 0.85) do
            background 0xff_44aa00

            # Games List
            stack(width: 0.15, height: 1.0) do
              background 0xff_559900

              stack(width: 1.0, border_thickness_left: 4, border_color_left: 0xff_000000) do
                background 0xff_663300

                image "#{GAME_ROOT_PATH}/media/icons/ren.png", height: 48
                inscription "C&C Renegade"
              end.subscribe(:clicked_left_mouse_button) do |e|
                puts "CLICKED"
              end

              stack(width: 1.0, border_thickness_left: 4, border_color_left: 0xff_000000) do
                background 0xff_4444ff

                image "#{GAME_ROOT_PATH}/media/icons/ecw.png", height: 48
                inscription "Exspansive Civilian Warfare"
              end.subscribe(:clicked_left_mouse_button) do |e|
                puts "CLICKED"
              end

              stack(width: 1.0, border_thickness_left: 4, border_color_left: 0xff_000000) do
                background 0xff_444488

                image "#{GAME_ROOT_PATH}/media/icons/ia.png", height: 48
                inscription "Interim Apex"
              end.subscribe(:clicked_left_mouse_button) do |e|
                puts "CLICKED"
              end

              stack(width: 1.0, border_thickness_left: 4, border_color_left: 0xff_000000) do
                background 0xff_444444

                image "#{GAME_ROOT_PATH}/media/icons/apb.png", height: 48
                inscription "Red Alert: A Path Beyond"
              end.subscribe(:clicked_left_mouse_button) do |e|
                puts "CLICKED"
              end

              stack(width: 1.0, border_thickness_left: 4, border_color_left: 0xff_000000) do
                background 0xff_448844

                image "#{GAME_ROOT_PATH}/media/icons/tsr.png", height: 48
                inscription "Tiberium Sun: Reborn"
              end.subscribe(:clicked_left_mouse_button) do |e|
                puts "CLICKED"
              end
            end

            # Game Menu
            stack(width: 0.85, height: 1.0) do
              background 0xff_5511ff

              # Release channel
              flow(width: 1.0, height: 0.03) do
                background 0xff_444411

                inscription "Release"
              end

              # Game Stuff
              flow(width: 1.0, height: 0.89) do
                background 0xff_9999ff

                # Gane options
                stack(width: 0.25, height: 1.0) do
                  background 0xff_550055
                end

                # Game News
                flow(width: 0.75, height: 1.0) do
                  background 0xff_005500
                end
              end

              # Play buttons
              flow(width: 1.0, height: 0.08) do
                background 0xff_551100

                button "Play Now"
                button "Single player"
              end
            end
          end
        end
      end
    end
  end
end
