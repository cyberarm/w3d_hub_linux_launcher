class W3DHub
  class ApplicationManager
    include CyberarmEngine::Common

    def initialize
      @tasks = [] # :installer, :importer, :repairer, :uninstaller
    end

    def install(app_id, channel)
      puts "Installation Request: #{app_id}-#{channel}"

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

    def import(app_id, channel, path)
      puts "Import Request: #{app_id}-#{channel} -> #{path}"

      # Check registry for auto-import if windows
      # if auto-import fails ask user for path to game exe
      # mark app as imported/installed

      @tasks.push(Importer.new(app_id, channel, path))
    end

    def settings(app_id, channel)
      puts "Settings Request: #{app_id}-#{channel}"

      # open wwconfig.exe or config.exe for ecw

      if (app_data = installed?(app_id, channel))
        config_exe = app_id == "ecw" ? "config.exe" : "wwconfig.exe"
        exe = "#{app_data[:install_directory]}/#{config_exe}"

        if File.exist?(exe)
          pid = Process.spawn("#{wine_command(app_id, channel)}\"#{exe}\"")
          Process.detach(pid)
        end
      end
    end

    def wine_configuration(app_id, channel)
      puts "Wine Configuration Request: #{app_id}-#{channel}"

      # open wwconfig.exe or config.exe for ecw

      if (app_data = installed?(app_id, channel) && W3DHub.unix?)
        exe = if window.settings[:wine_prefix]
          "WINEPREFIX=\"#{window.settings[:wine_prefix]}\" winecfg"
        else
          "winecfg"
        end

        Process.spawn("#{exe}")
      end
    end

    def repair(app_id, channel)
      puts "Repair Installation Request: #{app_id}-#{channel}"

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
      puts "Uninstall Request: #{app_idchannel}"

      return false if !installed?(app_id, channel) || installing?(app_id, channel)

      @tasks.push(Uninstaller.new(app_id, channel))
    end

    def show_folder(app_id, channel, type)
      puts "Show Folder Request: #{app_id} -> #{type.inspect}"

      case type
      when :installation
      when :user_data
      when :screenshots
      else
        warn "Unknown folder type: #{type.inspect}"
      end
    end

    def wine_command(app_id, channel)
      return "" if W3DHub.windows?

      if window.settings[:wine_prefix]
        "WINEPREFIX=\"#{window.settings[:wine_prefix]}\" \"#{window.settings[:wine_command]}\" "
      else
        "#{window.settings[:wine_command]} "
      end
    end

    def run(app_id, channel, *args)
      if (app_data = installed?(app_id, channel))
        pp "#{wine_command(app_id, channel)}#{app_data[:install_path]}", *args
        pid = Process.spawn("#{wine_command(app_id, channel)}#{app_data[:install_path]}", *args)
        Process.detach(pid)
      end
    end

    def join_server(app_id, channel, server, password = nil)
      if installed?(app_id, channel) && window.settings[:server_list_username].to_s.length.positive?
        run(
          app_id, channel,
          "-launcher",
          "+connect #{server.address}:#{server.port}",
          "+netplayername \"#{window.settings[:server_list_username]}\"",
          password ? "+password \"#{password}\"" : ""
        )
      end
    end

    def auto_import
      return unless W3DHub.windows?

      # Renegade
      auto_import_win32_registry("ren", "release", 'SOFTWARE\Westwood\Renegade')

      # Red Alert: A Path Beyond
      auto_import_win32_registry("apb", "release")

      # Expansive Civilian Warfare
      auto_import_win32_registry("ecw", "release")

      # Interim Apex
      auto_import_win32_registry("ia", "release")

      # Tiberian Sun: Reborn
      auto_import_win32_registry("tsr", "release")
    end

    def auto_import_win32_registry(app_id, channel_id, registry_path = nil)
      return unless W3DHub.windows?
      return if installed?(app_id, channel_id)

      puts "Importing: #{app_id}-#{channel_id}"

      require "win32/registry"

      registry_path ||= "SOFTWARE\\W3D Hub\\games\\#{app_id}-#{channel_id}"
      reg_type = Win32::Registry::KEY_READ

      reg_constant = app_id == "ren" ? Win32::Registry::HKEY_CURRENT_USER : Win32::Registry::HKEY_LOCAL_MACHINE

      begin
        reg_constant.open(registry_path, reg_type) do |reg|
          if (install_path = reg["InstallPath"])
            if File.exist?(install_path) || (app_id == "ecw" && File.exist?("#{File.dirname(install_path)}/game750.exe"))
              install_path.gsub!("\\", "/")
              installed_version = reg["InstalledVersion"] unless app_id == "ren"

              application_data = {
                install_directory: File.dirname(install_path),
                installed_version: app_id == "ren" ? "1.0.0.0" : installed_version,
                install_path: app_id == "ecw" ? "#{File.dirname(install_path)}/game750.exe" : install_path,
                wine_prefix: nil
              }

              window.settings[:games] ||= {}
              window.settings[:games][:"#{app_id}_#{channel_id}"] = application_data
              window.settings.save_settings
            end
          end
        end
      rescue => e
        puts e.message, e.backtrace

        false
      end
    end

    def installed!(task)
      # install_dir
      # installed_version
      # installPath # game executable
      # wine_prefix # optional

      install_directory = Cache.install_path(task.application, task.channel)
      application_data = {
        install_directory: install_directory,
        installed_version: task.channel.current_version,
        install_path: "#{install_directory}/game.exe",
        wine_prefix: task.wine_prefix
      }

      window.settings[:games] ||= {}
      window.settings[:games][:"#{task.app_id}_#{task.release_channel}"] = application_data
      window.settings.save_settings
    end

    def installed?(app_id, channel)
      window.settings[:games, :"#{app_id}_#{channel}"]
    end

    def installing?(app_id, channel)
      @tasks.find { |t| t.is_a?(Installer) && t.app_id == app_id && t.release_channel == channel }
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
