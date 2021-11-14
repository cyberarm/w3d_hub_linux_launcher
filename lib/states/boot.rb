class W3DHub
  class States
    class Boot < CyberarmEngine::GuiState
      def setup
        background 0xff_252525

        @fraction = 0.0
        @w3dhub_logo = get_image("#{GAME_ROOT_PATH}/media/icons/w3dhub.png")
        @tasks = {
          refresh_user_token: { started: false, complete: false },
          service_status: { started: false, complete: false },
          applications: { started: false, complete: false }
        }

        @task_index = 0

        stack(width: 1.0, height: 1.0, border_thickness: 1, border_color: 0xff_aaaaaa) do
          stack(width: 1.0, height: 0.925) do
          end

          @progressbar = progress height: 0.025, width: 1.0, fraction_background: 0xff_00acff, border_thickness: 0

          flow(width: 1.0, height: 0.05, padding_left: 16, padding_right: 16, padding_bottom: 8, padding_top: 8) do
            @status_label = caption "Starting #{NAME}...", width: 0.5
            inscription "W3D Hub Launcher 0.14.0.0", width: 0.5, text_align: :right
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
          push_state(
            States::Interface,
            refresh_token: @refresh_token,
            service_status: @service_status,
            applications: @applications
          )
        end

        send(:"#{@tasks.keys[@task_index]}") if @tasks.dig(@tasks.keys[@task_index], :complete) == false

        @task_index += 1 if @tasks.dig(@tasks.keys[@task_index], :complete)
      end

      def refresh_user_token
        @tasks[:refresh_user_token][:started] = true
        @tasks[:refresh_user_token][:complete] = true

        @refresh_token = nil
      end

      def service_status
        @tasks[:service_status][:started] = true

        Thread.new do
          @service_status = Api.service_status

          if service_status
            if !service_status.authentication? || !service_status.package_download?
              # FIXME: MAIN THREAD!
              @status_label.value = "Authentication is #{service_status.authentication? ? 'Okay' : 'Down'}. Package Download is #{service_status.package_download? ? 'Okay' : 'Down'}."
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

        warn "ALREADY STARTED APPLICATIONS!!!" if @tasks[:applications][:started]

        return if @tasks[:applications][:started]

        @tasks[:applications][:started] = true

        Thread.new do
          @applications = Api.applications

          if applications
            pp applications.games.first

            @tasks[:applications][:complete] = true
          end
        end
      end
    end
  end
end
