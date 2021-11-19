class W3DHub
  class Pages
    class Community < Page
      def setup
        body.clear do
          stack(width: 1.0, height: 1.0, padding: 8) do
            stack(width: 1.0, height: 0.15) do
              tagline "<b>Welcome to the #{W3DHub::NAME}</b>"
              para "The #{W3DHub::NAME} is a one-stop shop for your W3D gaming needs, providing game downloads, automatic updating, an integrated server browser, and centralized management of in-game options."
            end

            flow(width: 1.0, height: 0.15, margin_bottom: 24) do
              flow(width: (1.0 - 0.27) / 2, height: 1.0) do
              end

              flow(width: 0.27, height: 1.0) do
                image "#{GAME_ROOT_PATH}/media/icons/w3dhub.png", height: 1.0, hover: { color: 0xaa_ffffff }, tip: "W3D Hub Forums" do
                  Launchy.open("https://w3dhub.com/forum/")
                end
                image "#{GAME_ROOT_PATH}/media/social_media_icons/discord.png", hover: { color: 0xaa_ffffff }, height: 1.0, margin_left: 32, tip: "W3D Hub Discord Server" do
                  Launchy.open("https://discord.com/invite/GYhW7eV")
                end
                image "#{GAME_ROOT_PATH}/media/social_media_icons/facebook.png", hover: { color: 0xaa_ffffff }, height: 1.0, margin_left: 32, tip: "W3D Hub Facebook Page" do
                  Launchy.open("https://www.facebook.com/w3dhub")
                end
              end
            end

            stack(width: 1.0, height: 0.55, scroll: true) do
              tagline "<b>Latest Updates</b>"
              para "Hello World " * 100
            end

            stack(width: 1.0, height: 0.15, margin_top: 16) do
              tagline "<b>Help & Support</b>"
              flow(width: 1.0) do
                para "For help and support using this launcher or playing any W3D Hub game visit the"
                link("W3D Hub forums", text_size: 16) { Launchy.open("https://w3dhub.com/forum/") }
                para "or join us in"
                image "#{GAME_ROOT_PATH}/media/social_media_icons/discord.png", height: 16, padding_top: 4
                link("#tech-support", text_size: 16) { Launchy.open("https://discord.com/invite/GYhW7eV") }
                para "on the W3D Hub Discord server"
              end
            end
          end
        end
      end
    end
  end
end
