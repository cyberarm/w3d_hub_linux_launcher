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

        window.application_manager.auto_import

        theme(W3DHub::THEME)

        stack(width: 1.0, height: 1.0, border_thickness: 1, border_color: 0xff_aaaaaa) do
          background 0xff_252525

          @header_container = flow(width: 1.0, height: 0.15, padding: 4) do
            image "#{GAME_ROOT_PATH}/media/icons/w3dhub.png", width: 0.11

            stack(width: 0.89, height: 1.0) do
              # background 0xff_885500

              @app_info_container = flow(width: 1.0, height: 0.65) do
                # background 0xff_8855ff

                stack(width: 0.75, height: 1.0) do
                  title "<b>#{I18n.t(:"app_name")}</b>", height: 0.5
                  flow(width: 1.0, height: 0.5) do
                    flow(width: 0.18, height: 1.0) do
                      button(
                        get_image("#{GAME_ROOT_PATH}/media/ui_icons/gear.png"),
                        tip: I18n.t(:"interface.app_settings_tip"),
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
                        tip: I18n.t(:"interface.download_manager"),
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
                        @application_taskbar_label = inscription "", width: 0.65, text_wrap: :none
                        @application_taskbar_status_label = inscription "", width: 0.35, text_align: :right, text_wrap: :none
                      end

                      @application_taskbar_progressbar = progress fraction: 0.0, height: 2, width: 1.0
                    end
                  end
                end

                @account_container = flow(width: 0.25, height: 1.0) do
                  stack(width: 0.7, height: 1.0) do
                    # background 0xff_222222
                    tagline "<b>#{I18n.t(:"interface.not_logged_in")}</b>", text_wrap: :none

                    flow(width: 1.0) do
                      link(I18n.t(:"interface.log_in"), text_size: 16, width: 0.5) { page(W3DHub::Pages::Login) }
                      link I18n.t(:"interface.register"), text_size: 16, width: 0.49 do
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
                  link I18n.t(:"interface.games") do
                    page(W3DHub::Pages::Games)
                  end

                  link I18n.t(:"interface.server_browser"), margin_left: 18 do
                    page(W3DHub::Pages::ServerBrowser)
                  end

                  link I18n.t(:"interface.community"), margin_left: 18 do
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

      def update_application_manager_status
        @page.update_application_manager_status
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
