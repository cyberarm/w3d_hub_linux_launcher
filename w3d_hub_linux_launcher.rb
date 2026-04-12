begin
  require_relative "../cyberarm_engine/lib/cyberarm_engine"
rescue LoadError
  require "cyberarm_engine"
end

require_relative "lib/window"

GUI_DEBUG = true
window = W3DHubLauncher::Window.new(width: 1280, height: 800, resizable: true)
window.show
