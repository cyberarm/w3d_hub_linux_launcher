class W3DHub
  class Pages
    class Login < Page
      def setup
        body.clear do
          flow(width: 1.0, height: 1.0, padding: 32) do
            background 0xff_252535

            stack(width: 0.28)

            stack(width: 0.48) do
              flow(width: 1.0) do
                stack(width: 0.4)
                image "#{GAME_ROOT_PATH}/media/icons/w3dhub.png", width: 0.20
              end
              para "Login using your W3D Hub forum account", width: 1.0, text_align: :center

              flow(width: 1.0) do
                tagline "Username", width: 0.25, text_align: :right
                @username = edit_line "", width: 0.75, focus: true
              end

              flow(width: 1.0) do
                tagline "Password", width: 0.25, text_align: :right
                @password = edit_line "", width: 0.75, type: :password
              end

              flow(width: 1.0) do
                tagline "", width: 0.25
                button "Log In" do |btn|
                  @username.enabled = false
                  @password.enabled = false
                  btn.enabled = false

                  # Todo lock whole UI until response or timeout

                  # Do network stuff

                  Thread.new do
                    account = Api.user_login(@username.value, @password.value)

                    if account
                      window.account = account
                      window.settings[:account][:refresh_token] = account.refresh_token
                      window.settings.save_settings

                      Cache.fetch(account.avatar_uri)

                      main_thread_queue << proc { populate_account_info; page(W3DHub::Pages::Games) }
                    else
                      # An error occurred, enable  account entry
                      # NOTE: Too many incorrect entries causes lock out (Unknown duration)
                      main_thread_queue << proc do
                        @username.enabled = true
                        @password.enabled = true
                        btn.enabled = true

                        @error_label.value = "Incorrect username or password.\nOr too many failed login attempts."
                      end
                    end
                  end
                end

                @error_label = caption "", width: 1.0, text_align: :center, color: 0xff_800000
              end
            end
          end
        end

        if window.account
          populate_account_info
          page(W3DHub::Pages::Games)
        end
      end

      def populate_account_info
        @host.instance_variable_get(:"@account_container").clear do
          stack(width: 0.7, height: 1.0) do
            # background 0xff_222222
            tagline "<b>#{window.account.username}</b>"

            flow(width: 1.0) do
              link(I18n.t(:"interface.log_out"), text_size: 16, width: 0.5) { depopulate_account_info }
              link I18n.t(:"interface.profile"), text_size: 16, width: 0.49 do
                Launchy.open("https://secure.w3dhub.com/forum/index.php?showuser=#{window.account.id}")
              end
            end
          end

          image Cache.path(window.account.avatar_uri), height: 1.0
        end
      end

      def depopulate_account_info
        window.settings[:account][:refresh_token] = nil
        window.settings.save_settings

        @host.instance_variable_get(:"@account_container").clear do
          stack(width: 0.7, height: 1.0) do
            # background 0xff_222222
            tagline "<b>#{I18n.t(:"interface.not_logged_in")}</b>", text_wrap: :none

            flow(width: 1.0) do
              link(I18n.t(:"interface.log_in"), text_size: 16, width: 0.5) { page(W3DHub::Pages::Login) }
              link I18n.t(:"interface.register"), text_size: 16, width: 0.49 do
                Launchy.open("https://secure.w3dhub.com/forum/index.php?app=core&module=global&section=register")
              end
            end
          end
        end
      end
    end
  end
end
