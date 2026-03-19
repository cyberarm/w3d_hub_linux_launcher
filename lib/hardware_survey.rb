class W3DHub
  class HardwareSurvey
    attr_reader :data

    def initialize(displays_only: false)
      @data = {
        displays: [],
        system: {
          motherboard: {
            manufacturer: "Unknown",
            model: "Unknown",
            bios_vendor: "Unknown",
            bios_release_date: "Unknown",
            bios_version: "Unknown"
          },
          operating_system: {
            name: "Unknown",
            build: "Unknown",
            version: "Unknown",
            edition: "Unknown"
          },
          cpus: [],
          cpu_instruction_sets: {},
          ram: 0,
          gpus: []
        }
      }

      if Gem::win_platform?
        lib_dir = File.dirname($LOADED_FEATURES.find { |file| file.include?("gosu.so") })
        SDL.load_lib("#{lib_dir}64/SDL2.dll")
      else
        SDL.load_lib("libSDL2")
      end

      query_displays
      unless displays_only
        query_motherboard
        query_operating_system
        query_cpus
        query_ram
        query_gpus
      end

      @data.freeze
    end

    def query_displays
      SDL.GetNumVideoDisplays.times do |d|
        modes = []
        refresh_rates = []

        SDL.GetNumDisplayModes(d).times do |m|
          mode = SDL::DisplayMode.new
          SDL.GetDisplayMode(d, m, mode)

          refresh_rates << mode[:refresh_rate]

          modes << [mode[:w], mode[:h]]
        end

        @data[:displays] << {
          name: SDL.GetDisplayName(d).read_string,
          refresh_rates: refresh_rates.uniq.sort.reverse,
          resolutions: modes.uniq.sort.reverse
        }
      end
    end

    def query_motherboard
      if Gem::win_platform?
        begin
          Win32::Registry::HKEY_LOCAL_MACHINE.open("HARDWARE\\DESCRIPTION\\System\\BIOS", Win32::Registry::KEY_READ) do |reg|
            @data[:system][:motherboard][:manufacturer]      = safe_reg(reg, "SystemManufacturer")
            @data[:system][:motherboard][:model]             = safe_reg(reg, "SystemProductName")
            @data[:system][:motherboard][:bios_vendor]       = safe_reg(reg, "BIOSVendor")
            @data[:system][:motherboard][:bios_release_date] = safe_reg(reg, "BIOSReleaseDate")
            @data[:system][:motherboard][:bios_version]      = safe_reg(reg, "BIOSVersion")
          end
        rescue Win32::Registry::Error
          @data[:system][:motherboard][:manufacturer]      = "Unknown"
          @data[:system][:motherboard][:model]             = "Unknown"
          @data[:system][:motherboard][:bios_vendor]       = "Unknown"
          @data[:system][:motherboard][:bios_release_date] = "Unknown"
          @data[:system][:motherboard][:bios_version]      = "Unknown"
        end
      else # unix
        @data[:system][:motherboard][:manufacturer]      = safe_file("/sys/devices/virtual/dmi/id/board_vendor")
        @data[:system][:motherboard][:model]             = safe_file("/sys/devices/virtual/dmi/id/board_name")
        @data[:system][:motherboard][:bios_version]      = safe_file("/sys/devices/virtual/dmi/id/board_version")
      end
    end

    def query_operating_system
      if Gem::win_platform?
        begin
          Win32::Registry::HKEY_LOCAL_MACHINE.open("SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion", Win32::Registry::KEY_READ) do |reg|
            @data[:system][:operating_system][:name]    = safe_reg(reg, "ProductName")
            @data[:system][:operating_system][:build]   = safe_reg(reg, "CurrentBuild")
            @data[:system][:operating_system][:version] = safe_reg(reg, "DisplayVersion")
            @data[:system][:operating_system][:edition] = safe_reg(reg, "EditionID")
          end
        rescue Win32::Registry::Error
          @data[:system][:operating_system][:name]    = "Unknown"
          @data[:system][:operating_system][:build]   = "Unknown"
          @data[:system][:operating_system][:version] = "Unknown"
          @data[:system][:operating_system][:edition] = "Unknown"
        end
      else # unix
        release_info = query_release_info
        @data[:system][:operating_system][:name]    = release_info["pretty_name"] || release_info["name"] || "Unknown"
        @data[:system][:operating_system][:build]   = release_info["version_codename"] || release_info["build_id"] || "Unknown"
        @data[:system][:operating_system][:version] = release_info["version_id"] || release_info["build_id"] || "Unknown"
        @data[:system][:operating_system][:edition] = release_info["id"] || release_info["id_like"] || "Unknown"
      end
    end

    def query_cpus
      if Gem::win_platform?
        begin
          Win32::Registry::HKEY_LOCAL_MACHINE.open("HARDWARE\\DESCRIPTION\\System\\CentralProcessor", Win32::Registry::KEY_READ) do |reg|
            i = 0

            reg.each_key do |key|
              reg.open(key) do |cpu|
                @data[:system][:cpus] << {
                  manufacturer: safe_reg(cpu, "VendorIdentifier", "Unknown"),
                  model: safe_reg(cpu, "ProcessorNameString").strip,
                  mhz: safe_reg(cpu, "~MHz"),
                  family: safe_reg(cpu, "Identifier")
                }

                i += 1
              end
            end
          end
        rescue Win32::Registry::Error
        end
      else
        cpu_info = query_cpu_info
        cpu_info.each do |cpu|
          @data[:system][:cpus] << {
            manufacturer: cpu["manufacturer"] || "Unknown",
            model: cpu["model"] || "Unknown",
            mhz: cpu["mhz"] || "Unknown",
            family: cpu["family"] || "Unknown"
          }
        end
      end

      instruction_sets = %w[ HasRDTSC HasAltiVec HasMMX Has3DNow HasSSE HasSSE2 HasSSE3 HasSSE41 HasSSE42 HasAVX HasAVX2 HasAVX512F HasARMSIMD HasNEON ] # HasLSX HasLASX # These cause a crash atm
      list = []
      instruction_sets.each do |i|
        if SDL.send(i).positive?
          list << i.sub("Has", "")
        end

        @data[:system][:cpu_instruction_sets][:"#{i.sub("Has", "").downcase}"] = SDL.send(i).positive?
      end
    end

    def query_ram
      @data[:system][:ram] = SDL.GetSystemRAM
    end

    def query_gpus
      if Gem::win_platform?
        begin
          Win32::Registry::HKEY_LOCAL_MACHINE.open("SYSTEM\\ControlSet001\\Control\\Class\\{4d36e968-e325-11ce-bfc1-08002be10318}", Win32::Registry::KEY_READ) do |reg|
            i = 0

            reg.each_key do |key, _|
              next unless key.start_with?("0")

              reg.open(key) do |device|
                vram = -1

                begin
                  vram = device["HardwareInformation.qwMemorySize"].to_i
                rescue Win32::Registry::Error, TypeError
                  begin
                    vram = device["HardwareInformation.MemorySize"].to_i
                  rescue Win32::Registry::Error, TypeError
                    vram = -1
                  end
                end

                next if vram.negative?

                vram = vram / 1024.0 / 1024.0

                @data[:system][:gpus] << {
                  manufacturer: safe_reg(device, "ProviderName"),
                  model: safe_reg(device, "DriverDesc"),
                  vram: vram.round,
                  driver_date: safe_reg(device, "DriverDate"),
                  driver_version: safe_reg(device, "DriverVersion")
                }

                i += 1
              end
            end
          end
        rescue Win32::Registry::Error
        end
      else # unix
        gpu_info = query_glx_info
        gpu_info.each do |gpu|
          @data[:system][:gpus] << {
            manufacturer: gpu["manufacturer"] || "Unknown",
            model: gpu["model"] || "Unknown",
            vram: gpu["vram"].to_i,
            driver_date: gpu["driver_date"] || "Unknown",
            driver_version: gpu["driver_version"] || "Unknown"
          }
        end
      end
    end

    def safe_reg(reg, key, default_value = "Unknown")
      reg[key]
    rescue Win32::Registry::Error
      default_value
    end

    def safe_file(path, default_value = "Unknown")
      value = File.read(path).to_s.strip
      return default_value if value.downcase == "default string"

      value
    rescue
      default_value
    end

    def query_release_info
      hash = {}

      File.open("/etc/os-release") do |f|
        f.each_line do |line|
          line = line.strip

          key, value = line.split("=", 2)
          value.gsub!('"', "")

          hash[key.downcase] = value
        end
      end

      hash
    rescue
      hash
    end

    def query_cpu_info
      cpus = []

      cpu = {}
      File.open("/proc/cpuinfo") do |f|
        f.each_line do |line|
          line = line.strip

          if line.empty?
            cpu["family"] = format(
              "%s Family %s Model %s Stepping %s",
              cpu["manufacturer"] || "Unknown",
              cpu["_family"] || "Unknown",
              cpu["_model"] || "Unknown",
              cpu["_stepping"] || "Unknown",
            )

            cpus << cpu
            cpu = {}

            next
          end

          key, value = line.split(":", 2).map(&:strip)

          case key.downcase
          when "vendor_id"
            cpu["manufacturer"] = value
          when "model name"
            cpu["model"] = value
          when "cpu mhz"
            cpu["mhz"] = value

          when "cpu family"
            cpu["_family"] = value
          when "model"
            cpu["_model"] = value
          when "stepping"
            cpu["_stepping"] = value
          end
        end
      end

      cpus
    rescue
      cpus
    end

    def query_glx_info
      gpus = []
      glxinfo = `glxinfo`

      return gpus if glxinfo.empty?

      gpu = {}
      glxinfo.lines do |line|
        line = line.strip

        next if line.empty?

        key, value = line.split(":", 2).map(&:strip)

        mesa_info = false
        gpu_memory_info = false
        case key.downcase
        when "opengl vendor string"
          if mesa_info
            gpus << gpu
            gpu = {}

            break
          end
        when /extended renderer info \(GLX_MESA_query_renderer\)/i
          # Joy and happiness
          mesa_info = true
        when /Memory info \(GL_NVX_gpu_memory_info\)/i
          # Happiness and joy
          gpu_memory_info = true
        when "vendor", "opengl vendor string"
          gpu["manufacturer"] = value
        when "device", "opengl renderer string"
          gpu["model"] = value
        when "version"
          gpu["driver_version"] = value
        when "video memory", "dedicated video memory"
          gpu["vram"] = value.gsub(/[\D]+/, "")
        when "opengl version string"
          gpus << gpu
          gpu = {}

          break
        end
      end

      gpus
    end
  end
end
