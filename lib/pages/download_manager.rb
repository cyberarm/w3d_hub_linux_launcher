class W3DHub
  class Pages
    class DownloadManager < Page
      def setup
        body.clear do
          stack(width: 1.0, height: 1.0) do
            flow(width: 1.0, height: 0.1, padding: 8) do
              background 0xff_252550
              flow(width: 0.70, height: 1.0) do
                image "#{GAME_ROOT_PATH}/media/icons/apb.png", height: 1.0
                stack(margin_left: 8) do
                  tagline "Red Alert: A Path Beyond"
                  inscription "Version: 0.3.23 (release)"
                end
              end

              flow(width: 0.30, height: 1.0) do
                stack(width: 0.499, height: 1.0) do
                  para "Download Speed", width: 1.0, text_align: :center
                  inscription "10 MB/s", width: 1.0, text_align: :center
                end

                stack(width: 0.5, height: 1.0) do
                  para "Downloaded", width: 1.0, text_align: :center
                  inscription "325.8 MB / 1.39 GB", width: 1.0, text_align: :center
                end
              end
            end

            # UPDATES
            stack(width: 1.0, height: 0.1) do
              background 0x44_000000
              inscription "Something something updates...", width: 1.0, text_align: :center, margin_top: 18
            end

            # Available to download
            stack(width: 1.0, height: 0.8, padding: 8, scroll: true) do
              window.applications.games.reject { |g| g.id == "ren" }.each_with_index do |game, i|
                flow(width: 1.0, height: 64, padding: 8) do
                  background 0xff_333333 if i.odd?

                  flow(width: 0.7, height: 1.0) do
                    image "#{GAME_ROOT_PATH}/media/icons/#{game.id}.png", width: 0.1, margin_right: 8

                    stack(width: 0.9, height: 1.0) do
                      title game.name
                      inscription "This is a brief description of the game", width: 1.0
                    end
                  end

                  flow(width: 0.3, height: 1.0) do
                    version_selector = list_box items: game.channels.map { |c| c.name }, width: 0.499, enabled: game.channels.count > 1
                    version_selector.subscribe(:changed) do |item|
                      p item.value
                    end

                    button "Install", width: 0.5 do
                      # Download/verify game-channel manifest
                      # Download broken/missing files
                      # Unpack
                      # Configure
                      # Disable install
                      # Enable Uninstall

                      get
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
