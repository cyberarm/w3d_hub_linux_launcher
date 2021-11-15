class W3DHub
  class ApplicationManager
    def install(app_id)
      puts "Installation Request: #{app_id}"
    end

    def import(app_id, path)
      puts "Import Request: #{app_id} -> #{path}"
    end

    def settings(app_id)
      puts "Settings Request: #{app_id}"
    end

    def repair(app_id)
      puts "Repair Installation Request: #{app_id}"
    end

    def uninstall(app_id)
      puts "Uninstall Request: #{app_id}"
    end

    def show_folder(app_id, type)
      puts "Show Folder Request: #{app_id} -> #{type.inspect}"

      case type
      when :installation
      when :user_data
      when :screenshots
      else
        warn "Unknown folder type: #{type.inspect}"
      end
    end

    def installed?(app_id)
      false
    end

    # No application tasks are being done
    def idle?
      true
    end

    # Whether some operation is in progress
    def busy?
      !idle?
    end
  end
end
