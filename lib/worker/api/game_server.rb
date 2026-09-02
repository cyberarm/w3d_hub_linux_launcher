module W3DHubLauncher
  class Worker
    class Api
      # Designed to work with cyberarm's Game Server Hub service data, may work with W3D Hub's service with degraded metadata.
      class GameServer
        attr_reader :id, :game, :channel, :address, :port, :region, :version

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
            team = @teams.find { |t| t.id == player_data["id"] }
            next unless team

            team.players << Player.new(player_data)
          end

          # Cyberarm GSH extras
          @version = data["version"] || "838"
          @next_map = data["status"]["nextmap"] || ""
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
