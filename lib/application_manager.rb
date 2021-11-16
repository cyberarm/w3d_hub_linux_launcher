class W3DHub
  class ApplicationManager
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
      installer.start
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

      # open wwconfig
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

    def installed?(app_id, channel)
      false
    end

    def installing?(app_id, channel)
      @tasks.find { |t| t.is_a?(Installer) && t.app_id == app_id }
    end

    # No application tasks are being done
    def idle?
      !busy?
    end

    # Whether some operation is in progress
    def busy?
      @tasks.any? { |t| t.state == :running }
    end

    def current_task
      @tasks.find { |t| t.state == :running }
    end
  end
end
