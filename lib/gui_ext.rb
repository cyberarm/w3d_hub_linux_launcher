module W3DHubLauncher
  module GuiExt
    BLACK_IMAGE = Gosu.render(64, 64, retro: true) { Gosu.draw_rect(0, 0, 32, 32, Gosu::Color::BLACK) }
    WHITE_IMAGE = Gosu.render(64, 64, retro: true) { Gosu.draw_rect(0, 0, 32, 32, Gosu::Color::WHITE) }

    def safe_get_image(path, retro: false)
      return get_image(path, retro: retro) if File.exist?(path)

      path = "./media/default.png"
      return get_image(path, retro: retro) if File.exist?(path)

      WHITE_IMAGE
    end

    def rounded_avatar(image)
      circle = get_image("./media/ui/circle.png")
      scale = [(circle.width.to_f / image.width).abs, (circle.width.to_f / image.height).abs].min

      Gosu.render(circle.width, circle.height) do
        image.draw_rot(circle.width / 2, circle.height / 2, 0, 0, 0.5, 0.5, scale, scale)
        circle.draw(0, 0, 1, 1, 1, 0xff_ffffff, :multiply)
      end
    end
  end
end
