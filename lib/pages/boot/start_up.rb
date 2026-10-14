module W3DHubLauncher
  module Page
    module Boot
      class StartUp < CyberarmEngine::Page
        include GuiExt

        def setup
          @steps = [
            method(:step_connectivity),
            method(:step_launcher_update),
            method(:step_server_list),
            method(:step_refresh_account_data),
            method(:step_fetch_applications),
            method(:step_battlefield_control_established)
          ]
          @initialization_acceptable = false
          @step_count = @steps.size

          stack(width: 1.0, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: 8, background_nine_slice_color: 0x11_ffffff, padding: HALF_PADDING) do
            banner "Establishing Battlefield Control", width: 1.0, text_align: :center
            tagline "Please stand by...", width: 1.0, text_align: :center
          end

          stack(width: 1.0, fill: true, padding: PADDING) do
            @initialization_container = stack(width: 1.0, fill: true, scroll: true) do
            end

            flow(width: 1.0, padding_top: PADDING) do
              @progress_bar = progress width: 1.0, fraction: 0.0
            end
          end

          # FIXME: Ask worker to start websocket connections...
          # WORKER.connect

          next_step
        end

        def next_step
          step = @steps.shift
          step&.call

          # pp (1.0 - (@steps.size / @step_count.to_f)), @steps.size, @step_count
          @progress_bar.value = (1.0 - (@steps.size / @step_count.to_f))


          if step.nil? && @initialization_acceptable
            after(100) do
              pop_state
              push_state(States::Interface)
            end
          end
        end

        def step_connectivity
          @initialization_container.append do
            tagline "Checking uplink..."
            # caption "Primary backend services <c=080>OK</c>", margin_left: LARGE_PADDING
            # caption "Upstream backend services <c=080>OK</c>", margin_left: LARGE_PADDING
          end

          Worker::Api.dns_resolution do |result|
            @initialization_container.append do
              if result.okay?
                caption "DNS Resolution <c=0f0>OK</c>", margin_left: LARGE_PADDING
                next_step
              else
                caption "DNS Resolution <c=f00>FAILED</c>", margin_left: LARGE_PADDING
                caption "Failed to resolve: #{result.error}", color: 0xff_ff0000, margin_left: LARGE_PADDING * 2
              end
            end
          end
        end

        def step_launcher_update
          @initialization_container.append do
            tagline "Checking for updates..."
            caption "Launcher version <c=0f0>OK</c>", margin_left: LARGE_PADDING
          end

          after(1000) do
            next_step
          end
        end

        def step_server_list
          @initialization_container.append do
            tagline "Requesting server listing..."
          end

          counter = 0
          every(1000) do
            if !MemCache[:servers].nil? || counter >= 5
              @initialization_container.append do
                if MemCache[:servers]
                  caption "Received #{MemCache[:servers].size} servers <c=0f0>OK</c>", margin_left: LARGE_PADDING
                else
                  caption "Failed to retrieve server listing.", color: 0xff_ff8800, margin_left: LARGE_PADDING
                end

                next_step
              end
            end

            counter += 1
          end
        end

        def step_refresh_account_data
          @initialization_container.append do
            tagline "Updating account information..."
            caption "Refresh session <c=0f0>OK</c>", margin_left: LARGE_PADDING
            caption "Profile data <c=0f0>OK</c>", margin_left: LARGE_PADDING
          end

          after(1000) do
            next_step
          end
        end

        def step_fetch_applications
          @initialization_container.append do
            tagline "Requesting application listing..."
          end

          Worker::Api.applications do |result|
            if result.okay?
              File.write("#{CACHE_PATH}/applications.json", result.data)
              hash = JSON.parse(result.data)
              applications = hash["applications"]&.map { |app| W3DHubLauncher::Worker::Api::Application.new(app) } || []

              MemCache[:applications] = applications

              @initialization_container.append do
                caption "Received #{MemCache[:applications].select(&:game?).size} applications <c=0f0>OK</c>", margin_left: LARGE_PADDING
              end

              next_step
            else
              @initialization_container.append do
                caption "A fatal error occurred while getting application data.", margin_left: LARGE_PADDING, color: 0xaa_ff0000
              end
            end
          end
        end

        def step_battlefield_control_established
          @initialization_acceptable = true

          @initialization_container.append do
            stack(fill: true)
            caption "All required systems operational", color: 0xff_00ff00, width: 1.0, text_v_align: :center, text_align: :center
            banner "Battlefield control established".upcase, width: 1.0, text_v_align: :center, text_align: :center
          end
          @progress_bar.hide

          after(800) do
            next_step
          end
        end
      end
    end
  end
end
