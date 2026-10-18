module W3DHubLauncher
  class Dialog
    class Account < W3DHubLauncher::Dialog
      def setup
        super

        stack(width: 1.0, max_width: 600, height: 1.0, max_height: 600, style_class: [:dialog]) do
          flow(width: 1.0, background_nine_slice: NINE_SLICE_ROUNDED_TOP, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0) do
            banner "Account", width: 1.0, text_align: :center
          end

          stack(style_class: [:dialog_container]) do
            title "Sign in with your W3D Hub forum account", margin_bottom: PADDING

            tagline "Username"
            @username = edit_line "", width: 1.0

            tagline "Password"
            @password = edit_line "", type: :password, width: 1.0

            flow(width: 1.0, margin_top: LARGE_PADDING, margin_bottom: LARGE_PADDING) do
              flow(fill: true, height: 2, v_align: :center, background: 0xff_000000)

              tagline "OR", margin_left: HALF_PADDING, margin_right: HALF_PADDING

              flow(fill: true, height: 2, v_align: :center, background: 0xff_000000)
            end

            tagline "Sign in with access token"
            flow(width: 1.0) do
              edit_line "", fill: true, enabled: false
              button "Get token", tip: "https://sso.w3d.cyberarm.dev/account/token", enabled: false
            end
          end

          flow(width: 1.0, padding: PADDING, background_nine_slice: NINE_SLICE_ROUNDED_BOTTOM, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0) do
            button "Cancel" do
              pop_state
            end

            flow(fill: true)

            button "Register", tip: "https://w3dhub.com/forum/register/" do
              SDL.OpenURL("https://w3dhub.com/forum/register/")
            end

            flow(fill: true)

            button "Sign In", **CTA_BUTTON_THEME do |btn|
              # use SSO service, eventually. , tip: "https://sso.w3d.cyberarm.dev"

              btn.enabled = false

              Worker::Api.user_login(@username.value, @password.value) do |result|
                if result.okay?
                  hash = JSON.parse(result.data)

                  MemCache[:settings].account = W3DHubLauncher::Worker::Api::Settings::Account.create(
                    user_id: hash["userid"],
                    username: hash["username"],
                    displayname: hash["displayname"],
                    avatar_uri: "",
                    access_token: hash["accessToken"],
                    refresh_token: hash["refreshToken"],
                    access_token_expiration_time: hash["accessTokenExpiry"]
                  )

                  Worker::Api.update_settings(MemCache[:settings]) do |settings_result|
                    if settings_result.okay?
                      on_main_thread(-> {
                        pop_state
                        window.current_state&.populate_account_information
                      })
                    end

                    # FIXME: Retry? Show error? ???
                    pp settings_result
                  end
                end

                # FIXME: Show error message!
                pp result
              end
            end
          end
        end
      end
    end
  end
end
