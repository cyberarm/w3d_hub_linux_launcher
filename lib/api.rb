class W3DHub
  class Api
    USER_AGENT = "Cyberarm's Linux Friendly W3D Hub Launcher v#{W3DHub::VERSION}".freeze
    DEFAULT_HEADERS = [
      ["User-Agent", USER_AGENT]
    ].freeze
    FORM_ENCODED_HEADERS = (
      DEFAULT_HEADERS + [["Content-Type", "application/x-www-form-urlencoded"]]
    ).freeze

    #! === W3D Hub API === !#

    ENDPOINT = "https://secure.w3dhub.com".freeze
    # W3DHUB_API_CONNECTION = Excon.new(ENDPOINT, persistent: true, connect_timeout: 15, tcp_nodelay: true)

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
    def self.refresh_user_login(internet, refresh_token)
      body = "data=#{JSON.dump({refreshToken: refresh_token})}"
      response = internet.post("#{ENDPOINT}/apis/launcher/1/user-login", FORM_ENCODED_HEADERS, body)

      if response.success?#status == 200
        user_data = JSON.parse(response.read, symbolize_names: true)

        return false if user_data[:error]

        body = "data=#{JSON.dump({ id: user_data[:userid] })}"
        user_details = internet.post("#{ENDPOINT}/apis/w3dhub/1/get-user-details", FORM_ENCODED_HEADERS, body)

        if user_details.success?
          user_details_data = JSON.parse(user_details.read, symbolize_names: true)
        end

        return Account.new(user_data, user_details_data)
      else
        false
      end
    end

    # See #user_refresh_token
    def self.user_login(internet, username, password)
      body = "data=#{JSON.dump({username: username, password: password})}"
      response = internet.post("#{ENDPOINT}/apis/launcher/1/user-login", FORM_ENCODED_HEADERS, body)

      if response.success?
        user_data = JSON.parse(response.read, symbolize_names: true)

        return false if user_data[:error]

        body = "data=#{JSON.dump({ id: user_data[:userid] })}"
        user_details = internet.post("#{ENDPOINT}/apis/w3dhub/1/get-user-details", FORM_ENCODED_HEADERS, body)

        if user_details.success?
          user_details_data = JSON.parse(user_details.read, symbolize_names: true)
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
    def self.user_details(internetn, id)
    end

    # /apis/w3dhub/1/get-service-status
    # Service response:
    # {"services":{"authentication":true,"packageDownload":true}}
    def self.service_status(internet)
      response = internet.post("#{ENDPOINT}/apis/w3dhub/1/get-service-status", DEFAULT_HEADERS)

      if response.success?
        ServiceStatus.new(response.read)
      else
        false
      end
    end

    # /apis/launcher/1/get-applications
    # Client sends an Authorization header bearer token which is received from logging in (Optional)
    # Launcher sends an empty data request: data={}
    # Response is a list of applications/games
    def self.applications(internet)
      response = internet.post("#{ENDPOINT}/apis/launcher/1/get-applications", DEFAULT_HEADERS)

      if response.success?
        Applications.new(response.read)
      else
        false
      end
    end

    # /apis/w3dhub/1/get-news
    # Client sends an Authorization header bearer token which is received from logging in (Optional)
    # Client requests news for a specific application/game e.g.: data={"category":"ia"} ("launcher-home" retrieves the weekly hub updates)
    # Response is a JSON hash with a "highlighted" and "news" keys; the "news" one seems to be the desired one
    def self.news(internet, category)
      body = "data=#{JSON.dump({category: category})}"
      response = internet.post("#{ENDPOINT}/apis/w3dhub/1/get-news", FORM_ENCODED_HEADERS, body)

      if response.success?#status == 200
        News.new(response.read)
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
    def self.package(package, &block)
      Cache.fetch_package(package, block)
    end

    #! === Server List API === !#

    SERVER_LIST_ENDPOINT = "https://gsh.w3dhub.com".freeze
    # SERVER_LIST_CONNECTION = Excon.new(SERVER_LIST_ENDPOINT, persistent: true, connect_timeout: 15, tcp_nodelay: true)

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
    def self.server_list(internet, level = 1)
      response = internet.get("#{SERVER_LIST_ENDPOINT}/listings/getAll/v2?statusLevel=#{level}", DEFAULT_HEADERS)

      if response.success?
        data = JSON.parse(response.read, symbolize_names: true)
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
    def self.server_details(internet, id, level)
    end

    # /listings/push/v2/negotiate?negotiateVersion=1
    ##? /listings/push/v2/?id=#{websocket token?}
    ## Websocket server list listener
    def self.server_list_push(id)
    end
  end
end
