class W3DHub
  class States
    class Interface < CyberarmEngine::GuiState
      attr_reader :main_thread_queue

      def setup
        window.show_cursor = true

        @account = @options[:account]
        @service_status = @options[:service_status]
        @applications = @options[:applications]

        @page = nil
        @pages = {}

        @main_thread_queue = []

        theme({
          ToolTip: {
            background: 0xff_dedede,
            color: 0xaa_000000,
            text_size: 18,
            text_border: false,
            text_shadow: false,
          },
          TextBlock: {
            # font: "Inconsolata",
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
          },
          ToggleButton: {
            padding_left: 8,
            padding_right: 8,
            width: 18,
            image_width: 18,
            checkmark_image: "#{GAME_ROOT_PATH}/media/ui_icons/checkmark.png"
          },
          Progress: {
            fraction_background: 0xff_00acff,
            border_thickness: 0
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
                    flow(width: 0.18, height: 1.0) do
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
                    end

                    @application_taskbar_container = stack(width: 0.77, height: 1.0, margin_left: 16) do
                      flow(width: 1.0, height: 0.65) do
                        @application_taskbar_label = inscription "Downloading Expansive Civilian Warfare...", width: 0.65, text_wrap: :none
                        @application_taskbar_status_label = inscription "460.2 MB / 254.5 GB", width: 0.35, text_align: :right, text_wrap: :none
                      end

                      @application_taskbar_progressbar = progress fraction: 0.4, height: 2, width: 1.0
                    end
                  end
                end

                @account_container = flow(width: 0.25, height: 1.0) do
                  stack(width: 0.7, height: 1.0) do
                    # background 0xff_222222
                    tagline "<b>Not Logged In</b>", text_wrap: :none

                    flow(width: 1.0) do
                      link("Log in", text_size: 16) { page(W3DHub::Pages::Login) }
                      link "Register", text_size: 16 do
                        Launchy.open("https://secure.w3dhub.com/forum/index.php?app=core&module=global&section=register")
                      end
                    end
                  end
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

        if window.account
          page(W3DHub::Pages::Login)
        else
          page(W3DHub::Pages::Games)
        end

        hide_application_taskbar
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

      def show_application_taskbar
        @application_taskbar_container.show
      end

      def hide_application_taskbar
        @application_taskbar_container.hide
      end

      def update_application_taskbar(message, status, progress)
        @application_taskbar_label.value = message
        @application_taskbar_status_label.value = status
        @application_taskbar_progressbar.value = progress.clamp(0.0, 1.0)
      end

      # def update_download_manager_state(application, channel)
      # end

      def update_download_manager_list
      end

      def update_download_manager_task(checksum, name, status, progress)
        return unless @page.is_a?(Pages::DownloadManager)

        download_package_info = @page.download_package_info

        name_ = download_package_info["#{checksum}_name"]
        status_ = download_package_info["#{checksum}_status"]
        progress_ = download_package_info["#{checksum}_progress"]

        name_.value = name if name
        status_.value = status if status
        progress_.value = progress if progress
      end
    end
  end
end
