module W3DHubLauncher
  class Worker
    class Api

      # Inferred or automaticly set options
      class Settings
        SCHEMA = 0

        attr_reader :schema, :preferences

        def initialize(data)
          @schema = data["schema"] || SCHEMA

          @last_selected_app = data["last_selected_app"] || "ren"
          @last_selected_app_channel = data["last_selected_app_channel"] || "release"

          @preferences = Preferences.new(data["preferences"])
          @applications = (data["applications"] || []).map { |app_data| Application.new(app_data) }
        end

        def to_json(context = nil)
          {
            schema: @schema,
            last_selected_app: @last_selected_app,
            last_selected_app_channel: @last_selected_app_channel,
            preferences: @preferences,
            applications: @applications
          }.to_json(context)
        end

        # User explictly set options
        class Preferences
          SCHEMA = 0

          def initialize(data)
            @schema = data["schema"] || SCHEMA

            @language = data["language"] || "en"
            @nickname = data["nickname"] || ""
            @launcher_package_cache_directory = data["launcher_package_cache_directory"] || DEFAULT_PACKAGE_CACHE_PATH
            @application_installation_directory = data["application_installation_directory"] || DEFAULT_APPLICATIONS_PATH
            @wine_prefix_path = data["wine_prefix_path"] || ""
            @wine_command = data["wine_command"] || "wine"
            @winetricks_command = data["winetricks_command"] || "winetricks"
          end

          def to_json(context = nil)
            {

            }.to_json(context)
          end
        end

        # Installed application data
        class Application
          SCHEMA = 0

          def initialize(data)
            @schema = data["schema"] || SCHEMA

            @id = data["id"]
            @channel = data["channel"]
            @version = data["version"]
            @installation_path = data["installation_path"]
            @wine_prefix_path = data["wine_prefix_path"]
            @launch_command = data["launch_command"]
          end

          def to_json(context = nil)
            {

            }.to_json(context)
          end
        end
      end
    end
  end
end
