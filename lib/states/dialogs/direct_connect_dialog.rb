class W3DHub
  class States
    class DirectConnectDialog < Dialog
      def setup
        window.show_cursor = true
        W3DHub::Store[:asterisk_config] ||= Asterisk::Config.new

        theme(W3DHub::THEME)

        background 0xaa_525252

        stack(width: 1.0, max_width: 720, height: 1.0, max_height: 576, v_align: :center, h_align: :center, background: 0xee_222222) do
          # Title bar
          flow(width: 1.0, height: 36, padding: 8) do
            background 0x88_000000

            image "#{GAME_ROOT_PATH}/media/ui_icons/export.png", height: 1.0, align: :center, color: 0xaa_ffffff

            title "<b>#{I18n.t(:"server_browser.direct_connect")}</b>", fill: true, text_align: :center, font: BOLD_FONT
          end

          stack(width: 1.0, fill: true, scroll: true) do
            stack(width: 1.0, height: 72, margin_left: 8, margin_right: 8) do
              para "Server profiles", text_align: :center, width: 1.0

              flow(width: 1.0, fill: true) do
                list = W3DHub::Store[:asterisk_config].server_profiles.count.positive? ? W3DHub::Store[:asterisk_config].server_profiles.map { |pf| pf.name }.insert(0, "") : [""]

                @server_profiles_list = list_box items: list, fill: true, height: 1.0
                @server_profiles_list.subscribe(:changed) do |list|
                  list.items.delete("") if list.value != ""

                  profile = W3DHub::Store[:asterisk_config].server_profiles.find { |pf| pf.name == list.value }
                  populate_from_server_profile(profile ? profile : W3DHub::Store[:asterisk_config].settings)

                  valid_for_multiplayer?
                end

                button get_image("#{GAME_ROOT_PATH}/media/ui_icons/plus.png"), image_height: 1.0, tip: "Create new profile" do
                  push_state(Asterisk::States::ServerProfileForm, save_callback: method(:save_server_profile))
                end

                @server_delete_button = button get_image("#{GAME_ROOT_PATH}/media/ui_icons/minus.png"), image_height: 1.0, tip: "Remove selected profile" do
                  push_state(ConfirmDialog, title: "Are you sure?", message: "Remove Server Profile: \"#{@server_profiles_list.value}\"?", accept_callback: -> { delete_server_profile(server_profile_from_name(@server_profiles_list.value)) })
                end

                @server_edit_button = button get_image("#{GAME_ROOT_PATH}/media/ui_icons/save.png"), image_height: 1.0, tip: "Edit and save selected profile" do
                  push_state(Asterisk::States::ServerProfileForm, editing: W3DHub::Store[:asterisk_config].server_profiles.find { |pf| pf.name == @server_profiles_list.value }, save_callback: method(:save_server_profile))
                end
              end
            end

            stack(width: 1.0, fill: true, margin_top: 8, padding: 8, border_color: 0xff_111111, border_thickness: 1) do
              flow(width: 1.0, height: 72) do
                stack(width: 0.5, height: 1.0) do
                  para "Nickname:"
                  @server_nickname = edit_line "", width: 1.0, fill: true
                  @server_nickname.subscribe(:changed) do |e|
                    @changes_made = true if @server_profiles_list.value.length.positive?

                    valid_for_multiplayer?
                  end
                end

                stack(width: 0.5, height: 1.0) do
                  para "Server Password:"
                  @server_password = edit_line "", width: 1.0, fill: true, margin_left: 4, type: :password
                  @server_password.subscribe(:changed) do |e|
                    @changes_made = true if @server_profiles_list.value.length.positive?

                    valid_for_multiplayer?
                  end
                end
              end

              flow(width: 1.0, height: 72) do
                stack(width: 0.5, height: 1.0) do
                  para "Server IP or Hostname:"
                  @server_hostname = edit_line "", width: 1.0, fill: true
                  @server_hostname.subscribe(:changed) do |e|
                    @changes_made = true if @server_profiles_list.value.length.positive?

                    valid_for_multiplayer?
                  end
                end

                stack(width: 0.5, height: 1.0) do
                  para "Server Port:"
                  @server_port = edit_line "", width: 1.0, fill: true, margin_left: 4
                  @server_port.subscribe(:changed) do |e|
                    @changes_made = true if @server_profiles_list.value.length.positive?

                    valid_for_multiplayer?
                  end
                end
              end

              stack(width: 1.0, height: 72) do
                para "Game or Mod:"

                flow(width: 1.0, fill: true) do
                  list = W3DHub::Store[:asterisk_config].games.count.positive? ? W3DHub::Store[:asterisk_config].games.map { |g| g.title } : [""]

                  @games_list = list_box items: list, fill: true, height: 1.0
                  @games_list.subscribe(:changed) do |list|
                    list.items.delete("") if list.value != ""

                    @changes_made = true if @server_profiles_list.value.length.positive?

                    valid_for_multiplayer?
                  end

                  button get_image("#{GAME_ROOT_PATH}/media/ui_icons/plus.png"), image_height: 1.0, tip: "Add game" do
                    push_state(Asterisk::States::GameForm, save_callback: method(:save_game))
                  end

                  @game_delete_button = button get_image("#{GAME_ROOT_PATH}/media/ui_icons/minus.png"), image_height: 1.0, tip: "Remove selected game" do
                    push_state(ConfirmDialog, title: "Are you sure?", message: "Remove game: #{@games_list.value}?", accept_callback: -> { delete_game(game_from_title(@games_list.value)) })

                  end

                  @game_edit_button = button get_image("#{GAME_ROOT_PATH}/media/ui_icons/gear.png"), image_height: 1.0, tip: "Edit selected game" do
                    push_state(Asterisk::States::GameForm, editing: W3DHub::Store[:asterisk_config].games.find { |g| g.title == @games_list.value }, save_callback: method(:save_game))
                  end
                end
              end

              stack(width: 1.0, height: 72) do
                para "Launch arguments (Optional):"
                @launch_arguments = edit_line "", width: 1.0, fill: true
                @launch_arguments.subscribe(:changed) do |e|
                  @changes_made = true if @server_profiles_list.value.length.positive?

                  valid_for_multiplayer?
                end
              end

              stack(width: 1.0, height: 72) do
                para "IRC Profile (Optional):"

                flow(width: 1.0, fill: true) do
                  @irc_profiles_list = list_box items: W3DHub::Store[:asterisk_config].irc_profiles.map {| pf| pf.name }.insert(0, "None"), fill: true, height: 1.0
                  @irc_profiles_list.subscribe(:changed) do |list|
                    @changes_made = true if @server_profiles_list.value.length.positive?

                    valid_for_multiplayer?
                  end

                  button get_image("#{GAME_ROOT_PATH}/media/ui_icons/plus.png"), image_height: 1.0, tip: "Add IRC profile" do
                    push_state(Asterisk::States::IRCProfileForm, save_callback: method(:save_irc_profile))
                  end

                  @irc_delete_button = button get_image("#{GAME_ROOT_PATH}/media/ui_icons/minus.png"), image_height: 1.0, tip: "Remove selected IRC profile" do
                    push_state(ConfirmDialog, title: "Are you sure?", message: "Delete IRC Profile: #{@irc_profiles_list.value}?", accept_callback: -> { delete_irc_profile(irc_profile_from_name(@irc_profiles_list.value)) })
                  end

                  @irc_edit_button = button get_image("#{GAME_ROOT_PATH}/media/ui_icons/gear.png"), image_height: 1.0, tip: "Edit selected IRC profile" do
                    push_state(Asterisk::States::IRCProfileForm, editing: irc_profile_from_name(@irc_profiles_list.value), save_callback: method(:save_irc_profile))
                  end
                end
              end
            end
          end

          flow(width: 1.0, height: 46, padding: 8) do
            button "Cancel", width: 0.25 do
              pop_state
            end

            stack(fill: true)

            @connect_button = button "Connect", width: 0.25 do
              pop_state

              join_server(game_from_title(@games_list.value).path, @server_nickname.value, @server_hostname.value, @server_port.value, @server_password.value, @launch_arguments.value)

              handle_irc
            end
          end
        end
      end

      def update
        super

        if @server_profiles_list.value == ""
          @server_delete_button.enabled = false
          @server_edit_button.enabled = false
        else
          @server_delete_button.enabled = true
          @server_edit_button.enabled = true
        end

        if @games_list.value == ""
          @game_delete_button.enabled = false
          @game_edit_button.enabled = false
        else
          @game_delete_button.enabled = true
          @game_edit_button.enabled = true
        end

        if @irc_profiles_list.value == "None"
          @irc_delete_button.enabled = false
          @irc_edit_button.enabled = false
        else
          @irc_delete_button.enabled = true
          @irc_edit_button.enabled = true
        end

        if @games_list.value.empty? || @server_nickname.value.empty? || @server_hostname.value.empty? || @server_port.value.empty?
          @connect_button.enabled = false
        else
          @connect_button.enabled = true
        end
      end

      def populate_from_server_profile(profile)
        @server_nickname.value = profile.nickname
        @server_password.value = Base64.strict_decode64(profile.password)
        @server_hostname.value = profile.server_hostname
        @server_port.value     = profile.server_port

        @games_list.choose = profile.game_title if @games_list.items.find { |game| game == profile.game_title }
        @launch_arguments.value = profile.launch_arguments

        @irc_profiles_list.choose = profile.irc_profile if @irc_profiles_list.items.find { |irc| irc == profile.irc_profile }
      end

      def valid_for_singleplayer?
        @single_player_button&.enabled = @games_list.value != ""
      end

      def valid_for_multiplayer?
        @join_server_button&.enabled = @games_list.value != "" &&
                                       @server_nickname.value.length.positive? &&
                                       @server_hostname.value.length.positive? &&
                                       @server_port.value.length.positive?
      end

      def save_server_profile(updated, name)
        if updated
          updated.name = name
          updated.nickname = @server_nickname.value
          updated.password = Base64.strict_encode64(@server_password.value)
          updated.server_profile = @server_profiles_list.value
          updated.server_hostname = @server_hostname.value
          updated.server_port = @server_port.value
          updated.game_title = @games_list.value
          updated.launch_arguments = @launch_arguments.value
          updated.irc_profile = @irc_profiles_list.value
        else
          profile = Asterisk::ServerProfile.new(
            {
              name: name,
              nickname: @server_nickname.value,
              password: Base64.strict_encode64(@server_password.value),
              server_profile: @server_profiles_list.value,
              server_hostname: @server_hostname.value,
              server_port: @server_port.value,
              game_title: @games_list.value,
              launch_arguments: @launch_arguments.value,
              irc_profile: @irc_profiles_list.value
            }
          )

          W3DHub::Store[:asterisk_config].server_profiles << profile
        end

        W3DHub::Store[:asterisk_config].save_config

        @server_profiles_list.items = W3DHub::Store[:asterisk_config].server_profiles.map {|profile| profile.name }
        @server_profiles_list.items << "" if @server_profiles_list.items.empty?
        @server_profiles_list.choose = name

        @changes_made = false
      end

      def delete_server_profile(profile)
        index = W3DHub::Store[:asterisk_config].server_profiles.index(profile)
        return unless index

        W3DHub::Store[:asterisk_config].server_profiles.delete(profile)

        W3DHub::Store[:asterisk_config].save_config

        @server_profiles_list.items = W3DHub::Store[:asterisk_config].server_profiles.map { |pf| pf.name }
        if W3DHub::Store[:asterisk_config].server_profiles.size.positive?
          @server_profiles_list.choose = W3DHub::Store[:asterisk_config].server_profiles[index - 1 > 0 ? index - 1 : 0].name
        end
      end

      def server_profile_from_name(name)
        W3DHub::Store[:asterisk_config].server_profiles.find { |pf| name == pf.name }
      end

      def game_from_title(title)
        W3DHub::Store[:asterisk_config].games.find { |g| title == g.title }
      end

      def save_game(updated, path, title)
        if updated
          updated.path = path
          updated.title = title
        else
          game = Asterisk::Game.new({
            path: path,
            title: title
          })

          W3DHub::Store[:asterisk_config].games << game
        end

        W3DHub::Store[:asterisk_config].save_config

        @games_list.items = W3DHub::Store[:asterisk_config].games.map {|g| g.title }
        @games_list.choose = title
      end

      def delete_game(game)
        index = W3DHub::Store[:asterisk_config].games.index(game) || 0

        W3DHub::Store[:asterisk_config].games.delete(game)

        W3DHub::Store[:asterisk_config].save_config

        @games_list.items = W3DHub::Store[:asterisk_config].games.map {|g| g.title }
        @games_list.choose = W3DHub::Store[:asterisk_config].games[index - 1 > 0 ? index - 1 : 0].title
      end

      def irc_profile_from_name(name)
        W3DHub::Store[:asterisk_config].irc_profiles.find { |pf| name == pf.name }
      end

      def save_irc_profile(
                            updated, nickname, username, password,
                            server_hostname, server_port, server_ssl, server_verify_ssl,
                            bot_username, bot_auth_username, bot_auth_password
                          )
        generated_name = Asterisk::States::IRCProfileForm.generate_profile_name(
          nickname,
          server_hostname,
          server_port,
          bot_username
        )

        if updated
          updated.name = generated_name
          updated.nickname = nickname
          updated.username = username
          updated.password = Base64.strict_encode64(password)
          updated.server_hostname = server_hostname
          updated.server_port = server_port
          updated.server_ssl = server_ssl
          updated.server_verify_ssl = server_verify_ssl
          updated.bot_username = bot_username
          updated.bot_auth_username = bot_auth_username
          updated.bot_auth_password = Base64.strict_encode64(bot_auth_password)
        else
          profile = Asterisk::IRCProfile.new({
            name: generated_name,
            nickname: nickname,
            username: username,
            password: Base64.strict_encode64(password),
            server_hostname: server_hostname,
            server_port: server_port,
            server_ssl: server_ssl,
            server_verify_ssl: server_verify_ssl,
            bot_username: bot_username,
            bot_auth_username: bot_auth_username,
            bot_auth_password: Base64.strict_encode64(bot_auth_password)
          })

          W3DHub::Store[:asterisk_config].irc_profiles << profile
        end

        W3DHub::Store[:asterisk_config].save_config

        @irc_profiles_list.items = W3DHub::Store[:asterisk_config].irc_profiles.map {| pf| pf.name }.insert(0, "None")
        @irc_profiles_list.choose = generated_name
      end

      def delete_irc_profile(profile)
        index = W3DHub::Store[:asterisk_config].irc_profiles.index(profile)
        return unless index

        W3DHub::Store[:asterisk_config].irc_profiles.delete(profile)

        W3DHub::Store[:asterisk_config].save_config

        @irc_profiles_list.items = W3DHub::Store[:asterisk_config].irc_profiles.map {| pf| pf.name }.insert(0, "None")
        @irc_profiles_list.choose = W3DHub::Store[:asterisk_config].irc_profiles[index - 1 > 0 ? index - 1 : 0].name
      end

      def wine_command
        return "" if W3DHub.windows?

        "#{Store.settings[:wine_command]} "
      end

      # TODO
      def mangohud_command
        return "" if W3DHub.windows?

        # TODO: Add game specific options
        # OPENGL?
        if false && system("which mangohud")
          "MANGOHUD=1 MANGOHUD_DLSYM=1 DXVK_HUD=1 mangohud "
        else
          ""
        end
      end

      # TODO
      def dxvk_command
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

      def run(game_path, *args)
        pid = Process.spawn("#{dxvk_command}#{mangohud_command}#{wine_command}\"#{game_path}\" #{args.join(' ')}")
        Process.detach(pid)
      end

      def join_server(game_path, nickname, server_address, server_port, server_password, launch_arguments)
        server_password = nil if server_password.empty?
        launch_arguments = nil if launch_arguments.empty?

        run(
          game_path,
          "-launcher +connect #{server_address}:#{server_port} +netplayername #{nickname}#{server_password ? " +password \"#{server_password}\"" : ""}#{launch_arguments ? " #{launch_arguments}" : ''}"
        )
      end

      def handle_irc
        return unless (profile = irc_profile_from_name(@irc_profiles_list.value))

        Thread.new do
          sleep 15

          W3DHub::Asterisk::IRCClient.new(profile)
        end
      end
    end
  end
end
