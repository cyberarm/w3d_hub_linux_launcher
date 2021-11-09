class W3DHub
  class Games
    class InterimApex < Game
      def setup
        set_name "Interim Apex"
        set_icon "#{GAME_ROOT_PATH}/media/icons/ia.png"
        set_news_feed "https://w3dhub.com/forum/forum/209-interim-apex.xml"
        set_background_color 0xff_034866

        menu_item("#{GAME_ROOT_PATH}/media/ui_icons/gear.png", "Game Settings")
        menu_item("#{GAME_ROOT_PATH}/media/ui_icons/wrench.png", "Repair Installation")
        menu_item("#{GAME_ROOT_PATH}/media/ui_icons/trashCan.png", "Uninstall")

        menu_item(nil, "Install Folder")
        menu_item(nil, "User Data Folder")
        menu_item(nil, "View Screenshots")

        play_item("Play Game")
        play_item("Single Player")

        set_slot(2)
      end
    end
  end
end
