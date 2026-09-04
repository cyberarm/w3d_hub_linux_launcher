module W3DHubLauncher
  class Worker
    class Api
      class Application
        attr_reader :id, :category, :name, :type, :channels, :extended_data, :web_links

        def initialize(data)
          # pp data

          @id = data["id"]
          @category = data["category"]
          @name = data["name"]
          @type = data["type"]

          @channels = data["channels"]&.map { |c| Channel.new(c, self) } || []

          @extended_data = data["extended-data"]&.map { |d| ExtendedData.new(d) } || nil
          @web_links = data["web-links"]&.map { |d| WebLink.new(d) } || nil

          @servicable = extended_data("application.isservicable", "true").strip.downcase == "true"
        end

        def extended_data(key, default)
          v = @extended_data&.find { |d| d.name == key }&.value
          return default if v.nil?

          v
        end

        # libgosu friendly color
        def color
          "ff_#{extended_data("colour","#000000").sub("#", "")}".to_i(16)
        end

        def game?
          @type.include?("game")
        end

        def servicable?
          @servicable
        end

        def to_json(context = nil)
          {
            "id": @id,
            "category": @category,
            "name": @name,
            "type": @type,
            "channels": @channels,
            "extended-data": @extended_data,
            "web-links": @web_links
          }.to_json(context)
        end

        class Channel
          attr_reader :id, :name, :user_level, :version, :extended_data

          def initialize(data, app)
            @_app = app

            @id = data["id"]
            @name = data["name"]
            @user_level = data["user-level"]
            @version = Gem::Version.new(data["current-version"])
            @extended_data = data["extended-data"]&.map { |d| ExtendedData.new(d) } || nil
          end

          def extended_data(key, default)
            v = @extended_data&.find { |d| d.name == key }&.value
            if v.nil?
              v = @_app.extended_data(key, value)

              return default if v.nil?
            end

            v
          end

          def server_channel
            extended_data("serverchannel", @id)
          end

          def to_json(context = nil)
            {
              "id": @id,
              "name": @name,
              "user-level": @user_level,
              "current-version": @version.to_s,
              "extended-data": @extended_data
            }.to_json(context)
          end
        end

        class ExtendedData
          attr_reader :name, :value

          def initialize(data)
            if data.is_a?(Hash)
              @name = data["name"]
              @value = data["value"]
            else
              @name = data[0]
              @value = data[1]
            end
          end

          def to_json(context = nil)
            {
              "name": @name,
              "value": @value
            }.to_json(context)
          end
        end

        class WebLink
          attr_reader :name, :uri

          def initialize(data)
            @name = data["name"]
            @uri = data["uri"]
          end

          def to_json(context = nil)
            {
              "name": @name,
              "uri": @uri
            }.to_json(context)
          end
        end
      end
    end
  end
end
