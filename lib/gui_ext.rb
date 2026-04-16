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
  end
end
