class W3DHub
  class Games
    class CNCRenegade < Game
      def setup
        set_name "C&C Renegade"
        set_icon "#{GAME_ROOT_PATH}/media/icons/ren.png"
        set_news_feed "https://w3dhub.com/forum/forum/231-command-and-conquer-renegade.xml"
        set_background_color 0xff_b03f25

        menu_item(nil, "Game Settings")

        menu_item(nil, "Install Folder")
        menu_item(nil, "View Screenshots")
        menu_item(nil, "> GET SCRIPTS 4.7 <")
        menu_item(nil, "Renegade News")

        play_item("Play Game")
        play_item("Single Player")

        set_slot(0)
      end
    end
  end
end
