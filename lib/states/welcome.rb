class W3DHub
  class States
    class Welcome < CyberarmEngine::GuiState
      def setup
        window.show_cursor = true

        theme(W3DHub::THEME)
        background 0x88_252525


        flow(width: 1.0, height: 1.0) do
          flow(fill: true)

          @card_container = stack(width: 1.0, max_width: MAX_PAGE_WIDTH, height: 1.0, max_height: 720, margin: 128, padding: 16) do
            background 0xff_252525
          end

          flow(fill: true)
        end

        @card_container.clear do
          card_welcome
        end
      end

      def card_welcome
        stack(width: 1.0, fill: true) do
          banner "Welcome", width: 1.0, border_thickness_bottom: 4, border_color_bottom: 0xff_000000
          title "Welcome to the #{I18n.t(:app_name_simple)}"
          caption "The #{I18n.t(:app_name_simple)} is a one-stop shop for your W3D gaming needs, providing game downloads, automatic updating, an integrated server browser, and centralized management of in-game options.", width: 1.0, margin_left: 32
        end

        flow(width: 1.0, height: 40) do
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
          banner "Getting Started", width: 1.0, border_thickness_bottom: 4, border_color_bottom: 0xff_000000
          title "Import C&C Renegade"
          caption "You can import your installed copy of Renegade if it wasn't automatically imported from the Games tab. If you need to procure a copy of Renegade, EA's Origin Store has the Command & Conquer The Ultimate Collection available. We cannot provide Renegade for installation.", width: 1.0, margin_left: 32

          stack(width: 1.0, height: 2, background: 0x88_ffffff)

          title "Install one of our standalone games"
          caption "Browse our selection of games from the left panel of the Games tab.\n• Interim Apex - Renegade but with hundreds of vehicles and characters.\n• Red Alert: A Path Beyond - DESCRIPTION\n• Tiberian Sun: Reborn - DESCRIPTION\n\nAnd more... Check out the left panel on the Games tab.", width: 1.0, margin_left: 32
        end

        flow(width: 1.0, height: 40) do
          flow(fill: true, height: 1.0) do
            button "< Back" do
              @card_container.clear { card_welcome }
            end

            link "Skip", border_color_bottom: 0xff_777777, margin_left: 16 do
              pop_state
            end
          end

          button "Next >" do
            @card_container.clear { card_communitiy }
          end
        end
      end

      def card_communitiy
        stack(width: 1.0, fill: true) do
          banner "W3D Hub Community", width: 1.0, border_thickness_bottom: 4, border_color_bottom: 0xff_000000
          title "Forums"
          caption "Join our forum community", margin_left: 32

          title "Facebook"
          caption "Like us on Facebook", margin_left: 32

          title "Discord"
          caption "Join our Discord community server", margin_left: 32

          title "YouTube"
          caption "Subscribe to our YouTube channel", margin_left: 32
        end

        flow(width: 1.0, height: 40) do
          flow(fill: true, height: 1.0) do
            button "< Back" do
              @card_container.clear { card_getting_started }
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
