class W3DHub
  class States
    class Boot < CyberarmEngine::GuiState
      def setup
        window.show_cursor = true

        theme(W3DHub::THEME)

        background 0xff_252525

        @fraction = 0.0
        @w3dhub_logo = get_image("#{GAME_ROOT_PATH}/media/icons/app.png")
        @tasks = {
          refresh_user_token: { started: false, complete: false },
          service_status: { started: false, complete: false },
          applications: { started: false, complete: false },
          server_list: { started: false, complete: false }
        }

        @task_index = 0

        stack(width: 1.0, height: 1.0, border_thickness: 1, border_color: 0xff_aaaaaa) do
          stack(width: 1.0, height: 0.925) do
          end

          @progressbar = progress height: 0.025, width: 1.0

          flow(width: 1.0, height: 0.05, padding_left: 16, padding_right: 16, padding_bottom: 8, padding_top: 8) do
            @status_label = caption "Starting #{I18n.t(:app_name_simple)}...", width: 0.5
            inscription "#{I18n.t(:app_name)} #{W3DHub::VERSION}", width: 0.5, text_align: :right
          end
        end

        Async do
          @tasks.keys.each do |key|
            Sync do
              send(key)
            end
          end
        end
      end

      def draw
        @w3dhub_logo.draw_rot(window.width / 2, window.height / 2, 32)

        super
      end

      def update
        super

        # @fraction += 1.0 * window.dt
        @fraction = 1.0 / (@tasks.size / @task_index.to_f)

        @progressbar.value = @fraction

        push_state(States::Interface) if @progressbar.value >= 1.0 && @task_index == @tasks.size

        @task_index += 1 if @tasks.dig(@tasks.keys[@task_index], :complete)
      end

      def refresh_user_token
        if Store.settings[:account, :data]
          account = Api::Account.new(Store.settings[:account, :data], {})

          if (account.access_token_expiry - Time.now) / 60 <= 60 * 3 # Refresh if token expires within 3 hours
            puts "Refreshing user login..."
            @account = Api.refresh_user_login(account.refresh_token)
          else
            @account = account
          end

          if @account
            Store.account = @account

            Store.settings[:account][:data] = @account

            Cache.fetch(@account.avatar_uri, true)
          else
            Store.settings[:account] = {}
          end

          Store.settings.save_settings

          @tasks[:refresh_user_token][:complete] = true
        else
          @tasks[:refresh_user_token][:complete] = true
        end
      end

      def service_status
        @service_status = Api.service_status

        if @service_status
          Store.service_status = @service_status

          if !@service_status.authentication? || !@service_status.package_download?
            @status_label.value = "Authentication is #{@service_status.authentication? ? 'Okay' : 'Down'}. Package Download is #{@service_status.package_download? ? 'Okay' : 'Down'}."
          end

          @tasks[:service_status][:complete] = true
        else
          @status_label.value = I18n.t(:"boot.w3dhub_service_is_down")
        end
      end

      def applications
        @status_label.value = I18n.t(:"boot.checking_for_updates")

        @applications = Api.applications

        if @applications
          Store.applications = @applications

          @tasks[:applications][:complete] = true
        else
          # FIXME: Failed to retreive!
        end
      end

      def server_list
        @status_label.value = I18n.t(:"server_browser.fetching_server_list")

        begin
          internet = Async::HTTP::Internet.instance

          list = Api.server_list(internet, 2)

          if list
            Store.server_list = list.sort_by! { |s| s&.status&.players&.size }.reverse
          end

          Store.server_list_last_fetch = Gosu.milliseconds

          Api::ServerListUpdater.instance

          @tasks[:server_list][:complete] = true
        rescue => e
          # Something went wrong!
          pp e
          Store.server_list = []
        end
      end
    end
  end
end
