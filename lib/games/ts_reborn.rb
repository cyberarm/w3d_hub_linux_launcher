class W3DHub
  class Games
    class TSReborn < Game
      def setup
        set_name "Tiberian Sun: Reborn"
        set_icon "#{GAME_ROOT_PATH}/media/icons/tsr.png"
        set_news_feed "https://w3dhub.com/forum/forum/97-tiberian-sun-reborn.xml"
        set_background_color 0xff_497331

        menu_item("#{GAME_ROOT_PATH}/media/ui_icons/gear.png", "Game Settings")
        menu_item("#{GAME_ROOT_PATH}/media/ui_icons/wrench.png", "Repair Installation")
        menu_item("#{GAME_ROOT_PATH}/media/ui_icons/trashCan.png", "Uninstall")

        menu_item(nil, "Install Folder")
        menu_item(nil, "User Data Folder")
        menu_item(nil, "View Screenshots")
        menu_item(nil, "Discord")
        menu_item(nil, "Modifications")

        play_item("Play Game")
        play_item("Single Player")

        set_slot(4)
      end
    end
  end
end
