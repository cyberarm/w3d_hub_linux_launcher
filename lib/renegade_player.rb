class W3DHub
  class RenegadePlayer
    attr_accessor :name, :team, :score, :kills, :deaths, :ping

    def initialize(name, team, score, kills, deaths, ping)
      @name = name
      @team = team
      @score = score
      @kills = kills
      @deaths = deaths
      @ping = ping
    end
  end
end
