class W3DHub
  class Asterisk
    class States
      class IRCProfileForm < CyberarmEngine::GuiState
        def setup
          @profile = @options[:editing]

          theme W3DHub::THEME

          background 0xcc_000000

          stack(width: 1.0, height: 248, margin: 48, padding: 16) do
            caption @game ? "Update IRC Profile" : "Add IRC Profile", width: 1.0, text_align: :center

            stack(width: 1.0, height: 60) do
              flow(width: 1.0, height: 1.0) do
                stack(width: 0.6, height: 1.0) do
                  para "IRC Nickname:"
                  @irc_nickname = edit_line "#{@profile&.nickname}", width: 1.0
                end

                stack(width: 0.4, height: 1.0) do
                  para "IRC Password:"
                  @irc_password = edit_line "#{@profile ? Base64.strict_decode64(@profile.password) : ''}", width: 1.0#, type: :password
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
                  para "IRC Port:"
                  @irc_port = edit_line "#{@profile&.server_port || '6667'}", width: 1.0
                end
              end
            end

            stack(width: 1.0, height: 60) do
              para "IRC Bot Name:"
              @irc_bot = edit_line "#{@profile&.server_bot}", width: 1.0
            end

            flow(width: 1.0, margin_top: 8) do
              button "Cancel", width: 0.5, margin_right: 4 do
                pop_state
              end

              @save_button = button "Save", width: 0.5, margin_left: 4, enabled: false do
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

        # def draw
        #   previous_state&.draw

        #   Gosu.flush

        #   super
        # end

        def update
          super

          @save_button.enabled = valid?
        end

        def close
          pop_state
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
