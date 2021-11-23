class W3DHub
  class Settings
    def self.defaults
      {
        language: Gosu.user_languages.first.split("_").first,
        app_install_dir: default_app_install_dir,
        package_cache_dir: default_package_cache_dir,
        wine_command: "wine",
        create_wine_prefixes: true,
        allow_diagnostic_reports: false,
        server_list_username: "",
        server_list_filters: {},
        server_list_region: "Any",
        account: {},
        applications: {},
        games: {}
      }
    end

    def self.default_app_install_dir
      if W3DHub.windows?
        "#{W3DHub.home_directory}/#{W3DHub::DIR_NAME}"
      elsif W3DHub.linux?
        "#{W3DHub.home_directory}/.local/share/#{W3DHub::DIR_NAME}"
      elsif W3DHub.mac?
        "#{W3DHub.home_directory}/.local/share/#{W3DHub::DIR_NAME}"
      else
        raise "Unknown platform: #{RbConfig::CONFIG["host_os"]}"
      end
    end

    def self.default_package_cache_dir
      if W3DHub.windows?
        "#{W3DHub.home_directory}/#{W3DHub::DIR_NAME}/Launcher/package-cache"
      elsif W3DHub.linux?
        "#{W3DHub.home_directory}/.local/share/#{W3DHub::DIR_NAME}/package-cache"
      elsif W3DHub.mac?
        "#{W3DHub.home_directory}/.local/share/#{W3DHub::DIR_NAME}/package-cache"
      else
        raise "Unknown platform: #{RbConfig::CONFIG["host_os"]}"
      end
    end

    def initialize
      unless File.exist?(SETTINGS_FILE_PATH)
        @settings = Settings.defaults

        save_settings
      else
        load_settings
      end
    end

    def [](*args)
      @settings.dig(*args)
    end

    def []=(key, value)
      @settings[key] = value
    end

    def load_settings
      @settings = JSON.parse(File.read(SETTINGS_FILE_PATH), symbolize_names: true)
    end

    def save_settings
      File.write(SETTINGS_FILE_PATH, @settings.to_json)
    end
  end
end
