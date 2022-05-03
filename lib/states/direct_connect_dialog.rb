class W3DHub
  class States
    class DirectConnectDialog < CyberarmEngine::GuiState
      def setup
        window.show_cursor = true

        theme(W3DHub::THEME)

        background 0xee_444444

        stack(width: 1.0, height: 1.0, margin: 128, background: 0xee_222222) do
          # Title bar
          flow(width: 1.0, height: 32, padding: 8) do
            background 0x88_000000

            image "#{GAME_ROOT_PATH}/media/ui_icons/export.png", width: 32, align: :center, color: 0xaa_ffffff

            tagline "<b>#{I18n.t(:"server_browser.direct_connect")}</b>", fill: true, text_align: :center
          end

          stack(width: 1.0, fill: true, scroll: true) do
            stack(width: 1.0, height: 60, margin_left: 8, margin_right: 8) do
              para "Server profiles", text_align: :center, width: 1.0

              flow(width: 1.0, fill: true) do
                list = [""] # window.config.server_profiles.count.positive? ? window.config.server_profiles.map { |pf| pf.name }.insert(0, "") : [""]

                @server_profiles_list = list_box items: list, fill: true, height: 1.0
                @server_profiles_list.subscribe(:changed) do |list|
                  list.items.delete("") if list.value != ""

                  profile = window.config.server_profiles.find { |pf| pf.name == list.value }
                  populate_from_server_profile(profile ? profile : window.config.settings)

                  valid_for_multiplayer?
                end

                button get_image("#{GAME_ROOT_PATH}/media/ui_icons/plus.png"), image_height: 1.0, tip: "Create new profile" do
                  push_state(ServerProfileForm, save_callback: method(:save_server_profile))
                end

                @server_delete_button = button get_image("#{GAME_ROOT_PATH}/media/ui_icons/minus.png"), image_height: 1.0, tip: "Remove selected profile" do
                  push_state(ConfirmDialog, message: "Purge server profile")
                end

                @server_edit_button = button get_image("#{GAME_ROOT_PATH}/media/ui_icons/gear.png"), image_height: 1.0, tip: "Edit and save selected profile" do
                  push_state(ServerProfileForm, editing: window.config.server_profiles.find { |pf| pf.name == @server_profiles_list.value }, save_callback: method(:save_server_profile))
                end
              end
            end

            stack(width: 1.0, fill: true, margin_top: 8, padding: 8, border_color: 0xff_111111, border_thickness: 1) do
              flow(width: 1.0, height: 60) do
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

              flow(width: 1.0, height: 60) do
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

              stack(width: 1.0, height: 60) do
                para "Game or Mod:"

                flow(width: 1.0, fill: true) do
                  list = [""] # window.config.games.count.positive? ? window.config.games.map { |g| g.title } : [""]

                  @games_list = list_box items: list, fill: true, height: 1.0
                  @games_list.subscribe(:changed) do |list|
                    list.items.delete("") if list.value != ""

                    @changes_made = true if @server_profiles_list.value.length.positive?

                    valid_for_multiplayer?
                  end

                  button get_image("#{GAME_ROOT_PATH}/media/ui_icons/plus.png"), image_height: 1.0, tip: "Add game" do
                    push_state(GameForm, save_callback: method(:save_game))
                  end

                  @game_delete_button = button get_image("#{GAME_ROOT_PATH}/media/ui_icons/minus.png"), image_height: 1.0, tip: "Remove selected game" do
                    push_state(ConfirmDialog, message: "Remove game?")
                  end

                  @game_edit_button = button get_image("#{GAME_ROOT_PATH}/media/ui_icons/gear.png"), image_height: 1.0, tip: "Edit selected game" do
                    push_state(GameForm, editing: window.config.games.find { |g| g.title == @games_list.value }, save_callback: method(:save_game))
                  end
                end
              end

              stack(width: 1.0, height: 60) do
                para "Launch arguments (Optional):"
                @launch_arguments = edit_line "", width: 1.0, fill: true
                @launch_arguments.subscribe(:changed) do |e|
                  @changes_made = true if @server_profiles_list.value.length.positive?

                  valid_for_multiplayer?
                end
              end

              stack(width: 1.0, height: 60) do
                para "IRC Profile:"

                flow(width: 1.0, fill: true) do
                  @irc_profiles_list = list_box items: ["None"], fill: true, height: 1.0
                  @irc_profiles_list.subscribe(:changed) do |list|
                    @changes_made = true if @server_profiles_list.value.length.positive?

                    valid_for_multiplayer?
                  end

                  button get_image("#{GAME_ROOT_PATH}/media/ui_icons/plus.png"), image_height: 1.0, tip: "Add IRC profile" do
                    push_state(IRCProfileForm, save_callback: method(:save_irc_profile))
                  end

                  @irc_delete_button = button get_image("#{GAME_ROOT_PATH}/media/ui_icons/minus.png"), image_height: 1.0, tip: "Remove selected IRC profile" do
                    push_state(ConfirmDialog, message: "")
                  end

                  @irc_edit_button = button get_image("#{GAME_ROOT_PATH}/media/ui_icons/gear.png"), image_height: 1.0, tip: "Edit selected IRC profile" do
                    push_state(IRCProfileForm, editing: window.config.irc_profiles.find { |pf| pf.name == @irc_profiles_list.value }, save_callback: method(:save_irc_profile))
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

      def draw
        previous_state&.draw

        Gosu.flush

        super
      end
    end
  end
end
