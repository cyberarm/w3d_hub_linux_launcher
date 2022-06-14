class W3DHub
  class States
    class DirectConnectDialog < CyberarmEngine::GuiState
      def setup
        window.show_cursor = true
        W3DHub::Store[:asterisk_config] ||= Asterisk::Config.new

        theme(W3DHub::THEME)

        background 0xee_444444

        stack(width: 1.0, max_width: 720, height: 1.0, max_height: 540, v_align: :center, h_align: :center, background: 0xee_222222) do
          # Title bar
          flow(width: 1.0, height: 32, padding: 8) do
            background 0x88_000000

            image "#{GAME_ROOT_PATH}/media/ui_icons/export.png", width: 32, align: :center, color: 0xaa_ffffff

            tagline "<b>#{I18n.t(:"server_browser.direct_connect")}</b>", fill: true, text_align: :center
          end

          stack(width: 1.0, fill: true, scroll: true) do
            stack(width: 1.0, height: 66, margin_left: 8, margin_right: 8) do
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
                  push_state(ConfirmDialog, message: "Purge server profile")
                end

                @server_edit_button = button get_image("#{GAME_ROOT_PATH}/media/ui_icons/save.png"), image_height: 1.0, tip: "Edit and save selected profile" do
                  push_state(Asterisk::States::ServerProfileForm, editing: W3DHub::Store[:asterisk_config].server_profiles.find { |pf| pf.name == @server_profiles_list.value }, save_callback: method(:save_server_profile))
                end
              end
            end

            stack(width: 1.0, fill: true, margin_top: 8, padding: 8, border_color: 0xff_111111, border_thickness: 1) do
              flow(width: 1.0, height: 66) do
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

              flow(width: 1.0, height: 66) do
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

              stack(width: 1.0, height: 66) do
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
                    push_state(ConfirmDialog, message: "Remove game?")
                  end

                  @game_edit_button = button get_image("#{GAME_ROOT_PATH}/media/ui_icons/gear.png"), image_height: 1.0, tip: "Edit selected game" do
                    push_state(Asterisk::States::GameForm, editing: W3DHub::Store[:asterisk_config].games.find { |g| g.title == @games_list.value }, save_callback: method(:save_game))
                  end
                end
              end

              stack(width: 1.0, height: 66) do
                para "Launch arguments (Optional):"
                @launch_arguments = edit_line "", width: 1.0, fill: true
                @launch_arguments.subscribe(:changed) do |e|
                  @changes_made = true if @server_profiles_list.value.length.positive?

                  valid_for_multiplayer?
                end
              end

              stack(width: 1.0, height: 66) do
                para "IRC Profile:"

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
                    push_state(ConfirmDialog, message: "")
                  end

                  @irc_edit_button = button get_image("#{GAME_ROOT_PATH}/media/ui_icons/gear.png"), image_height: 1.0, tip: "Edit selected IRC profile" do
                    push_state(Asterisk::States::IRCProfileForm, editing: W3DHub::Store[:asterisk_config].irc_profiles.find { |pf| pf.name == @irc_profiles_list.value }, save_callback: method(:save_irc_profile))
                  end
                end
              end
            end
          end

          flow(width: 1.0, height: 40, padding: 8) do
            button "Cancel", width: 0.25 do
              pop_state
              @options[:cancel_callback]&.call
            end

            stack(fill: true)

            button "Connect", width: 0.25 do
              pop_state
              @options[:accept_callback]&.call
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
      end

      def draw
        previous_state&.draw

        Gosu.flush

        super
      end

      def populate_from_server_profile(profile)
        @server_nickname.value = profile.nickname
        @server_password.value = Base64.strict_decode64(profile.password)
        @server_hostname.value = profile.server_hostname
        @server_port.value     = profile.server_port

        @games_list.choose = profile.game if @games_list.items.find { |game| game == profile.game }
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
          updated.game = @games_list.value
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
              game: @games_list.value,
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
          updated.server_hostname = hserver_hostname
          updated.server_port = hserver_port
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
    end
  end
end
