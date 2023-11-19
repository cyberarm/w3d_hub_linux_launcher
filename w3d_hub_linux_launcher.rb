# Hint to SDL that we're not a game and that the system may sleep
ENV["SDL_VIDEO_ALLOW_SCREENSAVER"] = "1"

require "fileutils"
require "digest"
require "rexml"
require "logger"
require "time"
require "base64"
require "zip"

class W3DHub
  W3DHUB_DEBUG = ARGV.join.include?("--debug")
  W3DHUB_DEVELOPER = ARGV.join.include?("--developer")

  GAME_ROOT_PATH = File.expand_path(".", __dir__)
  CACHE_PATH = "#{GAME_ROOT_PATH}/data/cache"
  SETTINGS_FILE_PATH = "#{GAME_ROOT_PATH}/data/settings.json"

  LOGGER = Logger.new("#{GAME_ROOT_PATH}/data/logs/w3d_hub_linux_launcher.log", "daily")
  LOGGER.level = Logger::Severity::DEBUG # W3DHUB_DEBUG ? Logger::Severity::DEBUG : Logger::Severity::WARN

  LOG_TAG = "W3DHubLinuxLauncher"
end

module Kernel
  def logger
    @logger = W3DHub::LOGGER
  end

  class W3DHubLogger
    def initialize
    end

    def level=(options)
    end

    def info(tag, &block)
      pp [tag, block&.call]
    end

    def debug(tag, &block)
      pp [tag, block&.call]
    end

    def warn(tag, &block)
      pp [tag, block&.call]
    end

    def error(tag, &block)
      pp [tag, block&.call]
    end
  end
end

begin
  require_relative "../cyberarm_engine/lib/cyberarm_engine"
rescue LoadError => e
  logger.warn(W3DHub::LOG_TAG) { "Failed to load local cyberarm_engine:" }
  logger.warn(W3DHub::LOG_TAG) { e }

  require "cyberarm_engine"
end

class W3DHub
  EMPTY_IMAGE = Gosu::Image.from_blob(1, 1)
  BLACK_IMAGE = Gosu::Image.from_blob(1, 1, "\x00\x00\x00\xff")
end

require "i18n"
require "websocket-client-simple"
require "English"
require "sdl2"

I18n.load_path << Dir["#{W3DHub::GAME_ROOT_PATH}/locales/*.yml"]
I18n.default_locale = :en

# GUI_DEBUG = true
require_relative "lib/gui_state_ext"

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
require_relative "lib/hardware_survey"
require_relative "lib/game_settings"
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
# require_relative "lib/states/interface"
require_relative "lib/states/interface_redesign"
require_relative "lib/states/welcome"
require_relative "lib/states/dialog"
require_relative "lib/states/message_dialog"
require_relative "lib/states/prompt_dialog"
require_relative "lib/states/confirm_dialog"
require_relative "lib/states/direct_connect_dialog"
# require_relative "lib/states/game_settings_dialog"
require_relative "lib/states/dialogs/game_settings_dialog"

require_relative "lib/api"
require_relative "lib/api/service_status"
require_relative "lib/api/applications"
require_relative "lib/api/news"
require_relative "lib/api/server_list_server"
require_relative "lib/api/server_list_updater"
require_relative "lib/api/account"
require_relative "lib/api/package"
require_relative "lib/api/event"

require_relative "lib/page"
# require_relative "lib/pages/games"
require_relative "lib/pages/games_redesign"
require_relative "lib/pages/server_browser"
require_relative "lib/pages/community"
require_relative "lib/pages/login"
require_relative "lib/pages/settings"
require_relative "lib/pages/download_manager"

require_relative "lib/asterisk/irc_client"
require_relative "lib/asterisk/config"
require_relative "lib/asterisk/game"
require_relative "lib/asterisk/irc_profile"
require_relative "lib/asterisk/server_profile"
require_relative "lib/asterisk/settings"
require_relative "lib/asterisk/states/game_form"
require_relative "lib/asterisk/states/irc_profile_form"
require_relative "lib/asterisk/states/server_profile_form"

require "win32/process" if W3DHub.windows?

logger.info(W3DHub::LOG_TAG) { "W3D Hub Linux Launcher v#{W3DHub::VERSION}" }

Thread.new do
  W3DHub::BackgroundWorker.create
end

until W3DHub::BackgroundWorker.alive?
  sleep 0.1
end

logger.info(W3DHub::LOG_TAG) { "Launching window..." }
# W3DHub::Window.new(width: 980, height: 720, borderless: false, resizable: true).show unless defined?(Ocra)
W3DHub::Window.new(width: 1280, height: 800, borderless: false, resizable: true).show unless defined?(Ocra)
# W3DHub::Window.new(width: 1920, height: 1080, borderless: false, resizable: true).show unless defined?(Ocra)
W3DHub::BackgroundWorker.shutdown!

worker_soft_halt = Gosu.milliseconds

# Wait for BackgroundWorker to return
while W3DHub::BackgroundWorker.alive?
  W3DHub::BackgroundWorker.kill! if Gosu.milliseconds - worker_soft_halt >= 1_000

  sleep 0.1
end

W3DHub::LOGGER&.close
