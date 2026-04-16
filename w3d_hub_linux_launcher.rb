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
  WORKER = Ractor.new(name: "Parallel Worker") { W3DHubLauncher::Worker.new }
end

# Hello, I exist because there presently exists no way to ask if there are pending
# messages in our ractors mailbox without making a blocking call which is a big no no
# for a GUI application. :|
#
# Keep an eye on: https://bugs.ruby-lang.org/issues/21930: "Add Ractor#empty? method to check for pending messages without blocking"
#
# NOTE: May need to mangle Window#update to do ruby-land sleep so thread gets time to process :(
Thread.new do
  loop do
    message = Ractor.receive
    pp message
  end
end

window = W3DHubLauncher::Window.new(width: 1280, height: 800, resizable: true)
# window = W3DHubLauncher::Window.new(width: 1920, height: 1080, resizable: true)
window.show
