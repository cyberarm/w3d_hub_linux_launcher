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

      def self.join_server(server, password)
        if (
          (server.status.password && password.length.positive?) ||
          !server.status.password) &&
           Store.settings[:server_list_username].to_s.length.positive?

          Store.application_manager.join_server(
            server.game,
            server.channel, server, password
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
    else
      if block
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
  end

  def self.home_directory
    File.expand_path("~")
  end

  def self.ask_file(title: "Open File", filter: "*game*.exe")
      result_ptr = LibUI.open_file(LIBUI_WINDOW)
      result = result_ptr.null? ? "" : result_ptr.to_s.gsub("\\", "/")

      result
  end

  def self.ask_folder(title: "Open Folder")
    result_ptr = LibUI.open_folder(window)
    result = result_ptr.null? ? "" : result_ptr.to_s.gsub("\\", "/")

    result
  end
end
