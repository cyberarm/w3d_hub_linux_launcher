begin
  require_relative "../cyberarm_engine/lib/cyberarm_engine"
rescue LoadError
  require "cyberarm_engine"
end

require_relative "lib/version"
require_relative "lib/gui_ext"
require_relative "lib/theme"
require_relative "lib/window"

require_relative "lib/worker"
require_relative "lib/worker/api"

module W3DHubLauncher
  WORKER = Ractor.new { W3DHubLauncher::Worker.new }
end

W3DHubLauncher::WORKER.send({ type: :fetch, cache: true, uri: "https://github.com" })

# window = W3DHubLauncher::Window.new(width: 1280, height: 800, resizable: true)
window = W3DHubLauncher::Window.new(width: 1920, height: 1080, resizable: true)
window.show

puts "HELO"
