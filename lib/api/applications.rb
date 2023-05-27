class W3DHub
  class Api
    class Applications
      def initialize(response)
        @data = JSON.parse(response, symbolize_names: true)

        games = @data[:applications].select { |a| a[:category] == "games" }

        @games = []

        games.each { |hash| @games << Game.new(hash) }
        @games.sort_by!(&:name).reverse
      end

      def games
        @games
      end

      class Game
        attr_reader :id, :name, :type, :category, :studio_id, :channels, :web_links, :color

        def initialize(hash)
          @data = hash

          @id = @data[:id]
          @name = @data[:name]
          @type = @data[:type]
          @category = @data[:category]
          @studio_id = @data[:"studio-id"]

           # TODO: Do processing
          @channels = @data[:channels].map { |channel| Channel.new(channel) }
          @web_links = @data[:"web-links"]&.map { |link| WebLink.new(link) } || []
          @extended_data = @data[:"extended-data"]

          color = @data[:"extended-data"].find { |h| h[:name] == "colour" }[:value].sub("#", "")

          @color = "ff#{color}".to_i(16)
        end

        class Channel
          attr_reader :id, :name, :user_level, :current_version

          def initialize(hash)
            @data = hash

            @id = @data[:id]
            @name = @data[:name]
            @user_level = @data[:"user-level"]
            @current_version = @data[:"current-version"]
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
