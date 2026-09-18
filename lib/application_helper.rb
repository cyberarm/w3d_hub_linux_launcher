module W3DHubLauncher
  class ApplicationHelper
    def self.wine_command(app)
      # FIXME: account for the cursed whitespace and wrap in quotes
      format("%s ", MemCache[:settings]&.preferences&.wine_command || "wine")
    end
    def self.wine_prefix(app)
      # TODO: fallback from app specific prefix to launcher prefix to global prefix
      # format("%s ", app&.wine_prefix_path || MemCache[:settings]&.preferences&.wine_prefix_path || "")

      ""
    end

    def self.run(app, *args)
      exe_path = app.id == "ecw" ? format("%s/game500.exe", app.installation_path) : format("%s/game.exe", app.installation_path)

      env = {}
      unless wine_prefix(app).to_s.empty?
        env["WINEPREFIX"] = wine_prefix(app).to_s
      end
      env["DXVK_HUD"] = "full"

      pid = Process.spawn(
        env,
        "#{wine_command(app)}#{exe_path} -launcher #{args.join(' ')}"
      )

      Process.detach(pid)
    end

    def self.join_server(app, server, password: nil, token: nil, multi: false)
      parameters = []

      parameters << format("+connect %s:%s", server.address, server.port)
      parameters << format("+netplayername \"%s\"", "cyberarm")
      parameters << format("+password \"%s\"", password) if password
      parameters << format("+userkey \"%s\"", token) if token
      parameters << "+multi" if multi

      run(
        app,
        parameters.join(" ")
      )
    end

    # select "best" server to join
    def self.play_now_server(app)
      channel = MemCache[:applications].find { |appl| appl.id == app.id }&.channels&.find { |c| c.id == app.channel }
      return nil unless channel

      server_options = MemCache[:servers].select do |server|
        server.game == app.id &&
        server.channel == channel.server_channel &&
        !server.password? &&
        server.player_count < server.max_players
      end.sort_by do |s|
        [s.player_count, -s.ping]
      end.reverse

      # try to find server with lowest ping and matching app version
      found_server = server_options.find { |s| s.version == app.version }
      # try to find server with lowest ping and undefined version
      found_server ||= server_options.find { |s| s.version == Worker::Api::GameServer::NO_OR_DEFAULT_VERSION }

      found_server
    end
  end
end
