module W3DHubLauncher
  class Worker
    class Api

      # Cached verifcation data for application and pending package files
      class VerificationData
        SCHEMA = 0

        def initialize(path)
          @path = path

          data = {}
          if File.exist?(@path)
            begin
              data = JSON.parse(File.read(@path))
            rescue JSON::ParserError
              data = {}
            end
          end
          data = {} unless data.is_a?(Hash)

          @schema = data["schema"] || SCHEMA
          @data = {}
          data["data"]&.each do |key, value|
            @data[key] = Data.new(value)
          end
        end

        def key(file_name, file_version: "", package: false)
          file_name = file_name.gsub("\\", "/").downcase

          if package
            "package:{file_name}:#{file_version}"
          else
            file_name
          end
        end

        def data(key)
          @data[key]
        end

        def unchanged?(key, checksum:, file_path:)
          data = data(key)
          return nil unless data

          return data if data.checksum.upcase.strip == checksum.upcase.strip &&
                         data.modification_time == File.mtime(file_path).to_i &&
                         data.file_size == File.size(file_path)

          nil
        end

        def set(key, checksum:, file_path:)
          data = Data.new(
            {
              "checksum" => checksum.upcase.strip,
              "modification_time" => File.mtime(file_path).to_i,
              "file_size" => File.size(file_path)
            }
          )

          @data[key] = data
          save

          data
        end

        def delete(key)
          data = @data.delete(key)
          save

          data
        end

        def save
          File.write(@path, JSON.pretty_generate(self))
        end

        def to_json(options = {})
          {
            schema: SCHEMA,
            data: @data
          }.to_json(options)
        end

        class Data
          attr_reader :checksum, :modification_time, :file_size

          def initialize(data)
            @checksum = data["checksum"]
            @modification_time = data["modification_time"]
            @file_size = data["file_size"]
          end

          def to_json(options = {})
            {
              checksum: @checksum,
              modification_time: @modification_time,
              file_size: @file_size
            }.to_json(options)
          end
        end
      end
    end
  end
end
