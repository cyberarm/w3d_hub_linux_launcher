class W3DHub
  class Games
    class APathBeyond < Game
      def setup
        set_name "Red Alert: A Path Beyond"
        set_icon "#{GAME_ROOT_PATH}/media/icons/apb.png"
        set_news_feed "https://w3dhub.com/forum/forum/201-red-alert-a-path-beyond.xml"
        set_background_color 0xff_353535

        menu_item("#{GAME_ROOT_PATH}/media/ui_icons/gear.png", "Game Settings")
        menu_item("#{GAME_ROOT_PATH}/media/ui_icons/wrench.png", "Repair Installation")
        menu_item("#{GAME_ROOT_PATH}/media/ui_icons/trashCan.png", "Uninstall")

        menu_item(nil, "Install Folder")
        menu_item(nil, "User Data Folder")
        menu_item(nil, "View Screenshots")
        menu_item(nil, "Modifications")
        menu_item(nil, "Bug Tracker")
        menu_item(nil, "Player Statistics")

        play_item("Play Game")
        play_item("Single Player")

        set_slot(3)
      end
    end
  end
end
