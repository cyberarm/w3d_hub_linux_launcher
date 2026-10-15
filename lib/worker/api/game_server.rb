module W3DHubLauncher
  class Worker
    class Api
      # Designed to work with cyberarm's Game Server Hub service data, may work with W3D Hub's service with degraded metadata.
      class GameServer
        BAD_OR_UNKNOWN_PING = 1_000_000
        NO_OR_DEFAULT_VERSION = "838".freeze

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

          @match_start_time = Time.parse(data["status"]["started"])
          @estimated_end_time = data["status"]["estimatedEndTime"] ? Time.parse(data["status"]["estimatedEndTime"]) : nil
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
          @version = data["version"] || NO_OR_DEFAULT_VERSION
          @next_map = data["status"]["nextmap"] || ""

          @version = Gem::Version.new(@version) if @version.split(".").size == 4
        end

        # TODO: implement :)
        def time_elapsed
          elapsed_seconds = Time.now.utc.to_i - @match_start_time.utc.to_i

          hours = (elapsed_seconds / 60.0 / 60.0).floor % 100
          minutes = (elapsed_seconds / 60.0).floor % 60
          seconds = (elapsed_seconds).floor % 60

          format("%02d:%02d:%02d", hours, minutes, seconds)
        end

        def time_remaining
          return "∞" unless @estimated_end_time

          remaining_seconds = @estimated_end_time.utc.to_i - Time.now.utc.to_i
          remaining_seconds = 0 if remaining_seconds.negative?

          hours = (remaining_seconds / 60.0 / 60.0).floor % 100
          minutes = (remaining_seconds / 60.0).floor % 60
          seconds = (remaining_seconds).floor % 60

          format("%02d:%02d:%02d", hours, minutes, seconds)
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

        def map_preview_image_path
          format("%s/map_preview_%s.png", W3DHubLauncher::CACHE_PATH, Digest::SHA256.hexdigest("#{@game}_#{@channel}_#{@current_map}"))
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
