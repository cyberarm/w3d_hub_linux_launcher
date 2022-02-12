ENV["SDL_VIDEO_ALLOW_SCREENSAVER"] = "1"

begin
  require_relative "../cyberarm_engine/lib/cyberarm_engine"
rescue LoadError => e
  puts "Failed to load local cyberarm_engine:"
  pp e

  require "cyberarm_engine"
end
require "fileutils"
require "digest"
require "rexml"

require "i18n"
require "launchy"

require "async"
require "async/barrier"
require "async/semaphore"
require "async/http/internet/instance"
require "async/http/endpoint"
require "async/websocket/client"
require "protocol/websocket/connection"

I18n.load_path << Dir[File.expand_path("locales") + "/*.yml"]
I18n.default_locale = :en

class W3DHub
  GAME_ROOT_PATH = File.expand_path(".", __dir__)
  CACHE_PATH = "#{GAME_ROOT_PATH}/data/cache"
  SETTINGS_FILE_PATH = "#{GAME_ROOT_PATH}/data/settings.json"

  EMPTY_IMAGE = Gosu::Image.from_blob(1, 1)
  BLACK_IMAGE = Gosu::Image.from_blob(1, 1, "\x00\x00\x00\xff")
end

require_relative "lib/version"
require_relative "lib/theme"
require_relative "lib/common"
require_relative "lib/store"
require_relative "lib/window"
require_relative "lib/cache"
require_relative "lib/settings"
require_relative "lib/mixer"
require_relative "lib/ico"
require_relative "lib/multicast_server"
require_relative "lib/background_worker"
require_relative "lib/application_manager"
require_relative "lib/application_manager/manifest"
require_relative "lib/application_manager/status"
require_relative "lib/application_manager/pool"
require_relative "lib/application_manager/task"
require_relative "lib/application_manager/tasks/installer"
require_relative "lib/application_manager/tasks/updater"
require_relative "lib/application_manager/tasks/uninstaller"
require_relative "lib/application_manager/tasks/repairer"
require_relative "lib/application_manager/tasks/importer"
require_relative "lib/states/demo_input_delay"
require_relative "lib/states/boot"
require_relative "lib/states/interface"
require_relative "lib/states/message_dialog"
require_relative "lib/states/prompt_dialog"
require_relative "lib/states/confirm_dialog"

require_relative "lib/api"
require_relative "lib/api/service_status"
require_relative "lib/api/applications"
require_relative "lib/api/news"
require_relative "lib/api/server_list_server"
require_relative "lib/api/server_list_updater"
require_relative "lib/api/account"
require_relative "lib/api/package"

require_relative "lib/page"
require_relative "lib/pages/games"
require_relative "lib/pages/server_browser"
require_relative "lib/pages/community"
require_relative "lib/pages/login"
require_relative "lib/pages/settings"
require_relative "lib/pages/download_manager"

Thread.new do
  W3DHub::BackgroundWorker.create
end

W3DHub::Window.new(width: 980, height: 720, borderless: false).show
