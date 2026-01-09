class W3DHub
  class Api
    class ServerListServer
      NO_OR_BAD_PING = 1_000_000
      NO_OR_DEFAULT_VERSION = "838"

      attr_reader :id, :game, :address, :port, :region, :channel, :version, :ping, :status

      def initialize(hash)
        @data = hash

        @id      = @data[:id]
        @game    = @data[:game]
        @address = @data[:address]
        @port    = @data[:port]
        @region  = @data[:region]
        @channel = @data[:channel] || "release"
        @version = @data[:version] || NO_OR_DEFAULT_VERSION
        @ping    = NO_OR_BAD_PING

        @status  = Status.new(@data[:status])

        @ping_interval = 30_000
        @last_pinged = Gosu.milliseconds + @ping_interval + 1_000
      end

      def update(hash)
        if @status
          @status.name = hash[:name]
          @status.password = hash[:password] || false
          @status.map = hash[:map]
          @status.max_players = hash[:maxplayers]
          @status.player_count = hash[:numplayers] || 0
          @status.started = hash[:started]
          @status.remaining = hash[:remaining]

          @status.teams = hash[:teams]&.map { |t| Team.new(t) } if hash[:teams]
          @status.players = hash[:players]&.select { |t| t[:nick] != "Nod" && t[:nick] != "GDI" }&.map { |t| Player.new(t) } if hash[:players]

          send_ping
        else
          @status = Status.new(hash)
        end

        true
      end

      def send_ping(force_ping = false)
        if force_ping || Gosu.milliseconds - @last_pinged >= @ping_interval
          @last_pinged = Gosu.milliseconds

          W3DHub::BackgroundWorker.foreground_parallel_job(
            lambda do
              W3DHub.command("ping #{@address} #{W3DHub.windows? ? '-n 3' : '-c 3'}") do |line|
                if W3DHub.windows? && line =~ /Minimum|Maximum|Maximum/i
                  @ping = line.strip.split(",").last.split("=").last.sub("ms", "").to_i
                elsif W3DHub.unix? && line.start_with?("rtt min/avg/max/mdev")
                  @ping = line.strip.split("=").last.split("/")[1].to_i
                end
              end

              @ping = NO_OR_BAD_PING if @ping.zero?

              @ping
            end,
            lambda do |_|
              States::Interface.instance&.update_server_ping(self)
            end
          )
        end
      end

      class Status
        attr_accessor :name, :password, :map, :max_players, :player_count, :started, :remaining, :teams, :players

        def initialize(hash)
          @data = hash || {}

          @teams   = @data[:teams]&.map { |t| Team.new(t) } || []
          @players = @data[:players]&.select { |t| t[:nick] != "Nod" && t[:nick] != "GDI" }&.map { |t| Player.new(t) } || []

          @name         = @data[:name] || ""
          @password     = @data[:password] || false
          @map          = @data[:map] || ""
          @max_players  = @data[:maxplayers] || 0
          @player_count = @players.size || @data[:numplayers].to_i
          @started      = @data[:started] || Time.now
          @remaining    = @data[:remaining] || "00.00.00"
        end
      end

      class Team
        attr_accessor :id, :name, :score, :kills, :deaths

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
        attr_accessor :nick, :team, :score, :kills, :deaths

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
