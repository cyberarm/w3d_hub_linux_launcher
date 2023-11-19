class W3DHub
  class GameSettings
    TYPE_LIBCONFIG = 0
    TYPE_REGISTRY = 1

    Setting = Struct.new(:group, :name, :label, :type, :key, :value, :options, :indexed)

    def initialize(app_id, channel)
      @app_id = app_id
      @channel = channel

      # Minimium width/height to show in options
      @min_width = 1280
      @min_height = 720

      @win32_registry_base = "SOFTWARE\\W3D Hub\\games\\#{app_id}-#{channel}".freeze
      @engine_cfg_path = "#{Dir.home}/Documents/W3D Hub/games/#{app_id}-#{channel}/engine.cfg".freeze

      @hardware_data = HardwareSurvey.new.data
      @cfg = File.exist?(@engine_cfg_path) ? File.read(@engine_cfg_path) : nil
      @cfg_hash = {}

      resolutions = @hardware_data[:displays].map { |display| display[:resolutions] }.flatten.each_slice(2).select do |pair|
        width = pair[0]
        height = pair[1]

        width >= @min_width && height >= @min_height && width > height
      end

      refresh_rates = ([300, 240, 165, 144, 120, 75, 60, 59, 50, 40] + @hardware_data[:displays].map do |display|
        display[:refresh_rates]
      end).flatten.uniq.sort.reverse.map { |r| [r, r] }

      @settings = {}

      # General
      @settings[:default_to_first_person] = Setting.new(:general, :default_to_first_person, "Default to First Person", TYPE_REGISTRY, "Options\\DefaultToFirstPerson", true)
      @settings[:background_downloads]    = Setting.new(:general, :background_downloads, "Background Downloads", TYPE_REGISTRY, "BackgroundDownloadingEnabled", true)
      @settings[:hints_enabled]           = Setting.new(:general, :hints_enabled, "Enable Hints", TYPE_REGISTRY, "HintsEnabled", true)
      @settings[:chat_log]                = Setting.new(:general, :chat_log, "Enable Chat Log", TYPE_REGISTRY, "ClientChatLog", true)
      @settings[:show_fps]                = Setting.new(:general, :show_fps, "Show FPS", TYPE_REGISTRY, "Networking\\Debug\\ShowFps", true)
      @settings[:show_velocity]           = Setting.new(:general, :show_velocity, "Show Velocity", TYPE_REGISTRY, "ShowVelocity", true)
      @settings[:show_damage_numbers]     = Setting.new(:general, :show_damage_numbers, "Show Damage Numbers", TYPE_REGISTRY, "Options\\HitDamageOnScreen", true)

      # Audio
      @settings[:master_volume]           = Setting.new(:audio, :master_volume, "Master Volume", TYPE_REGISTRY, "Sound\\master volume", 1.0)
      @settings[:master_enabled]          = Setting.new(:audio, :master_enabled, "Master Volume Enabled", TYPE_REGISTRY, "Sound\\master enabled", true)
      @settings[:sound_effects_volume]    = Setting.new(:audio, :sound_effects_volume, "Sound Effects", TYPE_REGISTRY, "Sound\\sound volume", 0.40)
      @settings[:sound_effects_enabled]   = Setting.new(:audio, :sound_effects_enabled, "Sound Effects Enabled", TYPE_REGISTRY, "Sound\\sound enabled", true)
      @settings[:sound_dialog_volume]     = Setting.new(:audio, :sound_dialog_volume, "Dialog", TYPE_REGISTRY, "Sound\\dialog volume", 0.75)
      @settings[:sound_dialog_enabled]    = Setting.new(:audio, :sound_dialog_enabled, "Dialog Enabled", TYPE_REGISTRY, "Sound\\dialog enabled", true)
      @settings[:sound_music_volume]      = Setting.new(:audio, :sound_music_volume, "Music", TYPE_REGISTRY, "Sound\\music volume", 0.75)
      @settings[:sound_music_enabled]     = Setting.new(:audio, :sound_music_enabled, "Music Enabled", TYPE_REGISTRY, "Sound\\music enabled", true)
      @settings[:sound_cinematic_volume]  = Setting.new(:audio, :sound_cinematic_volume, "Cinematic", TYPE_REGISTRY, "Sound\\cinematic volume", 0.75)
      @settings[:sound_cinematic_enabled] = Setting.new(:audio, :sound_cinematic_enabled, "Cinematic Enabled", TYPE_REGISTRY, "Sound\\cinematic enabled", true)

      @settings[:sound_in_background] = Setting.new(:audio, :sound_in_background, "Play Sound with Game in Background", TYPE_REGISTRY, "Sound\\mute in background", false)

      # Video
      @settings[:resolution_width]  = Setting.new(:video, :resolution_width, "Resolution", TYPE_LIBCONFIG, "Render:Width", resolutions.first[0], resolutions.map { |a| [a[0], a[0]] })
      @settings[:resolution_height] = Setting.new(:video, :resolution_height, "Resolution", TYPE_LIBCONFIG, "Render:Height", resolutions.first[1], resolutions.map { |a| [a[1], a[1]] })
      @settings[:windowed_mode]     = Setting.new(:video, :windowed_mode, "Windowed Mode", TYPE_LIBCONFIG, "Render:FullscreenMode", 2, [["Windowed", 0], ["Fullscreen", 1], ["Borderless", 2]], true)
      @settings[:vsync]             = Setting.new(:video, :vsync, "Enable VSync", TYPE_LIBCONFIG, "Render:DisableVSync", true)
      @settings[:fps]               = Setting.new(:video, :fps, "FPS Limit", TYPE_LIBCONFIG, "Render:MaxFPS", refresh_rates.first[1], refresh_rates)
      @settings[:anti_aliasing]     = Setting.new(:video, :anti_aliasing, "Anti-aliasing", TYPE_REGISTRY, "System Settings\\Antialiasing_Mode", 0x80000001, [["None", 0], ["2x", 0x80000000], ["4x", 0x80000001], ["8x", 0x80000002]], true)

      # Performance
      @settings[:texture_detail]         = Setting.new(:performance, :texture_detail, "Texture Detail", TYPE_REGISTRY, "System Settings\\Texture_Resolution", 0, [["High",0], ["Medium", 1], ["Low", 2]], true)
      @settings[:texture_filtering]      = Setting.new(:performance, :texture_filtering, "Texture Filtering", TYPE_REGISTRY, "System Settings\\Texture_Filter_Mode", 3, [["Bilinear", 0], ["Trilinear", 1], ["Anisotropic 2x", 2], ["Anisotropic 4x", 3], ["Anisotropic 8x", 4], ["Anisotropic 16x", 5]], true)
      @settings[:shadow_resolution]      = Setting.new(:performance, :shadow_resolution, "Shadow Resolution", TYPE_REGISTRY, "System Settings\\Dynamic_Shadow_Resolution", 512, [["128", 128], ["256", 256], ["512", 512], ["1024", 1024], ["2048*", 2048], ["4096*", 4096]], true)
      @settings[:high_quality_shadows]   = Setting.new(:general, :high_quality_shadows, "High Quality Shadows", TYPE_REGISTRY, "HighQualityShadows", true)

      load_settings
    end

    def get(key)
      @settings[key]
    end

    def get_value(key)
      setting = get(key)

      if setting.options.is_a?(Array) && setting.indexed
        setting.options[setting.options.map(&:last).index(setting.value)][0]
      else
        setting.value
      end
    end

    def set_value(key, value)
      setting = get(key)

      if setting.options.is_a?(Array)
        setting.value = setting.options.find { |v| v[0] == value }[1]
      elsif setting.options.is_a?(Hash)
        setting.value = value.clamp(setting.options[:min], setting.options[:max])
      else
        setting.value = value
      end
    end

    def load_settings
      load_from_registry
      load_from_cfg
    end

    def load_from_registry
      @settings.each do |_key, setting|
        next unless setting.type == TYPE_REGISTRY

        data = nil
        begin
          data = read_reg(setting.key)
        rescue Win32::Registry::Error
        end
        next unless data

        if setting.value.is_a?(TrueClass) || setting.value.is_a?(FalseClass)
          setting.value = data == 1
        elsif setting.value.is_a?(Float)
          if setting.group == :audio
            setting.value = data.to_f / 100.0
          else
            setting.value = data
          end
        elsif setting.value.is_a?(Integer)
          setting.value = data
        else
          raise "UNKNOWN VALUE TYPE: #{setting.value.class}"
        end
      end
    end

    def load_from_cfg
      @cfg_hash = {}

      if @cfg
        in_hash = false
        @cfg.lines.each do |line|
          line = line.strip
          break if line.start_with?("}")

          if line.start_with?("{")
            in_hash = true
            next
          end

          next unless in_hash

          parts = line.split("=").map { |l| l.strip.sub(";", "")}
          @cfg_hash[parts.first] = parts.last
        end
      end

      @cfg_hash.each do |key, value|
        next if value.start_with?("\"")

        begin
          @cfg_hash[key] = Integer(value)
        rescue ArgumentError # Not an int
          @cfg_hash[key] = value == "true" ? true : false if value == "true" || value == "false"
          @cfg_hash[key] = !@cfg_hash[key] if key == "DisableVSync" # UI shows enable vsync, cfg stores disable vsync
        end
      end

      @settings.each do |key, setting|
        next unless setting.type == TYPE_LIBCONFIG

        cfg_key = setting.key.split(":").last

        v = @cfg_hash[cfg_key]
        if v != nil
          if v.is_a?(TrueClass) || v.is_a?(FalseClass)
            setting.value = v
          elsif v.is_a?(Integer)
            i = setting.options.map(&:last).index(v) || 0
            if ["Width", "Height"].include?(cfg_key)
              set_value(key, setting.options[i][0])
            elsif cfg_key == "MaxFPS"
              setting.value = v
            end
          end
        else
          @cfg_hash[cfg_key] = setting.value
        end
      end
    end

    def save_settings!
      save_to_registry!
      save_to_cfg!
    end

    def save_to_registry!
      @settings.each do |_key, setting|
        next unless setting.type == TYPE_REGISTRY

        if setting.value.is_a?(TrueClass) || setting.value.is_a?(FalseClass)
          write_reg(setting.key, setting.value ? 1 : 0)
        elsif setting.value.is_a?(Float)
          if setting.group == :audio
            write_reg(setting.key, (setting.value * 100.0).round.clamp(0, 100))
          else
            write_reg(setting.key, setting.value)
          end
        elsif setting.value.is_a?(Integer)
          write_reg(setting.key, setting.value)
        else
          raise "UNKNOWN VALUE TYPE: #{setting.value.class}"
        end
      end
    end

    def save_to_cfg!
      @settings.each do |key, setting|
        next unless setting.type == TYPE_LIBCONFIG

        cfg_key = setting.key.split(":").last

        v = @cfg_hash[cfg_key]
        if v
           # UI shows enable vsync, cfg stores disable vsync
          @cfg_hash[cfg_key] = cfg_key == "DisableVSync" ? !setting.value : setting.value
        end
      end

      string = "Render : \n{\n"

      @cfg_hash.each do |key, value|
        string += "  #{key} = #{value.to_s};\n"
      end

      string += "};\n"

      FileUtils.mkdir_p(File.dirname(@engine_cfg_path)) unless Dir.exist?(File.dirname(@engine_cfg_path))
      File.write(@engine_cfg_path, string)
    end

    def read_reg(key)
      keys = key.split("\\")
      sub_key = keys.size > 1 ? keys[0..(keys.size - 2)].join("\\") : ""
      target_key = keys.last
      reg_key = "#{@win32_registry_base}\\#{sub_key}".freeze

      value = nil

      Win32::Registry::HKEY_CURRENT_USER.open(reg_key) do |reg|
        value = reg[target_key]
      end

      value
    end

    def write_reg(key, value)
      keys = key.split("\\")
      sub_key = keys.size > 1 ? keys[0..(keys.size - 2)].join("\\") : ""
      target_key = keys.last
      reg_key = "#{@win32_registry_base}#{sub_key.empty? ? '' : "\\#{sub_key}"}".freeze

      begin
        Win32::Registry::HKEY_CURRENT_USER.open(reg_key, Win32::Registry::KEY_WRITE) do |reg|
          reg[target_key] = value
        end
      rescue Win32::Registry::Error
        result = Win32::Registry::HKEY_CURRENT_USER.create(reg_key)

        result.write_i(target_key, value)
      end
    end
  end
end
