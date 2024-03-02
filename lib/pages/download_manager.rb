class W3DHub
  class Pages
    class DownloadManager < Page
      attr_reader :operation_info

      def setup
        @operation_info ||= {}
        task = Store.application_manager.current_task

        unless task
          body.clear do
            stack(width: 1.0, height: 1.0) do
              background 0xaa_252525

              tagline "No operations pending.", width: 1.0, text_align: :center, margin: 128
            end
          end

          return
        end

        regenerate(task)
      end

      def regenerate(task)
        @operation_info[:___step] = task.status.step

        body.clear do
          stack(width: 1.0, height: 1.0) do
            background 0xaa_252525

            # TODO: Show correct application details here
            flow(width: 1.0, height: 0.1, padding: 8) do
              app_color = Gosu::Color.new(task.application.color)
              app_color.alpha = 0x88
              background app_color

              flow(width: 0.70, height: 1.0) do
                image_path = File.exist?("#{GAME_ROOT_PATH}/media/icons/#{task.app_id}.png") ? "#{GAME_ROOT_PATH}/media/icons/#{task.app_id}.png" : "#{GAME_ROOT_PATH}/media/icons/default_icon.png"
                @application_image = image image_path, height: 1.0

                stack(margin_left: 8, width: 0.75) do
                  @application_name_label = tagline "#{task.application.name}"
                  @application_version_label = para "Version: #{task.target_version} (#{task.channel.id})"
                end
              end

              flow(width: 0.30, height: 1.0) do
                stack(width: 0.499, height: 1.0) do
                  para "Download Speed", width: 1.0, text_align: :center
                  @download_speed_label = para "- b/s", width: 1.0, text_align: :center
                end

                stack(width: 0.5, height: 1.0) do
                  para "Downloaded", width: 1.0, text_align: :center
                  para "---- b / ---- b", width: 1.0, text_align: :center
                end
              end
            end

            # Operations
            @operations_container = stack(width: 1.0, height: 0.9, padding: 8, scroll: true) do
              # TODO: Show actual list of downloads

              i = -1
              task.status.operations.each do |key, operation|
                i += 1

                stack(width: 1.0, height: 26, padding: 8) do
                  background 0xaa_333333 if i.odd?

                  flow(width: 1.0, height: 22) do
                    @operation_info["#{key}_name"] = para operation.label, width: 0.7, text_wrap: :none, tag: "#{key}_name"
                    @operation_info["#{key}_status"] = para operation.value, width: 0.3, text_align: :right, text_wrap: :none, tag: "#{key}_status"
                  end

                  @operation_info["#{key}_progress"] = progress fraction: operation.progress, height: 2, width: 1.0, margin_top: 2, tag: "#{key}_progress"
                end
              end
            end
          end
        end
      end
    end
  end
end
