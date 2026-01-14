class W3DHub
  class States
    class Welcome < CyberarmEngine::GuiState
      def setup
        window.show_cursor = true

        theme(W3DHub::THEME)


        flow(width: 1.0, height: 1.0, background_image: "#{GAME_ROOT_PATH}/media/banners/background.png", background_image_color: 0xff_525252, background_image_mode: :fill) do
          flow(fill: true)

          @card_container = stack(width: 1.0, max_width: MAX_PAGE_WIDTH, height: 1.0, max_height: 720, margin: 64, v_align: :center, h_align: :center, padding: 16) do
            background 0xaa_353535
          end

          flow(fill: true)
        end

        @card_container.clear do
          card_welcome
        end
      end

      def card_welcome
        stack(width: 1.0, fill: true) do
          banner "Welcome", width: 1.0, border_thickness_bottom: 4, border_color_bottom: 0xff_0074e0
          title "Welcome to the #{I18n.t(:app_name_simple)}"
          caption "The #{I18n.t(:app_name_simple)} is a one-stop shop for your W3D gaming needs, providing game downloads, "\
                  "automatic updating, an integrated server browser, and centralized management of in-game options.", width: 1.0, margin_left: 32

          image "#{GAME_ROOT_PATH}/media/icons/app.png", height: 256
        end

        flow(width: 1.0, height: 46) do
          stack(fill: true, height: 1.0) do
            link "Skip", border_color_bottom: 0xff_777777 do
              pop_state
            end
          end

          button "Next >" do
            @card_container.clear { card_getting_started }
          end
        end
      end

      def card_getting_started
        stack(width: 1.0, fill: true) do
          banner "Getting Started", width: 1.0, border_thickness_bottom: 4, border_color_bottom: 0xff_0074e0
          title "Import Command & Conquer: Renegade"
          caption "You can import your installed copy of Renegade if it wasn't automatically imported from the Games tab.\n"\
                  "If you need to procure a copy of Renegade, Both Steam and the EA App have the Command & Conquer The Ultimate Collection available for purchase. "\
                  "We cannot provide Renegade for installation.", width: 1.0, margin_left: 32

          stack(width: 1.0, height: 2, background: 0xff_0074e0, margin_top: 16, margin_bottom: 16)

          title "Install one of our standalone games"
          stack(width: 1.0, fill: true, margin_left: 32) do
            tagline "Interim Apex"
            caption "An expanded boots on the ground conflict set after the advent of Tiberian Dawn and the inter-war period between Tiberian Dawn and Tiberian Sun.", margin_left: 16
            tagline "Red Alert 2: Apocalypse Rising"
            caption "A multiplayer first-and-third-person shooter set in the vibrant universe of Command & Conquer: Red Alert 2. ", margin_left: 16
            tagline "Tiberian Sun: Reborn"
            caption "A standalone first-person shooter set in the Tiberian Sun universe.", margin_left: 16
            para ""
            caption "And more games! See them all on the Games tab."
          end
        end

        flow(width: 1.0, height: 46) do
          flow(fill: true, height: 1.0) do
            button "< Back" do
              @card_container.clear { card_welcome }
            end

            link "Skip", border_color_bottom: 0xff_777777, margin_left: 16 do
              pop_state
            end
          end

          button "Next >" do
            @card_container.clear { W3DHub.unix? ? card_wine : card_community }
          end
        end
      end

      def card_wine
        stack(width: 1.0, fill: true) do
          banner "Wine - Windows compatibility layer", width: 1.0, border_thickness_bottom: 4, border_color_bottom: 0xff_0074e0
          stack(width: 1.0, fill: true, margin_left: 32) do
            title "Got Wine?"
            caption "The launcher requires a windows compatibility tool like wine in order to run the games.", margin_left: 32
            caption "Install wine and winetricks through your distribution's package manager or use a wine manager like Bottles.", margin_left: 32
            link "See most up to date instructions on the wiki.", tip: "https://github.com/cyberarm/w3d_hub_linux_launcher/wiki/Getting-Started-With-Wine", margin_top: 16, margin_left: 32, border_color_bottom: 0xff_777777 do
              W3DHub.url("https://github.com/cyberarm/w3d_hub_linux_launcher/wiki/Getting-Started-With-Wine")
            end
          end
        end

        flow(width: 1.0, height: 46) do
          flow(fill: true, height: 1.0) do
            button "< Back" do
              @card_container.clear { card_getting_started }
            end

            link "Skip", border_color_bottom: 0xff_777777, margin_left: 16 do
              pop_state
            end
          end

          button "Next >" do
            @card_container.clear { card_community }
          end
        end
      end

      def card_community
        stack(width: 1.0, fill: true) do
          banner "W3D Hub Community", width: 1.0, border_thickness_bottom: 4, border_color_bottom: 0xff_0074e0
          title "W3D Hub"
          link "Visit website", tip: "https://w3dhub.com", margin_left: 32, border_color_bottom: 0xff_777777 do
            W3DHub.url("https://w3dhub.com")
          end

          title "Forum"
          link "Join our forum community", tip: "https://w3dhub.com/forum", margin_left: 32, border_color_bottom: 0xff_777777 do
            W3DHub.url("https://w3dhub.com/forum")
          end

          title "Facebook"
          link "Like us on Facebook", tip: "https://www.facebook.com/w3dhub/", margin_left: 32, border_color_bottom: 0xff_777777 do
            W3DHub.url("https://www.facebook.com/w3dhub/")
          end

          title "Discord"
          link "Join our Discord community server", tip: "https://discord.gg/jMmmRa2", margin_left: 32, border_color_bottom: 0xff_777777 do
            W3DHub.url("https://discord.gg/jMmmRa2")
          end

          title "YouTube"
          link "Subscribe to our YouTube channel", tip: "https://www.youtube.com/@w3dhub-official", margin_left: 32, border_color_bottom: 0xff_777777 do
            W3DHub.url("https://www.youtube.com/@w3dhub-official")
          end
        end

        flow(width: 1.0, height: 46) do
          flow(fill: true, height: 1.0) do
            button "< Back" do
              @card_container.clear { W3DHub.unix? ? card_wine : card_getting_started }
            end
          end

          button "Done" do
            pop_state
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
