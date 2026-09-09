module Gosu
  # ! nonblocking
  def self.choose_file(&block)
    callback_id = "gc_protect_#{Gosu.milliseconds}"

    callback = lambda do |user_data, file_list, filter|
      data = nil

      if file_list
        data = file_list.read_array_of_string
      end

      block.call(data)

      W3DHubLauncher::MemCache.delete(callback_id)
    end

    W3DHubLauncher::MemCache[callback_id] = callback

    SDL.ShowOpenFileDialog(
      callback,
      nil,
      CyberarmEngine::Window.instance.sdl_window,
      nil,
      0,
      W3DHubLauncher::CACHE_PATH,
      false
    )
  end

  def self.choose_folder()
  end

  def self.save_file()
  end
end
