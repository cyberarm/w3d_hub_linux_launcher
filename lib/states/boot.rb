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
          app_icons: { started: false, complete: false },
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
      end

      def draw
        Gosu.draw_circle(window.width / 2, window.height / 2, @w3dhub_logo.width * Gosu.milliseconds / 1000.0 % 500, 128, 0x44_000000, 32)
        @w3dhub_logo.draw_rot(window.width / 2, window.height / 2, 32)

        super
      end

      def update
        super

        # @fraction += 1.0 * window.dt
        @fraction = 1.0 / (@tasks.size / @task_index.to_f)

        @progressbar.value = @fraction

        push_state(States::Interface) if @progressbar.value >= 1.0 && @task_index == @tasks.size

        task = @tasks[@tasks.keys[@task_index]]

        if task && !task[:started]
          task[:started] = true
          send(@tasks.keys[@task_index])
        end

        @task_index += 1 if @tasks.dig(@tasks.keys[@task_index], :complete)
      end

      def refresh_user_token
        p :refresh_user_token

        if Store.settings[:account, :data]
          account = Api::Account.new(Store.settings[:account, :data], {})

          if (account.access_token_expiry - Time.now) / 60 <= 60 * 3 # Refresh if token expires within 3 hours
            puts "Refreshing user login..."

            Api.on_fiber(:refresh_user_login, account.refresh_token) do |refreshed_account|
              update_account_data(refreshed_account)
            end

          else
            update_account_data(account)
          end

        else
          @tasks[:refresh_user_token][:complete] = true
        end
      end

      def update_account_data(account)
        if account
          Store.account = account

          Store.settings[:account][:data] = account

          Cache.fetch(account.avatar_uri, true)
        else
          Store.settings[:account] = {}
        end

        Store.settings.save_settings

        @tasks[:refresh_user_token][:complete] = true
      end

      def service_status
        p :service_status

        Api.on_fiber(:service_status) do |service_status|
          @service_status = service_status

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
      end

      def applications
        p :applications

        @status_label.value = I18n.t(:"boot.checking_for_updates")

        Api.on_fiber(:applications) do |applications|
          if applications
            Store.applications = applications

            @tasks[:applications][:complete] = true
          else
            # FIXME: Failed to retreive!
            @status_label.value = "FAILED TO RETREIVE APPS LIST"
          end
        end
      end

      def app_icons
        puts :app_icons

        return unless Store.applications

        packages = []
        Store.applications.games.each do |app|
          packages << { category: app.category, subcategory: app.id, name: "#{app.id}.ico", version: "" }
        end

        Api.on_fiber(:package_details, packages) do |package_details|
          puts "Got response?"

          package_details&.each do |package|
            path = Cache.package_path(package.category, package.subcategory, package.name, package.version)
            generated_icon_path = "#{GAME_ROOT_PATH}/media/icons/#{package.subcategory}.png"

            regenerate = false

            broken_or_out_dated_icon = Digest::SHA256.new.hexdigest(File.binread(path)).upcase != package.checksum.upcase if File.exist?(path)

            if File.exist?(path) && !broken_or_out_dated_icon
              regenerate = !File.exist?(generated_icon_path)
            else
              Cache.fetch_package(package, proc {})
              regenerate = true
            end

            if regenerate
              ico = ICO.new(file: path)
              image = ico.images.max_by(&:width)

              ico.save(image, generated_icon_path)
            end
          end

          @tasks[:app_icons][:complete] = true
        end
      end

      def server_list
        puts :server_list

        @status_label.value = I18n.t(:"server_browser.fetching_server_list")

        Api.on_fiber(:server_list, 2) do |list|
          Store.server_list = list.sort_by! { |s| s&.status&.players&.size }.reverse if list

          Store.server_list_last_fetch = Gosu.milliseconds

          Api::ServerListUpdater.instance

          @tasks[:server_list][:complete] = true
        end
      end
    end
  end
end
