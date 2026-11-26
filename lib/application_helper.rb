module W3DHubLauncher
  class ApplicationHelper
    def self.flatpak_spawn_command(env)
      return "" unless FLATPAK_CONTAINER

      format('flatpak-spawn --directory="%s" --host%s ', Dir.home, env.map { |k, v| "--env=#{k}=#{v}" }.join(" "))
    end

    def self.wine_command(app)
      format('"%s" ', MemCache[:settings]&.preferences&.wine_command || "wine")
    end

    def self.wine_prefix(app)
      [app&.wine_prefix_path, MemCache[:settings]&.preferences&.wine_prefix_path].find { |prefix| !prefix.empty? } || ""
    end

    def self.run(app, *args)
      exe_path = case app.id
                 when "ecw" # ecw is a little special. each of its numbered exes represents a max render distance.
                   format("%s/game500.exe", app.installation_path)
                 when "ren" # little hacky. TT auto patching launcher doesn't work* on linux so bypass it.
                   format("%s/game2.exe", app.installation_path)
                 else # the rest of the games are reasonably sane.
                   format("%s/game.exe", app.installation_path)
                 end

      env = {}
      prefix = wine_prefix(app)
      unless prefix.to_s.empty?
        env["WINEPREFIX"] = format('"%s"', prefix)
      end
      # env["DXVK_HUD"] = "full"

      pid = Process.spawn(
        env,
        "#{flatpak_spawn_command(env)}#{wine_command(app)}\"#{exe_path}\" -launcher #{args.join(' ')}"
      )

      Process.detach(pid)
    end

    def self.join_server(app, server, password: nil, token: nil, multi: false)
      parameters = []

      playername = MemCache[:settings].preferences.nickname

      parameters << format("+connect %s:%s", server.address, server.port)
      parameters << format("+netplayername \"%s\"", playername)
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

      server_options = (MemCache[:servers]&.select do |server|
        server.game == app.id &&
        server.channel == channel.server_channel &&
        !server.password? &&
        server.player_count < server.max_players
      end || []).sort_by do |s|
        [s.player_count, -s.ping]
      end.reverse

      # try to find server with lowest ping and matching app version
      found_server = server_options.find { |s| s.version == app.version }
      # try to find server with lowest ping and undefined version
      found_server ||= server_options.find { |s| s.version == Worker::Api::GameServer::NO_OR_DEFAULT_VERSION }

      found_server
    end

    def self.announce_application_changed(application, state)
      CyberarmEngine::EventBus.publish("application_changed", { application: application, state: state })
    end
  end
end
