class W3DHub
  class States
    class Boot < CyberarmEngine::GuiState
      def setup
        theme(W3DHub::THEME)

        background 0xff_252525

        @fraction = 0.0
        @w3dhub_logo = get_image("#{GAME_ROOT_PATH}/media/icons/w3dhub.png")
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
            @status_label = caption "Starting #{NAME}...", width: 0.5
            inscription "#{NAME} #{W3DHub::VERSION}", width: 0.5, text_align: :right
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

        if @progressbar.value >= 1.0 && @task_index == @tasks.size
          Store.account = @account
          Store.service_status = @service_status
          Store.applications = @applications

          push_state(States::Interface)
        end

        if @tasks.dig(@tasks.keys[@task_index], :started) == false
          @tasks[@tasks.keys[@task_index]][:started] = true

          send(:"#{@tasks.keys[@task_index]}")
        end

        @task_index += 1 if @tasks.dig(@tasks.keys[@task_index], :complete)
      end

      def refresh_user_token
        if Store.settings[:account, :refresh_token]
          Thread.new do
            @account = Api.refresh_user_login(Store.settings[:account, :refresh_token])

            if @account
              Store.settings[:account][:refresh_token] = @account.refresh_token
            else
              Store.settings[:account][:refresh_token] = nil
            end

            Store.settings.save_settings

            @tasks[:refresh_user_token][:complete] = true
          end
        else
          @tasks[:refresh_user_token][:complete] = true
        end
      end

      def service_status
        Thread.new do
          @service_status = Api.service_status

          if @service_status
            if !@service_status.authentication? || !@service_status.package_download?
              # FIXME: MAIN THREAD!
              @status_label.value = "Authentication is #{@service_status.authentication? ? 'Okay' : 'Down'}. Package Download is #{@service_status.package_download? ? 'Okay' : 'Down'}."
            end

            @tasks[:service_status][:complete] = true
          else
            # FIXME: MAIN THREAD!
            @status_label.value = "W3D Hub Service is down."
          end
        end
      end

      def applications
        @status_label.value = "Checking for updates..."

        Thread.new do
          @applications = Api.applications

          if @applications
            @tasks[:applications][:complete] = true
          else
            # FIXME: Failed to retreive!
          end
        end
      end

      def server_list
        @status_label.value = "Getting server list..."

        Thread.new do
          begin
            list = Api.server_list(2)

            if list
              Store.server_list = list.sort_by! { |s| s&.status&.players&.size }.reverse
            end

            Store.server_list_last_fetch = Gosu.milliseconds

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
end
