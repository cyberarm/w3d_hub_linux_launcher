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
                @username = edit_line "", width: 0.75, autofocus: true, focus: true
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

                  Async do
                    internet = Async::HTTP::Internet.instance

                    account = Api.user_login(internet, @username.value, @password.value)

                    if account
                      Store.account = account
                      Store.settings[:account][:refresh_token] = account.refresh_token
                      Store.settings.save_settings

                      Cache.fetch(internet, account.avatar_uri)

                      populate_account_info
                      page(W3DHub::Pages::Games)
                    else
                      # An error occurred, enable account entry
                      # NOTE: Too many incorrect entries causes lock out (Unknown duration)
                      @username.enabled = true
                      @password.enabled = true
                      btn.enabled = true

                      @error_label.value = "Incorrect username or password.\nOr too many failed login attempts, try again in a few minutes."
                    end
                  end
                end

                @error_label = caption "", width: 1.0, text_align: :center, color: 0xff_800000
              end
            end
          end
        end

        if Store.account
          Async do
            internet = Async::HTTP::Internet.instance
            Cache.fetch(internet, Store.account.avatar_uri)

            populate_account_info
            page(W3DHub::Pages::Games)
          end
        end
      end

      def populate_account_info
        @host.instance_variable_get(:"@account_container").clear do
          stack(width: 0.7, height: 1.0) do
            # background 0xff_222222
            tagline "<b>#{Store.account.username}</b>"

            flow(width: 1.0) do
              link(I18n.t(:"interface.log_out"), text_size: 16, width: 0.5) { depopulate_account_info }
              link I18n.t(:"interface.profile"), text_size: 16, width: 0.49 do
                Launchy.open("https://secure.w3dhub.com/forum/index.php?showuser=#{Store.account.id}")
              end
            end
          end

          image Cache.path(Store.account.avatar_uri), height: 1.0
        end
      end

      def depopulate_account_info
        Store.settings[:account][:refresh_token] = nil
        Store.settings.save_settings
        Store.account = nil

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
