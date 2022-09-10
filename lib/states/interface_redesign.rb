class W3DHub
  class States
    class Interface < CyberarmEngine::GuiState
      attr_accessor :interface_task_update_pending

      @@instance = nil

      def self.instance
        @@instance
      end

      def setup
        @@instance = self

        window.show_cursor = true

        @account = @options[:account]
        @service_status = @options[:service_status]
        @applications = @options[:applications]

        @interface_task_update_pending = nil

        @page = nil
        @pages = {}

        Store.application_manager.auto_import # unless Store.offline_mode

        theme(W3DHub::THEME)

        @interface_container = stack(width: 1.0, height: 1.0, border_thickness: 1, border_color: W3DHub::BORDER_COLOR) do
          background 0xff_252525

          @header_container = flow(width: 1.0, height: 84, padding: 4, border_thickness_bottom: 1, border_color_bottom: W3DHub::BORDER_COLOR) do
            flow(width: 148, height: 1.0) do
              flow(fill: true)
              image "#{GAME_ROOT_PATH}/media/icons/app.png", height: 84
              flow(fill: true)
            end

            @navigation_container = stack(fill: true, height: 1.0) do
              flow(width: 1.0, fill: true) do
                # background 0xff_666666

                link I18n.t(:"interface.games").upcase, text_size: 34 do
                  page(W3DHub::Pages::Games)
                end

                link I18n.t(:"interface.servers").upcase, text_size: 34, margin_left: 12 do
                  page(W3DHub::Pages::ServerBrowser)
                end

                link I18n.t(:"interface.community").upcase, text_size: 34, margin_left: 12 do
                  page(W3DHub::Pages::Community)
                end

                link I18n.t(:"interface.downloads").upcase, text_size: 34, margin_left: 12 do
                  page(W3DHub::Pages::DownloadManager)
                end

                link I18n.t(:"interface.settings").upcase, text_size: 34, margin_left: 12 do
                  page(W3DHub::Pages::Settings)
                end
              end

              # Installer task display
              flow(width: 1.0, height: 0.5) do
                @application_taskbar_container = stack(width: 1.0, height: 1.0, margin_left: 16, margin_right: 16) do
                  flow(width: 1.0, height: 0.65) do
                    @application_taskbar_label = inscription "", width: 0.60, text_wrap: :none
                    @application_taskbar_status_label = inscription "", width: 0.40, text_align: :right, text_wrap: :none
                  end

                  @application_taskbar_progressbar = progress fraction: 0.0, height: 2, width: 1.0
                end
              end
            end

            @account_container = flow(width: 256, height: 1.0) do
              if Store.offline_mode
                stack(width: 1.0, height: 1.0) do
                  flow(fill: true)

                  title "<b>OFFLINE</b>", text_wrap: :none, width: 1.0, text_align: :center

                  flow(fill: true)
                end
              else
                stack(width: 1.0, height: 1.0) do
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
          end

          @content_container = flow(width: 1.0, fill: true) do
          end
        end

        if Store.account
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

        update_interface_task_status(@interface_task_update_pending) if @interface_task_update_pending
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
        body.clear

        @page.blur if @page

        @pages[klass] = klass.new(host: self) unless @pages[klass]
        @page = @pages[klass]

        @page.options = options
        @page.setup
        @page.focus
      end

      def current_page
        @page
      end

      def update_server_browser(server)
        return unless @page.is_a?(Pages::ServerBrowser)

        @page.refresh_server_list(server)
      end

      def update_server_ping(server)
        return unless @page.is_a?(Pages::ServerBrowser)

        @page.update_server_ping(server)
      end

      def show_application_taskbar
        @application_taskbar_container.show
      end

      def hide_application_taskbar
        @application_taskbar_container.hide
      end

      def update_interface_task_status(task)
        @application_taskbar_label.value = task.status.label
        @application_taskbar_status_label.value = "#{task.status.value} (#{format("%.2f%%", task.status.progress.clamp(0.0, 1.0) * 100.0)})"
        @application_taskbar_progressbar.value = task.status.progress.clamp(0.0, 1.0)

        return unless @page.is_a?(Pages::DownloadManager)

        operation_info = @page.operation_info
        operation_step = @page.operation_info[:___step]

        if task.status.step != operation_step
          @page.regenerate(task)

          return
        end

        task.status.operations.each do |key, operation|

          name_ = operation_info["#{key}_name"]
          status_ = operation_info["#{key}_status"]
          progress_ = operation_info["#{key}_progress"]

          next if name_.value == operation.label &&
                  status_.value == operation.value &&
                  progress_.value == operation.value

          name_.value = operation.label if operation.label
          status_.value = operation.value if operation.value

          if operation.progress
            if operation.progress == Float::INFINITY
              progress_.type = :marquee unless progress_.type == :marquee
            else
              progress_.type = :linear unless progress_.type == :linear
              progress_.value = operation.progress.clamp(0.0, 1.0)
            end
          end
        end
      end
    end
  end
end
