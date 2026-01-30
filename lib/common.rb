class W3DHub
  PLATFORM_WINDOWS = RbConfig::CONFIG["host_os"] =~ /(mingw|mswin|windows)/i
  PLATFORM_DARWIN = RbConfig::CONFIG["host_os"] =~ /(darwin|mac os)/i
  PLATFORM_LINUX = RbConfig::CONFIG["host_os"] =~ /(linux|bsd|aix|solaris)/i

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
    PLATFORM_WINDOWS
  end

  def self.mac?
    PLATFORM_DARWIN
  end

  def self.linux?
    PLATFORM_LINUX
  end

  def self.unix?
    linux? || mac?
  end

  # Detect system CA bundle path for SSL verification
  def self.ca_bundle_path
    [
      "/etc/ssl/certs/ca-certificates.crt",      # Debian/Ubuntu
      "/etc/pki/tls/certs/ca-bundle.crt",        # RHEL/Fedora/CentOS
      "/etc/ssl/ca-bundle.pem"                   # Some other distros
    ].find { |path| File.exist?(path) }
  end

  def self.url(path)
    raise "Hazardous input: #{path}" if path.include?("&&") || path.include?(";")

    if windows?
      system("start #{path}")
    elsif linux?
      system("xdg-open #{path}")
    elsif mac?
      system("open #{path}")
    end
  end

  def self.prompt_for_nickname(accept_callback: nil, cancel_callback: nil)
        CyberarmEngine::Window.instance.push_state(
          W3DHub::States::PromptDialog,
          title: I18n.t(:"server_browser.set_nickname"),
          message: I18n.t(:"server_browser.set_nickname_message"),
          prefill: Store.settings[:server_list_username],
          accept_callback: accept_callback,
          cancel_callback: cancel_callback,
          # See: https://gitlab.com/danpaul88/brenbot/-/blob/master/Source/renlog.pm#L136-175
          valid_callback: proc do |entry|
            entry.length > 1 && entry.length < 30 && (entry =~ /(:|!|&|%| )/i).nil? &&
              (entry =~ /[\001\002\037]/).nil? && (entry =~ /\\/).nil?
          end
        )
      end

      def self.prompt_for_password(accept_callback: nil, cancel_callback: nil)
        CyberarmEngine::Window.instance.push_state(
          W3DHub::States::PromptDialog,
          title: I18n.t(:"server_browser.enter_password"),
          message: I18n.t(:"server_browser.enter_password_message"),
          input_type: :password,
          accept_callback: accept_callback,
          cancel_callback: cancel_callback,
          valid_callback: proc { |entry| entry.length.positive? }
        )
      end

      def self.join_server(server:, username: Store.settings[:server_list_username], password: nil, multi: false)
        if (
          (server.status.password && password.length.positive?) ||
          !server.status.password) &&
           username.to_s.length.positive?

          Store.application_manager.join_server(
            server.game,
            server.channel,
            server,
            username,
            password,
            multi
          )
        else
          CyberarmEngine::Window.instance.push_state(W3DHub::States::MessageDialog, type: "?", title: "?", message: "?")
        end
      end

  def self.command(command, &block)
    if windows?
      stdout_read, stdout_write = IO.pipe if block

      hash = {
        command_line: command,
        creation_flags: Process::DETACHED_PROCESS,
        process_inherit: true,
        thread_inherit: true,
        close_handles: false,
        inherit: true
      }

      if block
        hash[:startup_info] = {
          stdout: stdout_write,
          stderr: stdout_write
        }
      end

      process_info = Process.create(**hash)

      pid = process_info.process_id
      status = -1

      until (status = Process.get_exitcode(pid))
        if block
          readable, _writable, _errorable = IO.select([stdout_read], [], [], 1)

          readable&.each do |io|
            line = io.readpartial(1024)

            block&.call(line)
          end
        else
          sleep 0.1
        end
      end

      status.zero?
    elsif block
      IO.popen(command, "r") do |io|
        io.each_line do |line|
          block&.call(line)
        end
      end

      $CHILD_STATUS.success?
    else
      system(command)
    end
  end

  def self.home_directory
    File.expand_path("~")
  end

  def self.ask_file(title: "Open File", filter: "*game*.exe", filters: [])
    filters << filter if filters.empty?

    if W3DHub.unix?
      # search for command
      cmds = %w[zenity matedialog qarma kdialog]

      command = cmds.find do |cmd|
        cmd if system("which #{cmd}")
      end

      path = case File.basename(command)
             when "zenity", "matedialog", "qarma"
               options = filters.map { |s| format("--file-filter=\"%s\"", s) }.join(" ")
               `#{command} --file-selection --title \"#{title}\" #{options}`
             when "kdialog"
               `#{command} --title "#{title}" --getopenfilename . "#{filters.join(" ")}"`
             else
               raise "No known command found for system file selection dialog!"
             end

      path.strip
    else
      result_ptr = LibUI.open_file(LIBUI_WINDOW)
      result = result_ptr.null? ? "" : result_ptr.to_s.gsub("\\", "/")

      result.strip
    end
  end

  def self.ask_folder(title: "Open Folder")
    if W3DHub.unix?
      # search for command
      cmds = %w[zenity matedialog qarma kdialog]

      command = cmds.find do |cmd|
        cmd if system("which #{cmd}")
      end

      path = case File.basename(command)
             when "zenity", "matedialog", "qarma"
               `#{command} --file-selection --directory --title "#{title}"`
             when "kdialog"
               `#{command} --title "#{title}" --getexistingdirectory #{Dir.home}"`
             else
               raise "No known command found for system file selection dialog!"
             end

      path.strip
    else
      result_ptr = LibUI.open_folder(LIBUI_WINDOW)
      result = result_ptr.null? ? "" : result_ptr.to_s.gsub("\\", "/")

      result.strip
    end
  end
end
