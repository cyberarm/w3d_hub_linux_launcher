module W3DHubLauncher
  module GuiExt
    BLACK_IMAGE = Gosu.render(64, 64, retro: true) { Gosu.draw_rect(0, 0, 32, 32, Gosu::Color::BLACK) }
    WHITE_IMAGE = Gosu.render(64, 64, retro: true) { Gosu.draw_rect(0, 0, 32, 32, Gosu::Color::WHITE) }

    def safe_get_image(path, retro: false)
      raise RuntimeError, "Images may only be loaded from the main thread!" unless Thread.current == Thread.main

      begin
        return get_image(path, retro: retro) if File.exist?(path)
      rescue RuntimeError => e
        pp e
      end

      path = "#{ROOT_PATH}/media/default.png"
      return get_image(path, retro: retro) if File.exist?(path)

      WHITE_IMAGE
    end

    def rounded_avatar(image)
      circle = get_image("#{ROOT_PATH}/media/ui/circle.png")
      scale = [(circle.width.to_f / image.width).abs, (circle.width.to_f / image.height).abs].min

      Gosu.render(circle.width, circle.height) do
        image.draw_rot(circle.width / 2, circle.height / 2, 0, 0, 0.5, 0.5, scale, scale)
        circle.draw(0, 0, 1, 1, 1, 0xff_ffffff, :multiply)
      end
    end

    # Downloads requested url and on success check if host element is still in the layout and call the block if so.
    def remote_image(path, url:, element:, &block)
      memcache_key = :"lock_net_download_#{element.style.tag}"

      if !File.exist?(path) && MemCache[memcache_key].nil?
        MemCache[memcache_key] = true

        Worker::Api.download_url(url, path) do |result|
          # ignore progress reports
          next unless result.okay? && result.data == true

          MemCache.delete(memcache_key)
          # does the target element still exist in the layout?
          e = find_element_by_tag(element.root, element.style.tag)

          next unless e

          if result.okay?
            block.call(element, path)
          end
        end
      end
    end

    def on_main_thread(block)
      window.add_to_queue(block)
    end
  end
end
