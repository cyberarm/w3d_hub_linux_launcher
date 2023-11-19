class W3DHub
  class HardwareSurvey
    attr_reader :data

    def initialize
      @data = {
        displays: [],
        system: {
          motherboard: {},
          operating_system: {},
          cpus: [],
          cpu_instruction_sets: {},
          ram: 0,
          gpus: []
        }
      }

      # Hardware survey only works on Windows atm
      return unless RbConfig::CONFIG["host_os"] =~ /mswin|msys|mingw|cygwin/

      lib_dir = File.dirname($LOADED_FEATURES.find { |file| file.include?("gosu.so") })
      SDL.load_lib("#{lib_dir}64/SDL2.dll")
      # Gosu already handles this
      # SDL.VideoInit(nil)

      query_displays
      query_motherboard
      query_operating_system
      query_cpus
      query_ram
      query_gpus

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

    def query_operating_system
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

    def query_cpus
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

    def safe_reg(reg, key, default_value = "Unknown")
      reg[key]
    rescue Win32::Registry::Error
      default_value
    end
  end
end
