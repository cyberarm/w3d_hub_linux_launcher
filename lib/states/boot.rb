class W3DHub
  class States
    class Boot < CyberarmEngine::GuiState
      LOG_TAG = "W3DHub::States::Boot".freeze

      def setup
        window.show_cursor = true

        theme(W3DHub::THEME)

        @fraction = 0.0
        @w3dhub_logo = get_image("#{GAME_ROOT_PATH}/media/icons/app.png")
        @tasks = {
          # connectivity_check: { started: false, complete: false }, # HEAD connectivity-check.ubuntu.com or HEAD secure.w3dhub.com?
          # launcher_updater: { started: false, complete: false },
          server_list: { started: false, complete: false },
          refresh_user_token: { started: false, complete: false },
          service_status: { started: false, complete: false },
          applications: { started: false, complete: false },
          app_icons: { started: false, complete: false }
        }

        @offline_mode = false

        @task_index = 0

        stack(width: 1.0, height: 1.0, border_thickness: 1, border_color: W3DHub::BORDER_COLOR, background_image: "#{GAME_ROOT_PATH}/media/banners/background.png", background_image_color: 0xff_525252, background_image_mode: :fill) do
          stack(width: 1.0, fill: true) do
          end

          stack(width: 1.0, height: 60) do
            flow(width: 1.0, height: 26, margin_left: 16, margin_right: 16, margin_bottom: 8, margin_top: 8) do
              @status_label = caption "Starting #{I18n.t(:app_name_simple)}...", fill: true
              para "#{I18n.t(:app_name)} #{W3DHub::VERSION}", text_align: :right
            end

            @progressbar = progress height: 4, width: 1.0, margin_left: 16, margin_right: 16, margin_bottom: 8
          end
        end
      end

      def draw
        Gosu.draw_circle(window.width / 2, window.height / 2, @w3dhub_logo.width * (0.6 + Math.cos(Gosu.milliseconds / 1000.0 * Math::PI).abs * 0.05), 128, 0xaa_353535, 32)
        @w3dhub_logo.draw_rot(window.width / 2, window.height / 2, 32)

        super
      end

      def update
        super

        @fraction = 1.0 / (@tasks.size / @task_index.to_f)

        @progressbar.value = @fraction

        if @offline_mode
          load_offline_applications_list

          unless Store.applications
            @progressbar.value = 0.0
            @status_label.value = "<c=f80>Unable to connect to W3D Hub API. No application data cached, unable to continue.</c>"

            return
          end
        end

        if @offline_mode || (@progressbar.value >= 1.0 && @task_index == @tasks.size)
          pop_state

          # --- Repair/Upgrade settings schema/data
          Store.settings[:favorites] ||= {}
          #   add game colo[u]r and uses_engine_cfg to application data
          unless @offline_mode
            Store.settings[:games].each do |key, game|
              application = Store.applications.games.find { |g| g.id == key.to_s.split("_", 2).first }
              next unless application

              game[:colour] = "##{application.color.to_s(16)}"
              game[:uses_engine_cfg] = application.uses_engine_cfg?
            end
          end

          Store.settings.save_settings

          push_state(States::Interface)
        end

        return if @offline_mode

        task = @tasks[@tasks.keys[@task_index]]

        if task && !task[:started]
          task[:started] = true
          send(@tasks.keys[@task_index])
        end

        @task_index += 1 if @tasks.dig(@tasks.keys[@task_index], :complete)
      end

      def needs_repaint?
        true
      end

      def refresh_user_token
        if Store.settings[:account, :data]
          account = Api::Account.new(Store.settings[:account, :data], {})

          if (account.access_token_expiry - Time.now) / 60 <= 60 * 3 # Refresh if token expires within 3 hours
            logger.info(LOG_TAG) { "Refreshing user login..." }

            # TODO: Check without network
            Api.on_thread(:refresh_user_login, account.refresh_token) do |refreshed_account|
              update_account_data(refreshed_account)
            end

          else
            BackgroundWorker.foreground_job(-> { update_account_data(account) }, ->(_) {})
          end

        else
          @tasks[:refresh_user_token][:complete] = true
        end
      end

      def update_account_data(account)
        if account
          Store.account = account

          Store.settings[:account][:data] = account

          Cache.fetch(uri: account.avatar_uri, force_fetch: true, async: false, backend: :w3dhub)
        else
          Store.settings[:account] = {}
        end

        Store.settings.save_settings

        @tasks[:refresh_user_token][:complete] = true
      end

      def service_status
        Api.on_thread(:service_status) do |service_status|
          @service_status = service_status

          if @service_status
            Store.service_status = @service_status

            if !@service_status.authentication? || !@service_status.package_download?
              @status_label.value = "Authentication is #{@service_status.authentication? ? 'Okay' : 'Down'}. Package Download is #{@service_status.package_download? ? 'Okay' : 'Down'}."
            end

            @tasks[:service_status][:complete] = true
          else
            BackgroundWorker.foreground_job(-> {}, ->(_) { @status_label.value = I18n.t(:"boot.w3dhub_service_is_down") })
            @tasks[:service_status][:complete] = true

            @offline_mode = true
            Store.offline_mode = true
          end
        end
      end

      def launcher_updater
        @status_label.value = "Checking for Launcher updates..." # I18n.t(:"boot.checking_for_updates")
        
        Api.on_thread(:fetch, "https://api.github.com/repos/Inq8/CAmod/releases/latest") do |response|
          if response.status == 200
            hash = JSON.parse(response.body, symbolize_names: true)
            available_version = hash[:tag_name].downcase.sub("v", "")

            pp Gem::Version.new(available_version) > Gem::Version.new(W3DHub::VERSION)
            pp [Gem::Version.new(available_version), Gem::Version.new(W3DHub::VERSION)]

            push_state(
              LauncherUpdaterDialog,
              release_data: hash,
              available_version: available_version,
              cancel_callback: -> { @tasks[:launcher_updater][:complete] = true }, 
              accept_callback: -> { @tasks[:launcher_updater][:complete] = true }
            )
          else
            # Failed to retrieve release data from github
            log "Failed to retrieve release data from Github"
            @tasks[:launcher_updater][:complete] = true
          end
        end
      end

      def applications
        @status_label.value = I18n.t(:"boot.checking_for_updates")

        Api.on_thread(:_applications) do |applications|
          if applications
            Store.applications = applications
            Store.settings.save_application_cache(applications.data.to_json)
            @tasks[:applications][:complete] = true
          else
            # FIXME: Failed to retreive!
            BackgroundWorker.foreground_job(-> {}, ->(_){ @status_label.value = "FAILED TO RETREIVE APPS LIST" })

            @offline_mode = true
            Store.offline_mode = true
          end
        end
      end

      def app_icons
        return unless Store.applications

        packages = []
        Store.applications.games.each do |app|
          packages << { category: app.category, subcategory: app.id, name: "#{app.id}.ico", version: "" }
        end

        Api.on_thread(:package_details, packages, :alt_w3dhub) do |package_details|
          package_details ||= nil

          package_details&.each do |package|
            next if package.error?

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
              BackgroundWorker.foreground_job(-> { ICO.new(file: path) }, ->(result) { result.save(result.images.max_by(&:width), generated_icon_path) })
            end
          end

          @tasks[:app_icons][:complete] = true
        end
      end

      def server_list
        @status_label.value = I18n.t(:"server_browser.fetching_server_list")

        Api.on_thread(:server_list, 2) do |list|
          if list
            Store.server_list = list.sort_by! { |s| s&.status&.players&.size }.reverse

            Store.server_list_last_fetch = Gosu.milliseconds

            Api::ServerListUpdater.instance

            list.each do |server|
              server.send_ping(true)
            end
          else
            Store.server_list = []
            Store.server_list_last_fetch = Gosu.milliseconds
          end

          @tasks[:server_list][:complete] = true
        end
      end

      def load_offline_applications_list
        if (application_cache = Store.settings.load_application_cache)
          Store.applications = Api::Applications.new(application_cache.to_json)

          return
        end

        hash = {
          applications: []
        }

        Store.settings[:games].each do |key, game|
          app_id, channel_id = key.to_s.split("_")

          app = hash[:applications].find { |a| a[:id] == app_id }
          app_in_array = !app.nil?
          app ||= {
            id: app_id,
            name: game[:name],
            type: "",
            category: "games",
            "studio-id": "",
            channels: [],
            "web-links": [],
            "extended-data": [
              { name: "colour", value: game[:colour] },
              { name: "usesEngineCfg", value: game[:uses_engine_cfg] },
            ]
          }

          channel = {
            id: channel_id,
            name: channel_id,
            "user-level": "",
            "current-version": game[:installed_version]
          }

          app[:channels] << channel

          hash[:applications] << app unless app_in_array
        end

        Store.applications = Api::Applications.new(hash.to_json) unless hash[:applications].empty?
      end
    end
  end
end
