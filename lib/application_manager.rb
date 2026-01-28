class W3DHub
  class ApplicationManager
    LOG_TAG = "W3DHub::ApplicationManager".freeze
    include CyberarmEngine::Common

    def initialize
      @tasks = [] # :installer, :importer, :repairer, :uninstaller
      @running_applications = {}
    end

    def install(app_id, channel)
      logger.info(LOG_TAG) { "Installation Request: #{app_id}-#{channel}" }

      return false if installed?(app_id, channel) || installing?(app_id, channel)

      # if on unix: ask/make a wine prefix
      # add install task to a list and mark as installing
      # fetch manifests
      # cycle through manifests and check package cache
      # generate list of required packages to download
      # download packages
      # verify packages
      # unpack packages
      # install dependencies (e.g. visual C runtime)

      installer = Installer.new(app_id, channel)

      @tasks.push(installer)
    end

    def update(app_id, channel)
      logger.info(LOG_TAG) { "Update Request: #{app_id}-#{channel}" }

      return false unless installed?(app_id, channel)

      updater = Updater.new(app_id, channel)

      @tasks.push(updater)
    end

    def import(app_id, channel)
      logger.info(LOG_TAG) { "Import Request: #{app_id}-#{channel}" }

      # Check registry for auto-import if windows
      # if auto-import fails ask user for path to game exe
      # mark app as imported/installed

      push_state(W3DHub::States::ImportGameDialog, app_id: app_id, channel: channel)
    end

    def settings(app_id, channel)
      logger.info(LOG_TAG) { "Settings Request: #{app_id}-#{channel}" }

      if (app_data = installed?(app_id, channel))
        _application = Store.applications.games.find { |g| g.id == app_id }
        _channel = _application.channels.find { |c| c.id == channel }

        push_state(W3DHub::States::GameSettingsDialog, title: "#{_application.name} (#{_channel.name}) Settings", app_id: app_id, channel: channel)
      end
    end

    def wwconfig(app_id, channel)
      logger.info(LOG_TAG) { "WWConfig Request: #{app_id}-#{channel}" }

      # open wwconfig.exe or config.exe for ecw

      if (app_data = installed?(app_id, channel))
        exe = if File.exist?("#{app_data[:install_directory]}/wwconfig.exe")
                "#{app_data[:install_directory]}/wwconfig.exe"

              elsif File.exist?("#{app_data[:install_directory]}/WWConfig.exe")
                "#{app_data[:install_directory]}/WWConfig.exe"

              elsif File.exist?("#{app_data[:install_directory]}/config.exe")
                "#{app_data[:install_directory]}/config.exe"
              end

        if File.exist?(exe)
          pid = Process.spawn("#{wine_command(app_id, channel)}\"#{exe}\"")
          Process.detach(pid)
        end
      end
    end

    def wine_configuration(app_id, channel)
      logger.info(LOG_TAG) { "Wine Configuration Request: #{app_id}-#{channel}" }

      # open wwconfig.exe or config.exe for ecw

      return unless (app_data = installed?(app_id, channel) && W3DHub.unix?)

      exe = if !Store.settings[:wine_prefix].to_s.empty?
              "WINEPREFIX=\"#{Store.settings[:wine_prefix]}\" winecfg"
            else
              "winecfg"
            end

      Process.spawn(exe)
    end

    def repair(app_id, channel)
      logger.info(LOG_TAG) { "Repair Installation Request: #{app_id}-#{channel}" }

      return false if !installed?(app_id, channel) || installing?(app_id, channel)

      # verify/download manifests
      # verify game files
      # verify package cache packages of any files that failed verification
      # re/download needed packages
      # unpack packages
      # install dependencies (e.g. visual C runtime) if appropriate

      @tasks.push(Repairer.new(app_id, channel))
    end

    def uninstall(app_id, channel)
      logger.info(LOG_TAG) { "Uninstall Request: #{app_id}-#{channel}" }

      return false if !installed?(app_id, channel) || installing?(app_id, channel)

      return false unless (game = Store.applications.games.find { |g| g.id == app_id })

      push_state(
        States::ConfirmDialog,
        title: "Uninstall #{game.name}?",
        message: "Are you sure you want to uninstall #{game.name} (#{channel})?",
        accept_callback: proc {
          @tasks.push(Uninstaller.new(app_id, channel))
        }
      )
    end

    def show_folder(app_id, channel, type)
      logger.info(LOG_TAG) { "Show Folder Request: #{app_id} -> #{type.inspect}" }

      app_data = installed?(app_id, channel)

      return false unless app_data

      cmd = if W3DHub.windows?
              "explorer"
            elsif W3DHub.linux?
              "xdg-open"
            elsif W3DHub.mac?
              "open"
            end

      # TODO: Change if this correct on Linux
      user_data_path = "#{Dir.home}/Documents/W3D Hub/games/#{app_id}-#{channel}"
      user_data_path = "#{Dir.home}/Documents/Renegade" if app_id == "ren"

      path = case type
      when :installation
        app_data[:install_directory]
      when :user_data
        user_data_path
      when :screenshots
        screenshots_path = "#{user_data_path}/Screenshots"
        screenshots_path = "#{user_data_path}/Client/Screenshots" if app_id == "ren"
        Dir.exist?(screenshots_path) ? screenshots_path : user_data_path
      else
        raise "Unknown folder type: #{type.inspect}"
      end

      path.gsub!("/", "\\") if W3DHub.windows?

      system("#{cmd} \"#{path}\"")
    end

    def wine_command(app_id, channel)
      return "" if W3DHub.windows?

      "\"#{Store.settings[:wine_command]}\" "
    end

    def wine_enviroment_variables(app_id, channel)
      vars = {}
      return vars if W3DHub.windows?

      vars["WINEPREFIX"] = Store.settings[:wine_prefix] unless Store.settings[:wine_prefix].to_s.empty?
      # vars["WINEDEBUG"] = "-all" if true # TODO make this an option. wine debug interferences with pid returned from Process.spawn

      vars
    end

    def mangohud_command(app_id, channel)
      return "" if W3DHub.windows?

      # TODO: Add game specific options
      # OPENGL?
      if false && system("which mangohud")
        "MANGOHUD=1 MANGOHUD_DLSYM=1 DXVK_HUD=1 mangohud "
      else
        ""
      end
    end

    def mangohud_enviroment_variables(app_id, channel)
      vars = {}
      return vars if W3DHub.windows?

      vars
    end

    def dxvk_command(app_id, channel)
      return "" if W3DHub.windows?

      # Vulkan
      # SETTING && WINE WILL USE DXVK?
      if false && true#system()
        _setting = "full"
        "DXVK_HUD=#{_setting} "
      else
        ""
      end
    end

    def dxvk_enviroment_variables(app_id, channel)
      vars = {}
      return vars if W3DHub.windows?

      vars
    end

    def start_command(path, exe)
      if W3DHub.windows?
        "start /D \"#{path}\" /B #{exe}"
      else
        "#{path}/#{exe}"
      end
    end

    def run(app_id, channel, *args)
      if (app_data = installed?(app_id, channel))
        install_directory = app_data[:install_directory]
        exe_path = app_id == "ecw" ? "#{install_directory}/game500.exe" : app_data[:install_path]
        exe_path.gsub!("/", "\\") if W3DHub.windows?
        exe_path.gsub!("\\", "/") if W3DHub.unix?

        exe = File.basename(exe_path)
        path = File.dirname(exe_path)

        env = {}
        if W3DHub.unix?
          env.merge!(
            dxvk_enviroment_variables(app_id, channel),
            mangohud_enviroment_variables(app_id, channel),
            wine_enviroment_variables(app_id, channel)
          )
        end
        attempted = false
        begin
          pid = Process.spawn(
            env,
            "#{dxvk_command(app_id, channel)}"\
            "#{mangohud_command(app_id, channel)}"\
            "#{wine_command(app_id, channel)}"\
            "#{attempted ? start_command(path, exe) : "\"#{exe_path}\""} "\
            "-launcher #{args.join(' ')}"
          )
          Process.detach(pid)
          BackgroundWorker.foreground_parallel_job(-> { monitor_process(app_id, channel, pid) }, ->(result) { handle_process_result(app_id, channel, result) })
        rescue Errno::EINVAL => e
          retryable = !attempted
          attempted = true

          # Assume that we're on windoze and that the game requires admin
          retry if retryable

          # TODO: Show an error message if we reach here...
        end
      end
    end

    def monitor_process(app_id, channel, pid)
      key = "#{app_id}-#{channel}"
      @running_applications[key] = pid

      status = Process::Status.wait(pid)
      pp [pid, status]

      @running_applications.delete(key)

      status
    end

    def handle_process_result(app_id, channel, status)
      pp [app_id, channel, status]

      # Everything's fine
      return if status.pid >= 0 && status.success?

      # Everything's not fine
      reason = status.pid.positive? ? "Crashed" : "Failed to Launch"
      game = Store.applications.games.find { |g| g.id == app_id }
      title = "#{reason}: #{game.name}" if game
      title = "Application #{reason}" unless game

      message = if status.pid.negative?
                  "Command Not Found."
                else
                  "Application crashed."
                end

      push_state(
        States::MessageDialog,
        title: title,
        message: message,
        accept_callback: proc {
        }
      )
    end

    def join_server(app_id, channel, server, username = Store.settings[:server_list_username], password = nil, multi = false)
      return unless installed?(app_id, channel) && username.to_s.length.positive?

      run(
        app_id, channel,
        "+connect #{server.address}:#{server.port} +netplayername #{username}#{password ? " +password \"#{password}\"" : ""}#{multi ? " +multi" : ""}"
      )
    end

    def play_now_server(app_id, channel)
      app_data = installed?(app_id, channel)

      return nil unless app_data

      server_options = Store.server_list.select do |server|
        server.game == app_id &&
          server.channel == channel &&
          !server.status.password &&
          server.status.player_count < server.status.max_players
      end
      # sort by player count HIGH to LOW
      # and by ping LOW to HIGH
      server_options.sort! do |a, b|
        [b.status.player_count, a.ping] <=> [a.status.player_count, b.ping]
      end

      # try to find server with lowest ping and matching version
      found_server = server_options.find { |server| server.version == app_data[:installed_version] }
      # try to find server with lowest ping and undefined version
      found_server ||= server_options.find { |server| server.version == Api::ServerListServer::NO_OR_DEFAULT_VERSION }

      found_server
    end

    def play_now(app_id, channel)
      server = play_now_server(app_id, channel)

      return false unless server

      if Store.settings[:server_list_username].to_s.length.zero?
        W3DHub.prompt_for_nickname(
          accept_callback: proc do |entry|
            Store.settings[:server_list_username] = entry
            Store.settings.save_settings

            if server.status.password
              W3DHub.prompt_for_password(
                accept_callback: proc do |password|
                  join_server(app_id, channel, server)
                end
              )
            else
              join_server(app_id, channel, server)
            end
          end
        )
      else
        join_server(app_id, channel, server)
      end
    end

    def favorite(app_id, bool)
      Store.settings[:favorites] ||= {}

      if bool
        Store.settings[:favorites][app_id.to_sym] = true
      else
        Store.settings[:favorites].delete(app_id.to_sym)
      end
    end

    def favorite?(app_id)
      Store.settings[:favorites] ||= {}

      Store.settings[:favorites][app_id.to_sym]
    end

    def app_order(app_id, int)
      Store.settings[:app_order] ||= {}

      Store.settings[:app_order][app_id.to_sym] = int
    end

    def app_order_index(app_id)
      Store.settings[:app_order] ||= {}

      Store.settings[:app_order][app_id.to_sym]
    end

    def auto_import
      return unless W3DHub.windows?

      Store.applications.games.each do |game|
        game.channels.each do |channel|
          if game.id == "ren" && channel.id == "release"
            auto_import_win32_registry(game, channel.id, 'SOFTWARE\Westwood\Renegade')
          else
            auto_import_win32_registry(game, channel.id)
          end
        end
      end
    end

    def auto_import_win32_registry(game, channel_id, registry_path = nil)
      return unless W3DHub.windows?

      app_id = game.id

      logger.info(LOG_TAG) { "Importing: #{app_id}-#{channel_id}" }

      require "win32/registry"

      registry_path ||= "SOFTWARE\\W3D Hub\\games\\#{app_id}-#{channel_id}"
      reg_type = Win32::Registry::KEY_READ

      reg_constant = app_id == "ren" ? Win32::Registry::HKEY_CURRENT_USER : Win32::Registry::HKEY_LOCAL_MACHINE

      begin
        reg_constant.open(registry_path, reg_type) do |reg|
          if (install_path = reg["InstallPath"])
            install_path = File.dirname(install_path)
            install_path.gsub!("\\", "/")

            exe_path = app_id == "ecw" ? "#{install_path}/game500.exe" : "#{install_path}/game.exe"

            if File.exist?(exe_path)
              installed_version = app_id == "ren" ? "1.0.0.0" : reg["InstalledVersion"]

              if (installed_app = installed?(app_id, channel_id))
                current_version = Gem::Version.new(installed_app[:installed_version])
                listed_version  = installed_version

                next if current_version >= listed_version
              end

              application_data = {
                name: game.name,
                install_directory: install_path,
                installed_version: installed_version,
                install_path: exe_path,
                wine_prefix: nil
              }

              Store.settings[:games] ||= {}
              Store.settings[:games][:"#{app_id}_#{channel_id}"] = application_data
              Store.settings.save_settings
            end
          end
        end
      rescue => e
        # puts e.class, e.message, e.backtrace
        if Win32::Registry::Error
          logger.warn(LOG_TAG) { "    Failed to import #{app_id}-#{channel_id}" }
        else
          logger.warn(LOG_TAG) { "    An error occurred while tying to import #{app_id}-#{channel_id}" }
          logger.warn(LOG_TAG) { e }
        end

        false
      end
    end

    def write_application_version_to_win32_registry(app_id, channel_id, version)
      # TODO: Figure out how to trigger UAC, but only for this so games DO NOT spawn with admin privileges.
      return
      return unless W3DHub.windows?
      return if app_id == "ren"

      require "win32/registry"

      registry_path ||= "SOFTWARE\\W3D Hub\\games\\#{app_id}-#{channel_id}"
      reg_type = Win32::Registry::KEY_ALL_ACCESS

      Win32::Registry::HKEY_LOCAL_MACHINE.open(registry_path, reg_type) do |reg|
        reg.write_s("InstalledVersion", version)
      end

    rescue => e
      puts e.class, e.message, e.backtrace
      if Win32::Registry::Error
        logger.warn(LOG_TAG) { "    Failed to update #{app_id}-#{channel_id} version in the registry" }
      else
        logger.warn(LOG_TAG) { "    An error occurred while tying to update #{app_id}-#{channel_id} version in the registry" }
        logger.warn(LOG_TAG) { e }
      end

      false
    end

    def imported!(application, channel, exe_path)
      exe_path.gsub!("\\", "/")

      application_data = {
        name: application.name,
        install_directory: File.dirname(exe_path),
        installed_version: channel.current_version,
        install_path: exe_path,
        wine_prefix: nil
      }

      Store.settings[:games] ||= {}
      Store.settings[:games][:"#{application.id}_#{channel.id}"] = application_data
      Store.settings.save_settings
    end

    def installed!(task)
      # install_dir
      # installed_version
      # installPath # game executable
      # wine_prefix # optional

      install_directory = Cache.install_path(task.application, task.channel)
      install_directory.gsub!("\\", "/")

      application_data = {
        name: task.application.name,
        install_directory: install_directory,
        installed_version: task.target_version,
        install_path: "#{install_directory}/game.exe",
        wine_prefix: task.wine_prefix
      }

      Store.settings[:games] ||= {}
      Store.settings[:games][:"#{task.app_id}_#{task.release_channel}"] = application_data
      Store.settings.save_settings

      write_application_version_to_win32_registry(task.app_id, task.release_channel, task.target_version)
    end

    def installed?(app_id, channel)
      Store.settings[:games, :"#{app_id}_#{channel}"]
    end

    def installing?(app_id, channel)
      @tasks.find { |t| t.is_a?(Installer) && t.app_id == app_id && t.release_channel == channel }
    end

    def updateable?(app_id, channel)
      installed_app = installed?(app_id, channel)

      return false unless installed_app

      listed_app = Store.applications.games.find { |g| g.id == app_id }

      return false unless listed_app

      listed_app_channel = listed_app&.channels&.find { |c| c.id == channel }

      return false unless listed_app_channel

      current_version = Gem::Version.new(installed_app[:installed_version])
      listed_version  = Gem::Version.new(listed_app_channel.current_version)

      listed_version > current_version
    end

    def uninstalled!(task)
      Store.settings[:games].delete(:"#{task.app_id}_#{task.release_channel}")
      Store.settings.save_settings
    end

    def color(app_id)
      Store.applications.games.detect { |g| g.id == app_id }&.color
    end

    def name(app_id)
      Store.applications.games.detect { |g| g.id == app_id }&.name
    end

    def channel_name(app_id, channel_id)
      app = Store.applications.games.detect { |g| g.id.to_s == app_id.to_s }
      return unless app

      app.channels.detect { |g| g.id.to_s == channel_id.to_s }&.name
    end

    def application(app_id)
      Store.applications.games.detect { |g| g.id.to_s == app_id.to_s }
    end

    def channel(app_id, channel_id)
      app = Store.applications.games.detect { |g| g.id.to_s == app_id.to_s }
      return unless app

      app.channels.detect { |g| g.id.to_s == channel_id.to_s }
    end

    # No application tasks are being done
    def idle?
      !busy?
    end

    # Whether some operation is in progress
    def busy?
      current_task
    end

    def current_task
      @tasks.find { |t| [:running, :paused].include?(t.state) }
    end

    def start_next_available_task
      return unless idle?

      @tasks.delete_if { |t| t.state == :complete || t.state == :halted || t.state == :failed }

      task = @tasks.find { |t| t.state == :not_started }
      task&.start
    end

    def task?(type, app_id, channel)
      @tasks.find do |t|
        t.type == type &&
        t.app_id == app_id &&
        t.release_channel == channel &&
        [ :not_started, :running, :paused ].include?(t.state)
      end
    end
  end
end
