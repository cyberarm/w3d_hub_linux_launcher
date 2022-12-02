class W3DHub
  class ApplicationManager
    LOG_TAG = "W3DHub::ApplicationManager".freeze
    include CyberarmEngine::Common

    def initialize
      @tasks = [] # :installer, :importer, :repairer, :uninstaller
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

      @tasks.push(Importer.new(app_id, channel))
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

      if (app_data = installed?(app_id, channel) && W3DHub.unix?)
        exe = if Store.settings[:wine_prefix]
          "WINEPREFIX=\"#{Store.settings[:wine_prefix]}\" winecfg"
        else
          "winecfg"
        end

        Process.spawn("#{exe}")
      end
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

      path = case type
      when :installation
        app_data[:install_directory]
      when :user_data
        user_data_path
      when :screenshots
        Dir.exist?("#{user_data_path}/Screenshots") ? "#{user_data_path}/Screenshots" : user_data_path
      else
        raise "Unknown folder type: #{type.inspect}"
      end

      path.gsub!("/", "\\") if W3DHub.windows?

      system("#{cmd} \"#{path}\"")
    end

    def wine_command(app_id, channel)
      return "" if W3DHub.windows?

      if Store.settings[:wine_prefix]
        "WINEPREFIX=\"#{Store.settings[:wine_prefix]}\" \"#{Store.settings[:wine_command]}\" "
      else
        "#{Store.settings[:wine_command]} "
      end
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

    def run(app_id, channel, *args)
      if (app_data = installed?(app_id, channel))
        pid = Process.spawn("#{dxvk_command(app_id, channel)}#{mangohud_command(app_id, channel)}#{wine_command(app_id, channel)}\"#{app_data[:install_path]}\" #{args.join(' ')}")
        Process.detach(pid)
      end
    end

    def join_server(app_id, channel, server, password = nil)
      if installed?(app_id, channel) && Store.settings[:server_list_username].to_s.length.positive?
        run(
          app_id, channel,
          "-launcher +connect #{server.address}:#{server.port} +netplayername #{Store.settings[:server_list_username]}#{password ? " +password \"#{password}\"" : ""}"
        )
      end
    end

    def play_now_server(app_id, channel)
      app_data = installed?(app_id, channel)

      return nil unless app_data

      found_server = Store.server_list.select do |server|
        server.game == app_id && server.channel == channel && !server.status.password
      end&.first

      found_server ? found_server : nil
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
      end
    end

    def favorive(app_id, bool)
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
          if (install_path = reg["InstallDir"])
            install_path.gsub!("\\", "/")

            exe_path = app_id == "ecw" ? "#{install_path}/game750.exe" : "#{install_path}/game.exe"

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

    def imported!(task, exe_path)
      application_data = {
        name: task.application.name,
        install_directory: File.dirname(exe_path),
        installed_version: task.channel.current_version,
        install_path: exe_path,
        wine_prefix: task.wine_prefix
      }

      Store.settings[:games] ||= {}
      Store.settings[:games][:"#{task.app_id}_#{task.release_channel}"] = application_data
      Store.settings.save_settings
    end

    def installed!(task)
      # install_dir
      # installed_version
      # installPath # game executable
      # wine_prefix # optional

      install_directory = Cache.install_path(task.application, task.channel)
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
