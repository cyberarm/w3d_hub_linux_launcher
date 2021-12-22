class W3DHub
  class Api
    class ServerListServer
      attr_reader :id, :game, :address, :port, :region, :channel, :status

      def initialize(hash)
        @data = hash

        @id      = @data[:id]
        @game    = @data[:game]
        @address = @data[:address]
        @port    = @data[:port]
        @region  = @data[:region]
        @channel = @data[:channel] || "release"

        @status  = @data[:status] ? Status.new(@data[:status]) : nil
      end

      class Status
        attr_reader :name, :password, :map, :max_players, :player_count, :started, :remaining, :teams, :players

        def initialize(hash)
          @data = hash

          @teams   = @data[:teams]&.map { |t| Team.new(t) }
          @players = @data[:players]&.select { |t| t[:nick] != "Nod" && t[:nick] != "GDI" }&.map { |t| Player.new(t) }

          @name         = @data[:name]
          @password     = @data[:password] || false
          @map          = @data[:map]
          @max_players  = @data[:maxplayers]
          @player_count = @players.size || @data[:numplayers].to_i
          @started      = @data[:started]
          @remaining    = @data[:remaining]
        end
      end

      class Team
        attr_reader :id, :name, :score, :kills, :deaths

        def initialize(hash)
          @data = hash

          @id     = @data[:id]
          @name   = @data[:name]
          @score  = @data[:score]
          @kills  = @data[:kills]
          @deaths = @data[:deaths]
        end
      end

      class Player
        attr_reader :nick, :team, :score, :kills, :deaths

        def initialize(hash)
          @data = hash

          @nick   = @data[:nick]
          @team   = @data[:team]
          @score  = @data[:score]
          @kills  = @data[:kills]
          @deaths = @data[:deaths]
        end
      end
    end
  end
end
