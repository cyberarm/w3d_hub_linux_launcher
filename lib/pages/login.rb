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
                    sleep 0.2

                    main_thread_queue << proc { populate_account_info; page(W3DHub::Pages::Games) }
                  end
                end
              end
            end
          end
        end
      end

      def populate_account_info
        @host.instance_variable_get(:"@account_container").clear do
          stack(width: 0.7, height: 1.0) do
            # background 0xff_222222
            tagline "<b>#{@username.value}</b>"

            flow(width: 1.0) do
              link("Logout", text_size: 16) { depopulate_account_info }
              link "Profile", text_size: 16
            end
          end

          image "#{GAME_ROOT_PATH}/media/ui_icons/singleplayer.png", height: 1.0
        end
      end

      def depopulate_account_info
        @host.instance_variable_get(:"@account_container").clear do
          stack(width: 0.7, height: 1.0) do
            # background 0xff_222222
            tagline "<b>Not Logged In</b>", text_wrap: :none

            flow(width: 1.0) do
              link("Log in", text_size: 16) { page(W3DHub::Pages::Login) }
              link "Register", text_size: 16
            end
          end
        end
      end
    end
  end
end
