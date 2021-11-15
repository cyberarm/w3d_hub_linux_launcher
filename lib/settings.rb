class W3DHub
  class Settings
    def self.defaults
      {
        language: Gosu.user_languages.first.split("_").first,
        app_install_dir: default_app_install_dir,
        package_cache_dir: default_package_cache_dir,
        allow_diagnostic_reports: false,
        server_list_username: nil,
        account: {},
        applications: {},
        games: {}
      }
    end

    def self.default_app_install_dir
      if windows?
        "#{home_directory}/#{W3DHub::DIR_NAME}"
      elsif linux?
        "#{home_directory}/.local/share/#{W3DHub::DIR_NAME}"
      elsif mac?
        "#{home_directory}/.local/share/#{W3DHub::DIR_NAME}"
      else
        raise "Unknown platform: #{RbConfig::CONFIG["host_os"]}"
      end
    end

    def self.default_package_cache_dir
      if windows?
        "#{home_directory}/#{W3DHub::DIR_NAME}/Launcher/package-cache"
      elsif linux?
        "#{home_directory}/.local/share/#{W3DHub::DIR_NAME}/package-cache"
      elsif mac?
        "#{home_directory}/.local/share/#{W3DHub::DIR_NAME}/package-cache"
      else
        raise "Unknown platform: #{RbConfig::CONFIG["host_os"]}"
      end
    end

    def self.windows?
      RbConfig::CONFIG["host_os"] =~ /(mingw|mswin|windows)/i
    end

    def self.mac?
      RbConfig::CONFIG["host_os"] =~ /(darwin|mac os)/i
    end

    def self.linux?
      RbConfig::CONFIG["host_os"] =~ /(linux|bsd|aix|solaris)/i
    end

    def self.home_directory
      File.expand_path("~")
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

    def load_settings
      @settings = JSON.parse(File.read(SETTINGS_FILE_PATH), symbolize_names: true)
    end

    def save_settings
      File.write(SETTINGS_FILE_PATH, @settings.to_json)
    end
  end
end
