class W3DHub
  class Asterisk
    class States
      class IRCProfileForm < CyberarmEngine::GuiState
        def setup
          @profile = @options[:editing]

          theme W3DHub::THEME

          background 0xaa_444444

          stack(width: 1.0, max_width: 760, height: 1.0, max_height: 560, v_align: :center, h_align: :center, background: 0xff_222222) do
            # Title bar
            flow(width: 1.0, height: 32, padding: 8) do
              background 0x88_000000

              # tagline "<b>#{I18n.t(:"server_browser.direct_connect")}</b>", fill: true, text_align: :center
              tagline @profile ? "Update IRC Profile" : "Add IRC Profile", width: 1.0, text_align: :center
            end

            stack(width: 1.0, fill: true, padding_left: 8, padding_right: 8) do
              stack(width: 1.0, height: 60) do
                para "IRC Nickname:"
                @irc_nickname = edit_line "#{@profile&.nickname}", width: 1.0
              end

              stack(width: 1.0, height: 60) do
                flow(width: 1.0, height: 1.0) do
                  stack(width: 0.5, height: 1.0) do
                    para "IRC Username:"
                    @irc_username = edit_line "#{@profile&.username}", width: 1.0
                  end

                  stack(width: 0.5, height: 1.0) do
                    para "IRC Server Password:"
                    @irc_password = edit_line @profile ? Base64.strict_decode64(@profile.password) : "", width: 1.0, type: :password
                  end
                end
              end

              stack(width: 1.0, height: 60) do
                flow(width: 1.0, height: 1.0) do
                  stack(width: 0.75, height: 1.0) do
                    para "IRC Server IP or Hostname:"
                    @irc_hostname = edit_line "#{@profile&.server_hostname}", width: 1.0
                  end

                  stack(width: 0.249, height: 1.0) do
                    para "IRC Server Port:"
                    @irc_port = edit_line "#{@profile&.server_port || '6667'}", width: 1.0
                  end
                end
              end

              flow(width: 1.0, height: 60, margin_top: 8) do
                flow(width: 0.5, height: 60) do
                  para "IRC Server Use SSL:", margin_top: 8
                  @irc_bot = check_box "#{@profile&.server_bot}"
                end


                flow(width: 0.5, height: 60) do
                  para "IRC Verify Server SSL Certificate:", margin_top: 8
                  @irc_bot = check_box "#{@profile&.server_bot}"
                end
              end

              stack(width: 1.0, height: 60, margin_top: 32) do
                para "Brenbot Bot Name:"
                @irc_bot = edit_line "#{@profile&.server_bot}", width: 1.0
              end

              flow(width: 1.0, height: 60) do
                stack(width: 0.5, height: 60) do
                  para "Brenbot Auth Username:"
                  @irc_bot = edit_line "#{@profile&.server_bot}", width: 1.0
                end

                stack(width: 0.5, height: 60) do
                  para "Brenbot Auth Password:"
                  @irc_password = edit_line @profile ? Base64.strict_decode64(@profile.password) : "", width: 1.0, type: :password
                end
              end

              flow(fill: true)

              flow(width: 1.0, margin_top: 8, height: 40, padding_bottom: 8) do
                button "Cancel", fill: true, margin_right: 4 do
                  pop_state
                end

                flow(fill: true)

                @save_button = button "Save", fill: true, margin_left: 4, enabled: false do
                  pop_state
                  @options[:save_callback].call(
                    @profile,
                    @irc_nickname.value,
                    @irc_password.value,
                    @irc_hostname.value,
                    @irc_port.value,
                    @irc_bot.value
                  )
                end
              end
            end
          end
        end

        def draw
          previous_state&.draw

          Gosu.flush

          super
        end

        def update
          super

          @save_button.enabled = valid?
        end

        def button_down(id)
          super

          case id
          when Gosu::KB_ESCAPE
            pop_state
          end
        end

        def valid?
          generated_name = IRCProfileForm.generate_profile_name(
            @irc_nickname.value,
            @irc_hostname.value,
            @irc_port.value,
            @irc_bot.value
          )
          existing_profile = W3DHub::Store[:asterisk_config].irc_profiles.find { |profile| profile.name == generated_name }

          @irc_nickname.value.length.positive? &&
          @irc_password.value.length.positive? && # May be optional?
          @irc_hostname.value.length.positive? &&
          @irc_port.value.length.positive? &&
          @irc_bot.value.length.positive?
        end

        def self.generate_profile_name(nickname, hostname, port, bot)
          "#{bot}@#{hostname}:#{port} as #{nickname}"
        end
      end
    end
  end
end
