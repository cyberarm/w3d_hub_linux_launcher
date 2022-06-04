class W3DHub
  class Asterisk
    class Config
      CONFIG_PATH = "#{GAME_ROOT_PATH}/data/asterisk.json"

      attr_reader :settings, :server_profiles, :games, :irc_profiles

      def initialize
        @config = nil

        save_new_config unless load_config
        load_config unless @config
      end

      def save_new_config
        hash = {
          settings: {
            theme: :default,

            server_profile: "",
            game: "",
            launch_arguments: "",
            irc_profile: "None",

            nickname: "",
            password: "",
            server_hostname: "",
            server_port: "",

            preload_app: "",
            enable_preload_app: false,

            post_launch_app: "",
            enable_post_launch_app: false,
          },

          server_profiles: [],

          games: [],

          irc_profiles: []
        }

        save_config(hash)
      end

      def load_config
        return false unless File.exist?(CONFIG_PATH)

        begin
          hash = JSON.parse(File.read(CONFIG_PATH), symbolize_names: true)

          @config ||= {}

          @config[:settings] = @settings = Settings.new(hash[:settings])

          @config[:server_profiles] = @server_profiles = []
          hash[:server_profiles].each { |profile| @server_profiles << ServerProfile.new(profile) }

          @config[:games] = @games = []
          hash[:games].each { |game| @games << Game.new(game) }

          @config[:irc_profiles] = @irc_profiles = []
          hash[:irc_profiles].each { |profile| @irc_profiles << IRCProfile.new(profile) }

        rescue JSON::ParserError
          puts "Config corrupted"

          false
        end
      end

      def hard_reset!
        save_new_config
        load_config
      end

      def save_config(config = @config)
        File.write(CONFIG_PATH, config.to_json)
      end
    end
  end
end
