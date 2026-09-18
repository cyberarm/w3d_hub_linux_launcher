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

    def self.join_server(app, server, password: nil, token: nil)

    end
  end
end
