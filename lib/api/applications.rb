class W3DHub
  class Api
    class Applications
      attr_reader :data

      def initialize(response, source = nil)
        @data = JSON.parse(response, symbolize_names: true)

        games = @data[:applications].select { |a| a[:category] == "games" }

        @games = []

        games.each { |hash| @games << Game.new(hash, source) }
        @games.sort_by!(&:name).reverse
      end

      def games
        @games
      end

      class Game
        attr_reader :id, :name, :type, :category, :studio_id, :channels, :web_links, :color
        attr_reader :___source

        def initialize(hash, source = nil)
          @data = hash
          @data[:___source] = source if source

          @id = @data[:id].to_s
          @name = @data[:name]
          @type = @data[:type]
          @category = @data[:category]
          @studio_id = @data[:"studio-id"]

           # TODO: Do processing
          @channels = @data[:channels].map { |channel| Channel.new(channel, source) }
          @web_links = @data[:"web-links"]&.map { |link| WebLink.new(link) } || []
          @extended_data = @data[:"extended-data"]

          color = @data[:"extended-data"].find { |h| h[:name] == "colour" }[:value].sub("#", "")

          color = color.sub("ff", "") if color.length == 8
          @color = "ff#{color}".to_i(16)

          cfg = @data[:"extended-data"].find { |h| h[:name] == "usesEngineCfg" }
          @uses_engine_cfg = (cfg && cfg[:value].to_s.downcase.strip == "true") == true # explicit truthy compare to prevent return `nil`

          cfg = @data[:"extended-data"].find { |h| h[:name] == "usesRenFolder" }
          @uses_ren_folder = (cfg && cfg[:value].to_s.downcase.strip == "true") == true # explicit truthy compare to prevent return `nil`
        end

        def uses_engine_cfg?
          @uses_engine_cfg
        end

        def uses_ren_folder?
          @uses_ren_folder
        end

        def source
          @data[:___source]&.to_sym || :w3dhub
        end

        def source=(sym)
          @data[:___source] = sym
        end

        class Channel
          attr_reader :id, :name, :user_level, :current_version

          def initialize(hash, source = nil)
            @data = hash
            @data[:___source] = source

            @id = @data[:id].to_s
            @name = @data[:name]
            @user_level = @data[:"user-level"]
            @current_version = @data[:"current-version"]
          end

          def source
            @data[:___source]&.to_sym || :w3dhub
          end

          def source=(sym)
            @data[:___source] = sym
          end
        end

        class WebLink
          attr_reader :name, :uri

          def initialize(hash)
            @data = hash

            @name = hash[:name]
            @uri  = hash[:uri]
          end
        end
      end
    end
  end
end
