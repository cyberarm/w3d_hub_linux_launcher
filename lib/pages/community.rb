class W3DHub
  class Pages
    class Community < Page
      def setup
        body.clear do
          stack(width: 1.0, height: 1.0, padding: 8) do
            stack(width: 1.0, height: 0.15) do
              tagline "<b>Welcome to the W3D Hub Launcher</b>"
              para "The W3D Hub launcher is a one-stop shop for your W3D gamings needs, providing game downloads and automatic updating, an intregrated server browser, centralized management of in-game options and many other features."
            end

            flow(width: 1.0, height: 0.1, margin_top: 24) do
              flow(width: 0.375, height: 1.0) do
              end

              flow(width: 0.25, height: 1.0) do
                image "#{GAME_ROOT_PATH}/media/icons/apb.png", height: 1.0
                image "#{GAME_ROOT_PATH}/media/icons/ren.png", height: 1.0, margin_left: 32
                image "#{GAME_ROOT_PATH}/media/icons/tsr.png", height: 1.0, margin_left: 32
                image "#{GAME_ROOT_PATH}/media/icons/w3dhub.png", height: 1.0, margin_left: 32
              end

              flow(width: 0.375, height: 1.0) do
              end
            end

            stack(width: 1.0, height: 0.6, scroll: true) do
              tagline "<b>Latest Updates</b>"
              para "<b>Beta 12</b>", margin_left: 16
              para "- Server Browser: Added detailed information for selection server", margin_left: 32

              para "<b>Beta 11.6</b>", margin_left: 16, margin_top: 16
              para "- Localisation: Added Korean translations (unknown author)", margin_left: 32
              para "- Localisation: Added Spanish translations (thanks to Silverlight and URKA)", margin_left: 32
              para "- Localisation: Added Spanish translations (thanks to darkyuri-cz)", margin_left: 32

              para "<b>Beta 11.0</b>", margin_left: 16, margin_top: 16
              para "- Localisation: Added partial Chinese (Simplified) translations and Polish (thanks to DoDoCat and TrollekPL on the W3D Hub forums for providing translations)", margin_left: 32
              para "- Performance: Reduced CPU and GPU usage during game installs and updates", margin_left: 32
              para "- Settings: Added new setting menu for the launcher - click on the [gear] icon in the titlebar. Incluudes:", margin_left: 32
              para "- Manually choose language, rather than using default based on OS", margin_left: 48
              para "- Choose package cache folder location", margin_left: 48
              para "- Choose default folder into which games are installed", margin_left: 48
              para "- Server Browser: Now receives push notifications so it shows changes to maps, player counts, etc. as soon as they are available", margin_left: 32
              para "- Server Browser: Now lists servers with players in above empty ones", margin_left: 32
              para "- Server Browser: Game filter options are now saved", margin_left: 32
            end

            stack(width: 1.0, height: 0.15) do
              tagline "<b>Help & Support</b>"
              flow(width: 1.0) do
                para "For help and support using this launcher or playing any W3D Hub game visit the"
                link("W3D Hub forums", text_size: 16) { Launchy.open("https://w3dhub.com/forum/") }
                para "or join us in"
                link("[discord]#tech-support", text_size: 16) { Launchy.open("https://w3dhub.com/forum/") }
                para "on the W3D Hub Discord server"
              end
            end
          end
        end
      end
    end
  end
end
