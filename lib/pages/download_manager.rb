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

            # Operations
            stack(width: 1.0, height: 0.9, padding: 8, scroll: true) do
              window.applications.games.reject { |g| g.id == "ren" }.each_with_index do |game, i|
                stack(width: 1.0, height: 24, padding: 8) do
                  background 0xff_333333 if i.odd?

                  flow(width: 1.0, height: 22) do
                    inscription game.name, width: 0.7, text_wrap: :none
                    inscription "Pending...", width: 0.3, text_align: :right, text_wrap: :none
                  end

                  progress fraction: rand(0.25..0.8), height: 2, width: 1.0
                end
              end
            end
          end
        end
      end
    end
  end
end
