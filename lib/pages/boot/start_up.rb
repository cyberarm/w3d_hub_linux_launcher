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
              # a = flow(width: 1.0, height: HALF_PADDING + PADDING, visible: false) do
              #   image safe_get_image("#{ROOT_PATH}/media/icons/checkmark.png"), height: 1.0, v_align: :center
              #   tagline "DNS resolution", height: 1.0, text_v_align: :center
              # end
              # after(500) do
              #   a.show
              # end
              # b = flow(width: 1.0, height: HALF_PADDING + PADDING, visible: false) do
              #   image safe_get_image("#{ROOT_PATH}/media/icons/information.png"), height: 1.0, v_align: :center, color: 0xff_ff8800
              #   tagline "Upstream backend", height: 1.0, text_v_align: :center
              #   caption "Notice: Unreachable. Accounts will be unavailable.", height: 1.0, text_v_align: :center, color: 0xff_ff8800
              # end
              # after(1000) do
              #   b.show
              # end
              # c = flow(width: 1.0, height: HALF_PADDING + PADDING, visible: false) do
              #   image safe_get_image("#{ROOT_PATH}/media/icons/checkmark.png"), height: 1.0, v_align: :center
              #   tagline "Alternate backend", height: 1.0, text_v_align: :center
              # end
              # after(1500) do
              #   c.show
              # end
              # d = flow(width: 1.0, height: HALF_PADDING + PADDING, visible: false) do
              #   image safe_get_image("#{ROOT_PATH}/media/icons/information.png"), height: 1.0, v_align: :center, color: 0xff_ff8800
              #   tagline "Refresh account session", height: 1.0, text_v_align: :center
              #   caption "Notice: Upstream backend unavailable, session not refreshed.", height: 1.0, text_v_align: :center, color: 0xff_ff8800
              # end
              # after(2000) do
              #   d.show
              # end
              # e = flow(width: 1.0, height: HALF_PADDING + PADDING, visible: false) do
              #   image safe_get_image("#{ROOT_PATH}/media/icons/checkmark.png"), height: 1.0, v_align: :center
              #   tagline "Fetch game servers", height: 1.0, text_v_align: :center
              # end
              # after(2500) do
              #   e.show
              # end
              # f = flow(width: 1.0, height: HALF_PADDING + PADDING, visible: false) do
              #   image safe_get_image("#{ROOT_PATH}/media/icons/cross.png"), height: 1.0, v_align: :center, color: 0xff_ff0000
              #   tagline "Fetch applications", height: 1.0, text_v_align: :center
              #   caption "Fatal: Failed to retrieve applications list and no local cache exists. Cannot continue.", height: 1.0, text_v_align: :center, color: 0xff_ff0000
              # end
              # after(3000) do
              #   puts "HELLO"
              #   W3DHubLauncher::Worker::Request.new(:w3dhub_api_call, { call: :fetch_applications }) do |result|
              #     # pp [:CALLBACK, result]
              #     File.write("applications.json", result.data)
              #     hash = JSON.parse(result.data)
              #     applications = hash["applications"]&.map { |app| W3DHubLauncher::Worker::Api::Application.new(app) } || []
              #     # pp applications.to_json

              #     MemCache[:applications] = applications
              #   end

              #   f.show
              #   @progress_bar.type = :linear
              #   @progress_bar.value = 0.0
              # end

              # after(35000) do
              #   parent.page_host.clear do
              #     banner "Battlefield control established".upcase, width: 1.0, height: 1.0, text_v_align: :center, text_align: :center
              #   end
              # end
              # after(36000) do
              #   pop_state
              #   push_state(States::Interface)
              # end
            end

            flow(width: 1.0, padding_top: PADDING) do
              @progress_bar = progress width: 1.0, fraction: 0.0
            end
          end

          next_step
        end

        def next_step
          step = @steps.shift
          step&.call

          pp (1.0 - (@steps.size / @step_count.to_f)), @steps.size, @step_count
          @progress_bar.value = (1.0 - (@steps.size / @step_count.to_f))
          puts

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
            caption "Found 21 servers <c=0f0>OK</c>", margin_left: LARGE_PADDING
          end

          after(1000) do
            next_step
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
              File.write("applications.json", result.data)
              hash = JSON.parse(result.data)
              applications = hash["applications"]&.map { |app| W3DHubLauncher::Worker::Api::Application.new(app) } || []

              MemCache[:applications] = applications

              @initialization_container.append do
                caption "Refresh session <c=0f0>OK</c>", margin_left: LARGE_PADDING
                caption "Profile data <c=0f0>OK</c>", margin_left: LARGE_PADDING
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

          after(200) do
            parent.page_host.clear do
              banner "Battlefield control established".upcase, width: 1.0, height: 1.0, text_v_align: :center, text_align: :center
            end
          end

          after(800) do
            next_step
          end
        end
      end
    end
  end
end
