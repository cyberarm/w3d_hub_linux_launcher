class W3DHub
  class Api
    USER_AGENT = "Cyberarm's Linux Friendly W3D Hub Launcher v#{W3DHub::VERSION}"
    DEFAULT_HEADERS = {
      "User-Agent": USER_AGENT
    }

    #! === W3D Hub API === !#

    ENDPOINT = "https://secure.w3dhub.com"
    W3DHUB_API_CONNECTION = Excon.new(ENDPOINT, persistent: true, connect_timeout: 15)
    # Method: POST
    # FORMAT: JSON

    # /apis/launcher/1/user-login
    # For an already logged in user the launcher sends
    # a "refreshToken" in the data field: data={"refreshToken":"TOKEN_STRING"}
    #
    # For a logging in user the launcher sends
    # data={"username":"NAME","password":"password_as_plaintext_but_over_https"}
    #
    # On successful login/token refresh the service responds with:
    # {"session_token":"string","userid:"1234"...}
    #
    # On a failed login the service responds with:
    # {"error":"login-failed"}
    def self.refresh_user_login(refresh_token)
      response = W3DHUB_API_CONNECTION.post(
        path: "apis/launcher/1/user-login",
        headers: DEFAULT_HEADERS.merge({"Content-Type": "application/x-www-form-urlencoded"}),
        body: "data=#{JSON.dump({refreshToken: refresh_token})}"
      )

      if response.status == 200
        user_data = JSON.parse(response.body, symbolize_names: true)

        return false if user_data[:error]

        user_details = W3DHUB_API_CONNECTION.post(
          path: "apis/w3dhub/1/get-user-details",
          headers: DEFAULT_HEADERS.merge({"Content-Type": "application/x-www-form-urlencoded"}),
          body: "data=#{JSON.dump({ id: user_data[:userid] })}"
        )

        if user_details.status == 200
          user_details_data = JSON.parse(user_details.body, symbolize_names: true)
        end

        return Account.new(user_data, user_details_data)
      else
        false
      end
    end

    # See #user_refresh_token
    def self.user_login(username, password)
      response = W3DHUB_API_CONNECTION.post(
        path: "apis/launcher/1/user-login",
        headers: DEFAULT_HEADERS.merge({"Content-Type": "application/x-www-form-urlencoded"}),
        body: "data=#{JSON.dump({username: username, password: password})}"
      )

      if response.status == 200
        user_data = JSON.parse(response.body, symbolize_names: true)

        return false if user_data[:error]

        user_details = W3DHUB_API_CONNECTION.post(
          path: "apis/w3dhub/1/get-user-details",
          headers: DEFAULT_HEADERS.merge({"Content-Type": "application/x-www-form-urlencoded"}),
          body: "data=#{JSON.dump({ id: user_data[:userid] })}"
        )

        if user_details.status == 200
          user_details_data = JSON.parse(user_details.body, symbolize_names: true)
        end

        return Account.new(user_data, user_details_data)
      else
        false
      end
    end

    # /apis/launcher/1/user-login
    # Client sends an Authorization header bearer token which is received from logging in (Required?)
    #
    # Response: avatar-uri (Image download uri), id, username
    def self.user_details(id)
    end

    # /apis/w3dhub/1/get-service-status
    # Service response:
    # {"services":{"authentication":true,"packageDownload":true}}
    def self.service_status
      response = W3DHUB_API_CONNECTION.post(
        path: "apis/w3dhub/1/get-service-status",
        headers: DEFAULT_HEADERS
      )

      if response.status == 200
        ServiceStatus.new(response.body)
      else
        false
      end
    end

    # /apis/launcher/1/get-applications
    # Client sends an Authorization header bearer token which is received from logging in (Optional)
    # Launcher sends an empty data request: data={}
    # Response is a list of applications/games
    def self.applications
      response = W3DHUB_API_CONNECTION.post(
        path: "apis/launcher/1/get-applications",
        headers: DEFAULT_HEADERS
      )

      if response.status == 200
        Applications.new(response.body)
      else
        false
      end
    end

    # /apis/w3dhub/1/get-news
    # Client sends an Authorization header bearer token which is received from logging in (Optional)
    # Client requests news for a specific application/game e.g.: data={"category":"ia"}
    # Response is a JSON hash with a "highlighted" and "news" keys; the "news" on seems to be the desired one
    def self.news(category)
      response = W3DHUB_API_CONNECTION.post(
        path: "apis/w3dhub/1/get-news",
        headers: DEFAULT_HEADERS.merge({"Content-Type": "application/x-www-form-urlencoded"}),
        body: "data=#{JSON.dump({category: category})}"
      )

      if response.status == 200
        News.new(response.body)
      else
        false
      end
    end

    # Downloading games

    # /apis/launcher/1/get-package-details
    # client requests package details: data={"packages":[{"category":"games","name":"apb.ico","subcategory":"apb","version":""}]}
    def self.package_details(packages)
      response = Excon.post(
        "#{ENDPOINT}/apis/launcher/1/get-package-details",
        headers: DEFAULT_HEADERS.merge({"Content-Type": "application/x-www-form-urlencoded"}),
        body: "data=#{JSON.dump({ packages: packages })}"
      )

      if response.status == 200
        hash = JSON.parse(response.body, symbolize_names: true)
        packages = hash[:packages].map { |pkg| Package.new(pkg) }
        return packages.first if packages.size == 1
        return packages
      else
        false
      end
    end

    # /apis/launcher/1/get-package
    # client requests package: data={"category":"games","name":"ECW_Asteroids.zip","subcategory":"ecw","version":"1.0.0.0"}
    #
    # server responds with download bytes, probably supports chunked download and resume
    def self.package(category, subcategory, name, version, &block)
      Cache.fetch_package(W3DHUB_API_CONNECTION, category, subcategory, name, version, block)
    end

    #! === Server List API === !#

    SERVER_LIST_ENDPOINT = "https://gsh.w3dhub.com"
    SERVER_LIST_CONNECTION = Excon.new(SERVER_LIST_ENDPOINT, persistent: true, connect_timeout: 15)
    # Method: GET
    # FORMAT: JSON

    # /listings/getAll/v2?statusLevel=#{0-2}
    # statusLevel = 0 returns:
    #   id, game, address, port, and region
    # statusLevel = 1 returns: (This is the default for the Launcher)
    #   id, game, address, port, region, and status:
    #     name, map, maxplayers, numplayers, started (DateTime), and remaining (RenTime)
    # statusLevel = 2 returns:
    #   id, game, address, port, region and
    #   ...status:
    #     name, map, maxplayers, numplayers, started (DateTime), and remaining (RenTime)
    #   ...teams[]:
    #     id, name, score, kills, deaths
    #   ...players[]:
    #     nick, team (index of teams array), score, kills, deaths
    def self.server_list(level = 1)
      response = SERVER_LIST_CONNECTION.get(
        path: "listings/getAll/v2?statusLevel=#{level}",
        headers: DEFAULT_HEADERS
      )

      if response.status == 200
        data = JSON.parse(response.body, symbolize_names: true)
        return data.map { |hash| ServerListServer.new(hash) }
      end

      pp response
    end

    # /listings/getStatus/v2/:id?statusLevel=#{0-2}
    # statusLevel = 0 returns:
    #   Empty/Blank response, assume 500 or 400 error
    # statusLevel = 1 returns:
    #   name, map, maxplayers, numplayers, started (DateTime), remaining (RenTime)
    # statusLevel = 2 returns:
    #   name, map, maxplayers, numplayers, started (DateTime), remaining (RenTime)
    #   ...teams[]:
    #     id, name, score, kills, deaths
    #   ...players[]:
    #     nick, team (index of teams array), score, kills, deaths
    def self.server_details(id, level)
    end

    # /listings/push/v2/negotiate?negotiateVersion=1
    ##? /listings/push/v2/?id=#{websocket token?}
    ## Websocket server list listener
    def self.server_list_push(id)
    end
  end
end
