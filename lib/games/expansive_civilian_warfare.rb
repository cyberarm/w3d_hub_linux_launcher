class W3DHub
  class Games
    class ExpansiveCivilianWarfare < Game
      def setup
        set_name "Expansive Civilian Warfare"
        set_icon "#{GAME_ROOT_PATH}/media/icons/ecw.png"
        set_news_feed "https://w3dhub.com/forum/forum/208-expansive-civilian-warfare.xml"
        set_background_color 0xff_3e5c87

        menu_item("#{GAME_ROOT_PATH}/media/ui_icons/gear.png", "Game Settings")
        menu_item("#{GAME_ROOT_PATH}/media/ui_icons/wrench.png", "Repair Installation")
        menu_item("#{GAME_ROOT_PATH}/media/ui_icons/trashCan.png", "Uninstall")

        menu_item(nil, "Install Folder")
        menu_item(nil, "User Data Folder")
        menu_item(nil, "View Screenshots")
        menu_item(nil, "Player Statistics")

        play_item("Play Game")
        play_item("Single Player")

        set_slot(1)
      end
    end
  end
end
