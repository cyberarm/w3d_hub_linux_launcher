require "cyberarm_engine"

GAME_ROOT_PATH = File.expand_path(".", __dir__)

require_relative "lib/window"
require_relative "lib/states/boot"
require_relative "lib/states/interface"

W3DHub::Window.new(width: 980, height: 720, borderless: false).show
