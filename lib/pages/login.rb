class W3DHub
  class Pages
    class Login < Page
      def setup
        body.clear do
          flow(width: 1.0, height: 1.0, padding: 32) do
            background 0xaa_25253f

            stack(width: 610, height: 380, v_align: :center, h_align: :center) do
              flow(width: 1.0) do
                stack(width: 0.4)
                image "#{GAME_ROOT_PATH}/media/icons/w3dhub.png", width: 0.20
              end
              para "Login using your W3D Hub forum account", width: 1.0, text_align: :center

              flow(width: 1.0) do
                tagline "Username", width: 0.25, text_align: :right
                @username = edit_line "", width: 0.75, autofocus: true, focus: true
              end

              flow(width: 1.0, margin_top: 8) do
                tagline "Password", width: 0.25, text_align: :right
                @password = edit_line "", width: 0.75, type: :password
              end

              flow(width: 1.0) do
                tagline "", width: 0.25
                @action_button = button "Log In" do |btn|
                  @username.enabled = false
                  @password.enabled = false
                  btn.enabled = false

                  # TODO: lock whole UI until response or timeout

                  # Do network stuff

                  BackgroundWorker.foreground_job(
                    lambda do
                      account = Api.user_login(@username.value, @password.value)
                      applications = nil

                      if account
                        Store.account = account
                        Store.settings[:account][:data] = account
                        Store.settings.save_settings

                        if account
                          Cache.fetch(uri: account.avatar_uri, force_fetch: true, async: false, backend: :w3dhub)
                          applications = Api._applications
                        end
                      end

                      [account, applications]
                    end,
                    lambda do |result|
                      account, applications = result

                      if account
                        populate_account_info
                        Store.applications = applications if applications

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
                  )
                end

                @error_label = caption "", width: 1.0, text_align: :center, color: 0xff_800000
              end
            end
          end
        end

        if Store.account
          BackgroundWorker.foreground_job(
            -> { Cache.fetch(uri: Store.account.avatar_uri, async: false, backend: :w3dhub) },
            ->(result) {
              populate_account_info
              page(W3DHub::Pages::Games)
            }
          )
        end
      end

      def button_down(id)
        case id
        when Gosu::KB_TAB
          if @username.focused?
            window.current_state.request_focus(@password)
          else
            window.current_state.request_focus(@username)
          end
        when Gosu::KB_ENTER, Gosu::KB_RETURN
          @action_button.enabled? && @action_button.clicked_left_mouse_button(@action_button, 0, 0)
        end
      end

      def populate_account_info
        return if Store.offline_mode

        @host.instance_variable_get(:"@account_container").clear do
          flow(fill: true, height: 1.0) do
            avatar_image = begin
              get_image(Cache.path(Store.account.avatar_uri))
            rescue
              get_image("#{GAME_ROOT_PATH}/media/icons/default_icon.png")
            end
            mask_image = get_image("#{GAME_ROOT_PATH}/media/textures/circle_mask.png")

            composite_image = Gosu.render(256, 256) do
              scale = 1.0

              if avatar_image.width > avatar_image.height
                # avatar image is wider than tall, use `height` for scaling to ensure we fill the canvas
                scale = 256.0 / avatar_image.height
              elsif avatar_image.width < avatar_image.height
                # avatar image is taller than wide, use `width` for scaling to ensure we fill the canvas
                scale = 256.0 / avatar_image.width
              else
                # avatar image is square, use width for scale to ensure we fit to the canvas
                scale = 256.0 / avatar_image.width
              end

              # Position image center in middle of composite
              avatar_image.draw_rot(128, 128, 0, 0, 0.5, 0.5, scale, scale)
              # Render mask image with mode :multiply so we get a clean circle cutout of the scaled avatar image
              mask_image.draw(0, 0, 1, 1, 1, 0xff_ffffff, :multiply)
            end

            image composite_image, width: 1.0
          end

          stack(width: 0.7, height: 1.0, margin_left: 8) do
            link Store.account.username, text_size: 24, font: BOLD_FONT, tip: I18n.t(:"interface.profile"), margin_top: 16, width: 1.0, text_wrap: :none do
              W3DHub.url("https://secure.w3dhub.com/forum/index.php?showuser=#{Store.account.id}")
            end

            link(I18n.t(:"interface.log_out"), text_size: 22) { depopulate_account_info }
          end
        end
      end

      def depopulate_account_info
        Store.settings[:account] = {}
        Store.settings.save_settings
        Store.account = nil

        BackgroundWorker.foreground_job(
          -> { Api._applications },
          lambda do |applications|
            if applications
              Store.applications = applications
              page(W3DHub::Pages::Games) if @host.current_page.is_a?(W3DHub::Pages::Games)
              page(W3DHub::Pages::ServerBrowser) if @host.current_page.is_a?(W3DHub::Pages::ServerBrowser)
            end

            @host.instance_variable_get(:"@account_container").clear do
              stack(width: 1.0, height: 1.0) do
                tagline "<b>#{I18n.t(:"interface.not_logged_in")}</b>", text_wrap: :none

                flow(width: 1.0) do
                  link(I18n.t(:"interface.log_in"), text_size: 22, width: 0.5) { page(W3DHub::Pages::Login) }
                  link I18n.t(:"interface.register"), text_size: 22, width: 0.49 do
                    W3DHub.url("https://secure.w3dhub.com/forum/index.php?app=core&module=global&section=register")
                  end
                end
              end
            end
          end
        )
      end
    end
  end
end
