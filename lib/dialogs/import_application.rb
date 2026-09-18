module W3DHubLauncher
  class Dialog
    class ImportApplication < W3DHubLauncher::Dialog
      def setup
        super

        @application = @options[:application]
        @channel = @options[:channel]

        stack(width: 1.0, max_width: 600, height: 1.0, max_height: 600, h_align: :center, v_align: :center, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0xee_63452c) do
          flow(width: 1.0, background_nine_slice: NINE_SLICE_ROUNDED_TOP, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0) do
            banner "Import Application", width: 1.0, text_align: :center
          end

          stack(width: 1.0, fill: true, scroll: true, margin_left: PADDING, margin_right: PADDING, padding: HALF_PADDING, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: ALPHA_BLACK) do
            title format("%s (%s)", @application.name, @channel.name)
            caption "Path to application executable:"
            @path_input = edit_line "", width: 1.0
            button "Browse..." do
              Gosu.choose_file do |file_list|
                pp file_list

                unless file_list.empty?
                  @path_input.value = file_list.first
                end
              end
            end

            @path_input.subscribe(:changed) do |e, value|
              found = false

              if File.directory?(File.dirname(value))
                Dir.glob("#{File.dirname(value)}/game*.exe").each do |file|
                  if File.exist?(file)
                    found = true

                    break
                  end
                end
              end

              @import_button.enabled = found
            end
          end

          flow(width: 1.0, padding: PADDING, background_nine_slice: NINE_SLICE_ROUNDED_BOTTOM, background_nine_slice_from_edge: NINE_SLICE_EDGE, background_nine_slice_color: 0) do
            button "Close" do
              pop_state
            end

            flow(fill: true)

            @import_button = button "Import", enabled: false, **CTA_BUTTON_THEME do
              pop_state

              app = Worker::Api::Settings::Application.create(
                id: @application.id,
                channel: @channel.id,
                version: @channel.version,
                installation_path: File.dirname(@path_input.value),
                wine_prefix_path: "",
                launch_command: "%COMMAND%",
                timestamp: Time.now.to_i
              )

              MemCache[:settings].applications << app

              Worker::Api.update_settings(MemCache[:settings])

              # FIXME: broadcast app installed on CyberarmEngine::EventBus
            end
          end
        end
      end
    end
  end
end
