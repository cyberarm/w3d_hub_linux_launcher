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

  def self.captured_commmand(command, &block)
    if windows?
      stdout_read, stdout_write = IO.pipe

      process_info = Process.create(
        command_line: command,
        creation_flags: Process::DETACHED_PROCESS,
        process_inherit: true,
        thread_inherit: true,
        inherit: true,
        startup_info: {
          stdout: stdout_write,
          stderr: stdout_write
        }
      )

      pid = process_info.process_id
      status = -1

      until (status = Process.get_exitcode(pid))
        readable, _writable, _errorable = IO.select([stdout_read], [], [], 1)

        readable&.each do |io|
          line = io.readpartial(1024)

          block&.call(line)
        end
      end

      stdout_read.close
      stdout_write.close

      status.zero?
    else
      IO.popen(command) do |io|
        io.each_line do |line|
          block&.call(line)
        end
      end

      $CHILD_STATUS.success?
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
