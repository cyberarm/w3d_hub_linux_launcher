begin
  require_relative "../cyberarm_engine/lib/cyberarm_engine"
rescue LoadError
  require "cyberarm_engine"
end

require "rexml"
require "base64"
require "logger"

require "async"
require "async/http/internet/instance"
require "async/websocket"
require "digest/crc"
require "ircparser"
require "zip"

require_relative "lib/version"
require_relative "lib/constants"
require_relative "lib/attribution"
require_relative "lib/gui_ext"
require_relative "lib/state"
require_relative "lib/dialog"
require_relative "lib/theme"
require_relative "lib/pages/games"
require_relative "lib/pages/server_browser"
require_relative "lib/pages/boot/terms"
require_relative "lib/pages/boot/initial_setup"
require_relative "lib/pages/boot/start_up"
require_relative "lib/dialogs/about"
require_relative "lib/states/boot"
require_relative "lib/states/interface"
require_relative "lib/window"

require_relative "lib/worker"
require_relative "lib/worker/api"
require_relative "lib/worker/request"
require_relative "lib/worker/w3dhub_api"
require_relative "lib/worker/task"
require_relative "lib/worker/tasks/install_application"
require_relative "lib/worker/tasks/uninstall_application"
require_relative "lib/worker/tasks/repair_application"
require_relative "lib/worker/tasks/update_application"

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
    response = Ractor.receive
    pp response

    request = W3DHubLauncher::Worker::Request.requests.find { |r| r.request_id == response.request_id }
    request&.handle_event(response.status, response.data)
  end
end

10.times do
  W3DHubLauncher::Worker::Request.new(W3DHubLauncher::Worker::Request::W3DHUB_API_CALL, { call: :fetch_applications }) do |result|
    pp result
  end
end

window = W3DHubLauncher::Window.new(width: 1280, height: 800, resizable: true)
# window = W3DHubLauncher::Window.new(width: 1920, height: 1080, resizable: true)
window.show
