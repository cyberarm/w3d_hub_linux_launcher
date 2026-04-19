module W3DHubLauncher
  module Page
    module Boot
      class StartUp < CyberarmEngine::Page
        include GuiExt

        def setup
          stack(width: 1.0, background_nine_slice: NINE_SLICE_ROUNDED, background_nine_slice_from_edge: 8, background_nine_slice_color: 0x11_ffffff, padding: HALF_PADDING) do
            banner "Establishing Battlefield Control", width: 1.0, text_align: :center
            tagline "Please stand by...", width: 1.0, text_align: :center
          end

          stack(width: 1.0, fill: true, padding: PADDING) do
            stack(width: 1.0, fill: true, scroll: true) do
              a = flow(width: 1.0, height: HALF_PADDING + PADDING, visible: false) do
                image safe_get_image("./media/icons/checkmark.png"), height: 1.0, v_align: :center
                tagline "DNS resolution", height: 1.0, text_v_align: :center
              end
              after(500) do
                a.show
              end
              b = flow(width: 1.0, height: HALF_PADDING + PADDING, visible: false) do
                image safe_get_image("./media/icons/information.png"), height: 1.0, v_align: :center, color: 0xff_ff8800
                tagline "Upstream backend", height: 1.0, text_v_align: :center
                caption "Notice: Unreachable. Accounts will be unavailable.", height: 1.0, text_v_align: :center, color: 0xff_ff8800
              end
              after(1000) do
                b.show
              end
              c = flow(width: 1.0, height: HALF_PADDING + PADDING, visible: false) do
                image safe_get_image("./media/icons/checkmark.png"), height: 1.0, v_align: :center
                tagline "Alternate backend", height: 1.0, text_v_align: :center
              end
              after(1500) do
                c.show
              end
              d = flow(width: 1.0, height: HALF_PADDING + PADDING, visible: false) do
                image safe_get_image("./media/icons/information.png"), height: 1.0, v_align: :center, color: 0xff_ff8800
                tagline "Refresh account session", height: 1.0, text_v_align: :center
                caption "Notice: Upstream backend unavailable, session not refreshed.", height: 1.0, text_v_align: :center, color: 0xff_ff8800
              end
              after(2000) do
                d.show
              end
              e = flow(width: 1.0, height: HALF_PADDING + PADDING, visible: false) do
                image safe_get_image("./media/icons/checkmark.png"), height: 1.0, v_align: :center
                tagline "Fetch game servers", height: 1.0, text_v_align: :center
              end
              after(2500) do
                e.show
              end
              f = flow(width: 1.0, height: HALF_PADDING + PADDING, visible: false) do
                image safe_get_image("./media/icons/cross.png"), height: 1.0, v_align: :center, color: 0xff_ff0000
                tagline "Fetch applications", height: 1.0, text_v_align: :center
                caption "Fatal: Failed to retrieve applications list and no local cache exists. Cannot continue.", height: 1.0, text_v_align: :center, color: 0xff_ff0000
              end
              after(3000) do
                f.show
                @progress_bar.type = :linear
                @progress_bar.value = 0.0
              end

              after(3500) do
                parent.page_host.clear do
                  banner "Battlefield control established".upcase, width: 1.0, height: 1.0, text_v_align: :center, text_align: :center
                end
              end
              after(3600) do
                pop_state
                push_state(States::Interface)
              end
            end

            flow(width: 1.0, padding_top: PADDING) do
              @progress_bar = progress width: 1.0, type: :marquee
            end
          end
        end
      end
    end
  end
end
