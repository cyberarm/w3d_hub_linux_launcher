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

          @channels = data["channels"]&.map { |c| Channel.new(c) } || []

          @extended_data = data["extended-data"]&.map { |d| ExtendedData.new(d) } || nil
          @web_links = data["web-links"]&.map { |d| WebLink.new(d) } || nil
        end

        # libgosu friendly color
        def color
          "ff_#{(@extended_data["colour"] || "#000000").sub("#", "")}".to_i(16)
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
          attr_reader :id, :name, :user_level, :version

          def initialize(data)
            @id = data["id"]
            @name = data["name"]
            @user_level = data["user-level"]
            @version = Gem::Version.new(data["current-version"])
          end

          def to_json(context = nil)
            {
              "id": @id,
              "name": @name,
              "user-level": @user_level,
              "current-version": @version.to_s
            }.to_json(context)
          end
        end

        class ExtendedData
          attr_reader :name, :value

          def initialize(data)
            @name = data["name"]
            @value = data["value"]
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
