require "cyberarm_engine"
require "sanitize"
require "rss"
require "zlib"
require "launchy"

GAME_ROOT_PATH = File.expand_path(".", __dir__)
EMPTY_IMAGE = Gosu::Image.from_blob(1, 1)

require_relative "lib/window"
require_relative "lib/states/boot"
require_relative "lib/states/interface"

require_relative "lib/game"
require_relative "lib/games/renegade"
require_relative "lib/games/expansive_civilian_warfare"
require_relative "lib/games/interim_apex"
require_relative "lib/games/ra_a_path_beyond"
require_relative "lib/games/ts_reborn"

W3DHub::Game.load_games

W3DHub::Window.new(width: 980, height: 720, borderless: false).show
