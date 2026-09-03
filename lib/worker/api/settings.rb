module W3DHubLauncher
  class Worker
    class Api

      # Inferred or automaticly set options
      class Settings
        SCHEMA = 0

        attr_accessor :last_selected_app, :last_selected_app_channel, :last_selected_server_app, :preferences, :applications, :account

        def initialize(data)
          @schema = data["schema"] || SCHEMA

          raise "Data is not a hash!" unless data.is_a?(Hash)

          @last_selected_app = data["last_selected_app"] || "ren"
          @last_selected_app_channel = data["last_selected_app_channel"] || "release"
          @last_selected_server_app = data["last_selected_server_app"] || ""

          @preferences = Preferences.new(data["preferences"])
          @applications = (data["applications"] || []).map { |app_data| Application.new(app_data) }
          @account = Account.new(data["account"])
        end

        def to_json(options = {})
          {
            schema: @schema,
            last_selected_app: @last_selected_app,
            last_selected_app_channel: @last_selected_app_channel,
            last_selected_server_app: @last_selected_server_app,
            preferences: @preferences,
            applications: @applications,
            account: @account
          }.to_json(options)
        end

        # User explictly set options
        class Preferences
          SCHEMA = 0

          attr_accessor :language, :nickname, :launcher_package_cache_directory, :application_installation_directory,
                        :wine_prefix_path, :wine_command, :winetricks_command

          def initialize(data)
            data ||= {}

            @schema = data["schema"] || SCHEMA

            @language = data["language"] || "en"
            @nickname = data["nickname"] || ""
            @launcher_package_cache_directory = data["launcher_package_cache_directory"] || DEFAULT_PACKAGE_CACHE_PATH
            @application_installation_directory = data["application_installation_directory"] || DEFAULT_APPLICATIONS_PATH
            @wine_prefix_path = data["wine_prefix_path"] || ""
            @wine_command = data["wine_command"] || "wine"
            @winetricks_command = data["winetricks_command"] || "winetricks"
          end

          def to_json(options = {})
            {
              schema: @schema,
              language: @language,
              nickname: @nickname,
              launcher_package_cache_directory: @launcher_package_cache_directory,
              application_installation_directory: @application_installation_directory,
              wine_prefix_path: @wine_prefix_path,
              wine_command: @wine_command,
              winetricks_command: @winetricks_command
            }.to_json(options)
          end
        end

        # Installed application data
        class Application
          SCHEMA = 0

          attr_reader :id, :channel
          attr_accessor :version, :installation_path, :wine_prefix_path, :launch_command

          def self.create(id:, channel:, version:, installation_path:, wine_prefix_path:, launch_command:)
            hash = {
              "schema" => SCHEMA,
              "id" => id,
              "channel" => channel,
              "version" => Gem::Version.new(version),
              "installation_path" => installation_path,
              "wine_prefix_path" => wine_prefix_path,
              "launch_command" => launch_command,
            }

            self.new(hash)
          end

          def initialize(data)
            @schema = data["schema"] || SCHEMA

            @id = data["id"]
            @channel = data["channel"]
            @version = Gem::Version.new(data["version"])
            @installation_path = data["installation_path"]
            @wine_prefix_path = data["wine_prefix_path"]
            @launch_command = data["launch_command"]
          end

          def to_json(options = {})
            {
              schema: @schema,
              id: @id,
              channel: @channel,
              version: @version.to_s,
              installation_path: @installation_path,
              wine_prefix_path: @wine_prefix_path,
              launch_command: @launch_command
            }.to_json(options)
          end
        end

        # User account data
        class Account
          SCHEMA = 0

          attr_accessor :user_id, :username, :displayname, :avatar_uri, :access_token, :refresh_token,
                        :access_token_expiration_time

          def self.create(user_id:, username:, displayname:, avatar_uri:, access_token:, refresh_token:, access_token_expiration_time:)
            hash = {
              "schema" => SCHEMA,
              "user_id" => user_id,
              "username" => username,
              "displayname" => displayname,
              "avatar_uri" => avatar_uri,
              "access_token" => access_token,
              "refresh_token" => refresh_token,
              "access_token_expiration_time" => access_token_expiration_time
            }

            self.new(hash)
          end

          def initialize(data)
            data ||= {}

            @schema = data["schema"] || SCHEMA

            @user_id = data["user_id"] || -1
            @username = data["username"] || ""
            @displayname = data["displayname"] || ""
            @avatar_uri = data["avatar_uri"] || ""
            @access_token = data["access_token"] || ""
            @refresh_token = data["refresh_token"] || ""
            @access_token_expiration_time = Time.at(data["access_token_expiration_time"] || 0)
          end

          def signed_in?
            @user_id.positive?
          end

          def to_json(options = {})
            {
              schema: @schema,
              user_id: @user_id,
              username: @username,
              displayname: @displayname,
              avatar_uri: @avatar_uri,
              access_token: @access_token,
              refresh_token: @refresh_token,
              access_token_expiration_time: @access_token_expiration_time.to_i
            }.to_json(options)
          end
        end
      end
    end
  end
end
