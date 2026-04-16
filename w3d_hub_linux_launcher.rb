begin
  require_relative "../cyberarm_engine/lib/cyberarm_engine"
rescue LoadError
  require "cyberarm_engine"
end

require_relative "lib/window"

# window = W3DHubLauncher::Window.new(width: 1280, height: 800, resizable: true)
window = W3DHubLauncher::Window.new(width: 1920, height: 1080, resizable: true)
window.show
