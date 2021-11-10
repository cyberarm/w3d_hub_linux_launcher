class W3DHub
  class States
    class Interface < CyberarmEngine::GuiState
      attr_reader :main_thread_queue

      def setup
        window.show_cursor = true

        @page = nil
        @pages = {}

        @main_thread_queue = []

        theme({
          ToolTip: {
            background: 0xff_222222,
            text_size: 18
          },
          TextBlock: {
            text_border: false,
            text_shadow: true,
            text_shadow_size: 1,
            text_shadow_color: 0x88_000000,
          },
          EditLine: {
            border_thickness: 2,
            border_color: Gosu::Color::WHITE,
            hover: { color: Gosu::Color::WHITE }
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

        stack(width: 1.0, height: 1.0, border_thickness: 1, border_color: 0xff_aaaaaa) do
          background 0xff_252525

          @header_container = flow(width: 1.0, height: 0.15, padding: 4) do
            image "#{GAME_ROOT_PATH}/media/icons/w3dhub.png", width: 0.11

            stack(width: 0.89, height: 1.0) do
              # background 0xff_885500

              @app_info_container = flow(width: 1.0, height: 0.65) do
                # background 0xff_8855ff

                stack(width: 0.75, height: 1.0) do
                  title "<b>W3D Hub Launcher</b>", height: 0.5
                  flow(width: 1.0, height: 0.5) do
                    button(
                      get_image("#{GAME_ROOT_PATH}/media/ui_icons/gear.png"),
                      tip: "W3D Hub Launcher Settings",
                      image_height: 1.0,
                      padding_left: 4,
                      padding_top: 4,
                      padding_right: 4,
                      padding_bottom: 4,
                      margin_left: 32
                    ) do
                      page(W3DHub::Pages::Settings)
                    end

                    button(
                      get_image("#{GAME_ROOT_PATH}/media/ui_icons/import.png"),
                      tip: "Download Manager",
                      image_height: 1.0,
                      padding_left: 4,
                      padding_top: 4,
                      padding_right: 4,
                      padding_bottom: 4,
                      margin_left: 4
                    ) do
                      page(W3DHub::Pages::DownloadManager)
                    end

                    inscription "Version 0.14.0.0", margin_left: 16
                  end
                end

                @account_container = flow(width: 0.25, height: 1.0) do
                  # background 0xff_22ff00

                  stack(width: 0.7, height: 1.0) do
                    # background 0xff_222222
                    tagline "<b>Cyberarm</b>"

                    flow(width: 1.0) do
                      link("Logout", text_size: 14) { page(W3DHub::Pages::Login) }
                      link "Profile", text_size: 14
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
                    page(W3DHub::Pages::Games)
                  end

                  link "Server Browser", margin_left: 18 do
                    page(W3DHub::Pages::ServerBrowser)
                  end

                  link "Community", margin_left: 18 do
                    page(W3DHub::Pages::Community)
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

        page(W3DHub::Pages::Games)
      end

      def draw
        super

        @page&.draw
      end

      def update
        super

        @page&.update

        while(block = @main_thread_queue.shift)
          block&.call
        end
      end

      def button_down(id)
        super

        @page&.button_down(id)
      end

      def button_up(id)
        super

        @page&.button_up(id)
      end

      def body
        @content_container
      end

      def page(klass, options = {})
        # @menu_bar.clear
        # @status_bar.clear
        body.clear

        @page.blur if @page

        @pages[klass] = klass.new(host: self) unless @pages[klass]
        @page = @pages[klass]

        @page.options = options
        @page.setup
        @page.focus
      end
    end
  end
end
