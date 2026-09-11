module W3DHubLauncher
  class Worker
    class Api
      # Designed to work with cyberarm's Game Server Hub service data, may work with W3D Hub's service with degraded metadata.
      class GameServer
        BAD_OR_UNKNOWN_PING = 1_000_000

        attr_reader :id, :game, :channel, :address, :port, :region,
                    :name, :password, :current_map, :player_count, :max_players,
                    :match_start_time, :estimated_end_time, :match_remaining_time,
                    :teams, :next_map, :version

        def initialize(data)
          # main data
          @id = data["id"]
          @game = data["game"]
          @channel = data["channel"]
          @address = data["address"]
          @port = data["port"]
          @region = data["region"]

          # status data
          @name = data["status"]["name"]
          @password = data["status"]["password"] || false
          @current_map = data["status"]["map"]
          @player_count = data["status"]["numplayers"] || 0
          @max_players = data["status"]["maxplayers"]

          @match_start_time = data["status"]["started"]
          @estimated_end_time = data["status"]["estimatedEndTime"]
          @match_remaining_time = data["status"]["remaining"]

          # status teams data
          @teams = []
          data["status"]["teams"].each do |team_data|
            @teams << Team.new(team_data)
          end

          # status player data
          data["status"]["players"].each do |player_data|
            team = @teams.find { |t| t.id == player_data["team"] }
            next unless team

            team.players << Player.new(player_data)
          end

          # Cyberarm GSH extras
          @version = data["version"] || "838"
          @next_map = data["status"]["nextmap"] || ""
        end

        # TODO: implement :)
        def time_elapsed
          "00:00"
        end

        def password?
          @password
        end

        def ping
          MemCache.dig(:game_server_pings, @address) || BAD_OR_UNKNOWN_PING
        end

        def ping_score_ratio
          # under 50 is best, over 200 is worst
          case ping
          when 0..49
            return 1.0
          when 50..200
            1.0 - (ping / 200.0) + 0.1
          else
            return 0.1
          end
        end

        def ping_score_color
          case ping
          when 0..49 # gentle green
            0xff_26a269
          when 50..149 # rich orange
            0xff_e5a50a
          when 150..200 # dark red
            0xff_a51d2d
          else # dark gray
            0xff_3d3846
          end
        end
      end

      class Team
        attr_reader :id, :name, :score, :kills, :deaths, :players

        def initialize(data)
          @id = data["id"]
          @name = data["name"]
          @score = data["score"]
          @kills = data["kills"]
          @deaths = data["deaths"]

          @players = []
        end
      end

      class Player
        attr_reader :name, :team, :score, :kills, :deaths, :ping, :time

        def initialize(data)
          @name = data["nick"]
          @team = data["team"]
          @score = data["score"]
          @kills = data["kills"]
          @deaths = data["deaths"]

          # Cyberarm GSH extras
          @ping = data["ping"] || 0
          @time = data["time"] || "00:00:00"
        end
      end
    end
  end
end
