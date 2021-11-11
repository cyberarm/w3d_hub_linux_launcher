require "cyberarm_engine"
require "sanitize"
require "rss"
require "zlib"
require "launchy"

GAME_ROOT_PATH = File.expand_path(".", __dir__)
EMPTY_IMAGE = Gosu::Image.from_blob(1, 1)
BLACK_IMAGE = Gosu::Image.from_blob(1, 1, "\x00\x00\x00\xff")

require_relative "lib/window"
require_relative "lib/states/boot"
require_relative "lib/states/interface"

require_relative "lib/game"
require_relative "lib/games/renegade"
require_relative "lib/games/expansive_civilian_warfare"
require_relative "lib/games/interim_apex"
require_relative "lib/games/ra_a_path_beyond"
require_relative "lib/games/ts_reborn"

require_relative "lib/page"
require_relative "lib/pages/games"
require_relative "lib/pages/server_browser"
require_relative "lib/pages/community"
require_relative "lib/pages/login"
require_relative "lib/pages/settings"
require_relative "lib/pages/download_manager"

require_relative "lib/renegade_server"
require_relative "lib/renegade_player"

W3DHub::Game.load_games

W3DHub::Window.new(width: 980, height: 720, borderless: false).show
