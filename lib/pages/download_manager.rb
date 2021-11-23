class W3DHub
  class Pages
    class DownloadManager < Page
      attr_reader :download_package_info

      def setup
        @download_package_info ||= {}
        @task = Store.application_manager.current_task

        return unless @task

        body.clear do
          stack(width: 1.0, height: 1.0) do
            # TODO: Show correct application details here
            flow(width: 1.0, height: 0.1, padding: 8) do
              background @task.application.color

              flow(width: 0.70, height: 1.0) do
                image "#{GAME_ROOT_PATH}/media/icons/#{@task.app_id}.png", height: 1.0

                stack(margin_left: 8) do
                  $bug_1 = tagline "#{@task.application.name}"
                  $bug_2 = inscription "Version: #{@task.channel.current_version} (#{@task.channel.id})"
                end
              end

              puts "OKAY"

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
            @downloads_container = stack(width: 1.0, height: 0.9, padding: 8, scroll: true) do
              # TODO: Show actual list of downloads

              @task&.packages_to_download&.each_with_index do |pkg, i|
                stack(width: 1.0, height: 24, padding: 8) do
                  background 0xff_333333 if i.odd?

                  flow(width: 1.0, height: 22) do
                    @download_package_info["#{pkg.checksum}_name"] = inscription pkg.name, width: 0.7, text_wrap: :none, tag: "#{pkg.checksum}_name"
                    @download_package_info["#{pkg.checksum}_status"] = inscription "Pending...", width: 0.3, text_align: :right, text_wrap: :none, tag: "#{pkg.checksum}_status"
                  end

                  @download_package_info["#{pkg.checksum}_progress"] = progress fraction: 0.0, height: 2, width: 1.0, tag: "#{pkg.checksum}_progress"
                end
              end
            end
          end
        end
      end
    end
  end
end
