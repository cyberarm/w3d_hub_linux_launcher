class W3DHub
  class RenegadeServer
    attr_accessor :country, :country_code, :time_left, :ip, :host_port, :hostname, :map_name,
                  :website, :player_count, :max_players, :password, :players

    def initialize(country, country_code, time_left, ip, host_port, hostname, map_name,
                   website, player_count, max_players, password, players)
      @country = country
      @country_code = country_code
      @time_left = time_left
      @ip = ip
      @host_port = host_port
      @hostname = hostname
      @map_name = map_name
      @website = website
      @player_count = player_count
      @max_players = max_players
      @password = password

      @players = players
    end
  end
end
