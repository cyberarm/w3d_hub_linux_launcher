class W3DHub
  def self.format_size(bytes)
    case bytes
    when 0..1023 # Bytes
      "#{bytes} B"
    when 1024..1_048_575 # KiloBytes
      "#{format_size_number(bytes / 1024.0)} KB"
    when 1_048_576..1_073_741_999 # MegaBytes
      "#{format_size_number(bytes / 1_048_576.0)} MB"
    else # GigaBytes
      "#{format_size_number(bytes / 1_073_742_000.0)} GB"
    end
  end

  def self.format_size_number(i)
    format("%0.2f", i)
  end

  def self.windows?
    RbConfig::CONFIG["host_os"] =~ /(mingw|mswin|windows)/i
  end

  def self.mac?
    RbConfig::CONFIG["host_os"] =~ /(darwin|mac os)/i
  end

  def self.linux?
    RbConfig::CONFIG["host_os"] =~ /(linux|bsd|aix|solaris)/i
  end

  def self.unix?
    linux? || mac?
  end

  def self.tar_command
    if windows?
      "tar"
    else
      "bsdtar"
    end
  end

  def self.commmand(command)
    if windows?

    else
      IO.popen(command)
    end
  end

  def self.home_directory
    File.expand_path("~")
  end

  def self.ask_file(title: "Open File", filter: "*game*.exe")
    if W3DHub.unix?
      # search for command
      cmds = %w{ zenity matedialog qarma kdialog }

      command = cmds.find do |cmd|
        cmd if system("which #{cmd}")
      end

      path = case File.basename(command)
      when "zenity", "matedialog", "qarma"
        `#{command} --file-selection --title "#{title}" --file-filter "#{filter}"`
      when "kdialog"
        `#{command} --title "#{title}" --getopenfilename . "#{filter}"`
      else
        raise "No known command found for system file selection dialog!"
      end

      path.strip
    else
      raise NotImplementedError
    end
  end
end
