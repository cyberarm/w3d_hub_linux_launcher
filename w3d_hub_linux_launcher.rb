begin
  require_relative "../cyberarm_engine/lib/cyberarm_engine"
rescue LoadError
  require "cyberarm_engine"
end

require "socket"
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
require_relative "lib/dialogs/downloads"
require_relative "lib/states/boot"
require_relative "lib/states/interface"
require_relative "lib/window"

require_relative "lib/worker"
require_relative "lib/worker/api"
require_relative "lib/worker/api/application"
require_relative "lib/worker/request"
require_relative "lib/worker/w3dhub_api"
require_relative "lib/worker/task"
require_relative "lib/worker/tasks/install_application"
require_relative "lib/worker/tasks/uninstall_application"
require_relative "lib/worker/tasks/repair_application"
require_relative "lib/worker/tasks/update_application"

module W3DHubLauncher
  MemCache = {}

  # UNIXServer
  Thread.new do
    W3DHubLauncher::Worker.new.listen
  end

  # UNIXSocket / client
  WORKER = W3DHubLauncher::Worker.new
  WORKER.connect
end

window = W3DHubLauncher::Window.new(width: 1280, height: 800, resizable: true)
# window = W3DHubLauncher::Window.new(width: 1920, height: 1080, resizable: true)
window.show
