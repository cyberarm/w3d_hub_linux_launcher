class W3DHub
  class Api
    LOG_TAG = "W3DHub::Api".freeze

    API_TIMEOUT = 10 # seconds
    USER_AGENT = "Cyberarm's Linux Friendly W3D Hub Launcher v#{W3DHub::VERSION}".freeze
    DEFAULT_HEADERS = {
      "User-Agent": USER_AGENT,
      "Accept": "application/json"
    }.freeze
    FORM_ENCODED_HEADERS = {
      "User-Agent": USER_AGENT,
      "Accept": "application/json",
      "Content-Type": "application/x-www-form-urlencoded"
    }.freeze

    def self.on_thread(method, *args, &callback)
      BackgroundWorker.foreground_job(-> { Api.send(method, *args) }, callback)
    end

    class DummyResponse
      def initialize(error)
        @error = error
      end

      def success?
        false
      end

      def status
        -1
      end

      def body
        ""
      end

      def error
        @error
      end
    end

    #! === W3D Hub API === !#

    ENDPOINT = "https://secure.w3dhub.com".freeze
    API_CONNECTION = Excon.new(ENDPOINT, persistent: true)

    def self.excon(method, url, headers = DEFAULT_HEADERS, body = nil, api = :api)
      logger.debug(LOG_TAG) { "Fetching #{method.to_s.upcase} \"#{url}\"..." }

      # Inject Authorization header if account data is populated
      if Store.account
        logger.debug(LOG_TAG) { "  Injecting Authorization header..." }
        headers = headers.dup
        headers["Authorization"] = "Bearer #{Store.account.access_token}"
      end

      connection = api == :api ? API_CONNECTION : GSH_CONNECTION
      endpoint = api == :api ? ENDPOINT : SERVER_LIST_ENDPOINT

      begin
        connection.send(
          method,
          path: url.sub(endpoint, ""),
          headers: headers,
          body: body,
          nonblock: true,
          tcp_nodelay: true,
          write_timeout: API_TIMEOUT,
          read_timeout: API_TIMEOUT,
          connect_timeout: API_TIMEOUT,
          idempotent: true,
          retry_limit: 3,
          retry_interval: 1,
          retry_errors: [Excon::Error::Socket, Excon::Error::HTTPStatus] # Don't retry on timeout
        )
      rescue Excon::Errors::Timeout => e
        logger.error(LOG_TAG) { "Connection to \"#{url}\" timed out after: #{API_TIMEOUT} seconds" }

        DummyResponse.new(e)
      rescue Excon::Error => e
        logger.error(LOG_TAG) { "Connection to \"#{url}\" errored:" }
        logger.error(LOG_TAG) { e }

        DummyResponse.new(e)
      end
    end

    def self.post(url, headers = DEFAULT_HEADERS, body = nil, api = :api)
      excon(:post, url, headers, body)
    end

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
      body = "data=#{JSON.dump({refreshToken: refresh_token})}"
      response = post("#{ENDPOINT}/apis/launcher/1/user-login", FORM_ENCODED_HEADERS, body)

      if response.status == 200
        user_data = JSON.parse(response.body, symbolize_names: true)

        return false if user_data[:error]

        body = "data=#{JSON.dump({ id: user_data[:userid] })}"
        user_details = post("#{ENDPOINT}/apis/w3dhub/1/get-user-details", FORM_ENCODED_HEADERS, body)

        if user_details.status == 200
          user_details_data = JSON.parse(user_details.body, symbolize_names: true)
        else
          logger.error(LOG_TAG) { "Failed to fetch refresh user details:" }
          logger.error(LOG_TAG) { user_details }
        end

        Account.new(user_data, user_details_data)
      else
        logger.error(LOG_TAG) { "Failed to fetch refresh user login:" }
        logger.error(LOG_TAG) { response }
        false
      end
    end

    # See #user_refresh_token
    def self.user_login(username, password)
      body = "data=#{JSON.dump({username: username, password: password})}"
      response = post("#{ENDPOINT}/apis/launcher/1/user-login", FORM_ENCODED_HEADERS, body)

      if response.status == 200
        user_data = JSON.parse(response.body, symbolize_names: true)

        return false if user_data[:error]

        body = "data=#{JSON.dump({ id: user_data[:userid] })}"
        user_details = post("#{ENDPOINT}/apis/w3dhub/1/get-user-details", FORM_ENCODED_HEADERS, body)

        if user_details.status == 200
          user_details_data = JSON.parse(user_details.body, symbolize_names: true)
        else
          logger.error(LOG_TAG) { "Failed to fetch user details:" }
          logger.error(LOG_TAG) { user_details }
        end

        Account.new(user_data, user_details_data)
      else
        logger.error(LOG_TAG) { "Failed to fetch user login:" }
        logger.error(LOG_TAG) { response }
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
      response = post("#{ENDPOINT}/apis/w3dhub/1/get-service-status", DEFAULT_HEADERS)

      if response.status == 200
        ServiceStatus.new(response.body)
      else
        logger.error(LOG_TAG) { "Failed to fetch service status:" }
        logger.error(LOG_TAG) { response }
        false
      end
    end

    # /apis/launcher/1/get-applications
    # Client sends an Authorization header bearer token which is received from logging in (Optional)
    # Launcher sends an empty data request: data={}
    # Response is a list of applications/games
    def self.applications
      response = post("#{ENDPOINT}/apis/launcher/1/get-applications")

      if response.status == 200
        Applications.new(response.body)
      else
        logger.error(LOG_TAG) { "Failed to fetch applications list:" }
        logger.error(LOG_TAG) { response }
        false
      end
    end

    # /apis/w3dhub/1/get-news
    # Client sends an Authorization header bearer token which is received from logging in (Optional)
    # Client requests news for a specific application/game e.g.: data={"category":"ia"} ("launcher-home" retrieves the weekly hub updates)
    # Response is a JSON hash with a "highlighted" and "news" keys; the "news" one seems to be the desired one
    def self.news(category)
      body = "data=#{JSON.dump({category: category})}"
      response = post("#{ENDPOINT}/apis/w3dhub/1/get-news", FORM_ENCODED_HEADERS, body)

      if response.status == 200
        News.new(response.body)
      else
        logger.error(LOG_TAG) { "Failed to fetch news for:" }
        logger.error(LOG_TAG) { category }
        logger.error(LOG_TAG) { response }
        false
      end
    end

    # Downloading games

    # /apis/launcher/1/get-package-details
    # client requests package details: data={"packages":[{"category":"games","name":"apb.ico","subcategory":"apb","version":""}]}
    def self.package_details(packages)
      body = URI.encode_www_form("data": JSON.dump({ packages: packages }))
      response = post("#{ENDPOINT}/apis/launcher/1/get-package-details", FORM_ENCODED_HEADERS, body)

      if response.status == 200
        hash = JSON.parse(response.body, symbolize_names: true)

        hash[:packages].map { |pkg| Package.new(pkg) }
      else
        logger.error(LOG_TAG) { "Failed to fetch package details for:" }
        logger.error(LOG_TAG) { packages }
        logger.error(LOG_TAG) { response }
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

    # /apis/w3dhub/1/get-events
    #
    # clients requests events: data={"serverPath":"apb"}
    def self.events(app_id)
      body = URI.encode_www_form("data": JSON.dump({ serverPath: app_id }))
      response = post("#{ENDPOINT}/apis/w3dhub/1/get-server-events", FORM_ENCODED_HEADERS, body)

      if response.status == 200
        array = JSON.parse(response.body, symbolize_names: true)
        array.map { |e| Event.new(e) }
      else
        false
      end
    end

    #! === Server List API === !#

    SERVER_LIST_ENDPOINT = "https://gsh.w3dhub.com".freeze
    # SERVER_LIST_ENDPOINT = "https://gsh.w3d.cyberarm.dev".freeze
    # SERVER_LIST_ENDPOINT = "http://127.0.0.1:9292".freeze
    GSH_CONNECTION = Excon.new(SERVER_LIST_ENDPOINT, persistent: true)

    def self.get(url, headers = DEFAULT_HEADERS, body = nil, api = :api)
      excon(:get, url, headers, body, api)
    end

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
      response = get("#{SERVER_LIST_ENDPOINT}/listings/getAll/v2?statusLevel=#{level}", DEFAULT_HEADERS, nil, :gsh)

      if response.status == 200
        data = JSON.parse(response.body, symbolize_names: true)
        return data.map { |hash| ServerListServer.new(hash) }
      end

      false
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
      return false unless id && level

      response = get("#{SERVER_LIST_ENDPOINT}/listings/getStatus/v2/#{id}?statusLevel=#{level}", DEFAULT_HEADERS, nil, :gsh)

      if response.status == 200
        hash = JSON.parse(response.body, symbolize_names: true)
        return hash
      end

      false
    end

    # /listings/push/v2/negotiate?negotiateVersion=1
    ##? /listings/push/v2/?id=#{websocket token?}
    ## Websocket server list listener
    def self.server_list_push(id)
    end
  end
end
