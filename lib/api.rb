class W3DHub
  class Api

    # Set Excon default CA file if found
    if (ca_file = W3DHub.ca_bundle_path)
      Excon.defaults[:ssl_ca_file] = ca_file
    end

    LOG_TAG = "W3DHub::Api".freeze

    API_TIMEOUT = 30 # seconds
    USER_AGENT = "Cyberarm's Linux Friendly W3D Hub Launcher v#{W3DHub::VERSION}".freeze
    DEFAULT_HEADERS = [
      ["user-agent", USER_AGENT],
      ["accept", "application/json"]
    ].freeze
    FORM_ENCODED_HEADERS = [
      ["user-agent", USER_AGENT],
      ["accept", "application/json"],
      ["content-type", "application/x-www-form-urlencoded"]
    ].freeze

    def self.on_thread(method, *args, &callback)
      BackgroundWorker.foreground_job(-> { Api.send(method, *args) }, callback)
    end

    class Response
      def initialize(error: nil, status: -1, body: "")
        @status = status
        @body = body
        @error = error
      end

      def success?
        @status == 200
      end

      def status
        @status
      end

      def body
        @body
      end

      def error
        @error
      end
    end

    #! === W3D Hub API === !#
    W3DHUB_API_ENDPOINT = "https://secure.w3dhub.com".freeze # "https://example.com" # "http://127.0.0.1:9292".freeze #
    ALT_W3DHUB_API_ENDPOINT = "https://w3dhub-api.w3d.cyberarm.dev".freeze # "https://secure.w3dhub.com".freeze # "https://example.com" # "http://127.0.0.1:9292".freeze #

    def self.async_http(method, url, headers = DEFAULT_HEADERS, body = nil, backend = :w3dhub)
      case backend
      when :w3dhub
        endpoint   = W3DHUB_API_ENDPOINT
      when :alt_w3dhub
        endpoint   = ALT_W3DHUB_API_ENDPOINT
      when :gsh
        endpoint   = SERVER_LIST_ENDPOINT
      end

      url = "#{endpoint}#{url}" unless url.start_with?("http")

      logger.debug(LOG_TAG) { "Fetching #{method.to_s.upcase} \"#{url}\"..." }

      # Inject Authorization header if account data is populated
      if Store.account
        logger.debug(LOG_TAG) { "  Injecting Authorization header..." }
        headers = headers.dup
        headers << ["authorization", "Bearer #{Store.account.access_token}"]
      end

      Sync do
        begin
         response = Async::HTTP::Internet.send(method, url, headers, body)

          Response.new(status: response.status, body: response.read)
        rescue Async::TimeoutError => e
          logger.error(LOG_TAG) { "Connection to \"#{url}\" timed out after: #{API_TIMEOUT} seconds" }

          Response.new(error: e)
        rescue StandardError => e
          logger.error(LOG_TAG) { "Connection to \"#{url}\" errored:" }
          logger.error(LOG_TAG) { e }

          Response.new(error: e)
        ensure
          response&.close
        end
      end
    end

    def self.post(url, headers = DEFAULT_HEADERS, body = nil, backend = :w3dhub)
      async_http(:post, url, headers, body, backend)
    end

    def self.get(url, headers = DEFAULT_HEADERS, body = nil, backend = :w3dhub)
      async_http(:get, url, headers, body, backend)
    end

    # Api.get but handles any URL instead of known hosts
    def self.fetch(url, headers = DEFAULT_HEADERS, body = nil, backend = nil)
      async_http(:get, url, headers, body, backend)
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
    def self.refresh_user_login(refresh_token, backend = :w3dhub)
      body = URI.encode_www_form("data": JSON.dump({refreshToken: refresh_token}))
      response = post("/apis/launcher/1/user-login", FORM_ENCODED_HEADERS, body, backend)

      if response.status == 200
        user_data = JSON.parse(response.body, symbolize_names: true)

        return false if user_data[:error]

        user_details_data = user_details(user_data[:userid]) || {}

        Account.new(user_data, user_details_data)
      else
        logger.error(LOG_TAG) { "Failed to fetch refresh user login:" }
        logger.error(LOG_TAG) { response }
        false
      end
    end

    # See #user_refresh_token
    def self.user_login(username, password, backend = :w3dhub)
      body = URI.encode_www_form("data": JSON.dump({username: username, password: password}))
      response = post("/apis/launcher/1/user-login", FORM_ENCODED_HEADERS, body, backend)

      if response.status == 200
        user_data = JSON.parse(response.body, symbolize_names: true)

        return false if user_data[:error]

        user_details_data = user_details(user_data[:userid]) || {}

        Account.new(user_data, user_details_data)
      else
        logger.error(LOG_TAG) { "Failed to fetch user login:" }
        logger.error(LOG_TAG) { response }
        false
      end
    end

    # /apis/w3dhub/1/get-user-details
    #
    # Response: avatar-uri (Image download uri), id, username
    def self.user_details(id, backend = :w3dhub)
      body = URI.encode_www_form("data": JSON.dump({ id: id }))
      user_details = post("/apis/w3dhub/1/get-user-details", FORM_ENCODED_HEADERS, body, backend)

      if user_details.status == 200
        JSON.parse(user_details.body, symbolize_names: true)
      else
        logger.error(LOG_TAG) { "Failed to fetch user details:" }
        logger.error(LOG_TAG) { user_details }
        false
      end
    end

    # /apis/w3dhub/1/get-service-status
    # Service response:
    # {"services":{"authentication":true,"packageDownload":true}}
    def self.service_status(backend = :w3dhub)
      response = post("/apis/w3dhub/1/get-service-status", DEFAULT_HEADERS, nil, backend)

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
    def self.applications(backend = :w3dhub)
      response = post("/apis/launcher/1/get-applications", DEFAULT_HEADERS, nil, backend)

      if response.status == 200
        Applications.new(response.body, backend)
      else
        logger.error(LOG_TAG) { "Failed to fetch applications list:" }
        logger.error(LOG_TAG) { response }
        false
      end
    end

    # Populate applications list from primary and alternate backends
    # (alternate only has latest public builds of _most_ games)
    def self._applications
      applications_primary = Store.account ? Api.applications(:w3dhub) : false
      applications_alternate = Api.applications(:alt_w3dhub)

      # Fail if we fail to fetch applications list from either backend
      return false unless applications_primary || applications_alternate

      return applications_alternate unless applications_primary

      # Merge the two app lists together
      apps = applications_alternate
      if applications_primary
        applications_primary.games.each do |game|
          # Check if game exists in alternate list
          _game = apps.games.find { |g| g.id == game.id }
          unless _game
            apps.games << game

            # App didn't exist in alternates list
            # comparing channels isn't useful
            next
          end

          # If it does, check that all of its channels also exist in alternate list
          # and that the primary versions are the same as the alternates list
          game.channels.each do |channel|
            _channel = _game.channels.find { |c| c.id == channel.id }

            unless _channel
              _game.channels << channel

              # App didn't have channel in alternates list
              # comparing channel isn't useful
              next
            end

            # If channel versions and access levels match then all's well
            if channel.current_version == _channel.current_version &&
              channel.user_level == _channel.user_level

              # All's Well!
              next
            end

            # If the access levels don't match then overwrite alternate's channel with primary's channel
            if channel.user_level != _channel.user_level
              # Replace alternate's channel with primary's channel
              _game.channels[_game.channels.index(_channel)] = channel

              # Replaced, continue.
              next
            end

            # If versions don't match then pick whichever one is higher
            if Gem::Version.new(channel.current_version) > Gem::Version.new(_channel.current_version)
              # Replace alternate's channel with primary's channel
              _game.channels[_game.channels.index(_channel)] = channel
            else
              # Do nothing, alternate backend version is greater.
            end
          end
        end
      end

      apps
    end

    # /apis/w3dhub/1/get-news
    # Client sends an Authorization header bearer token which is received from logging in (Optional)
    # Client requests news for a specific application/game e.g.: data={"category":"ia"} ("launcher-home" retrieves the weekly hub updates)
    # Response is a JSON hash with a "highlighted" and "news" keys; the "news" one seems to be the desired one
    def self.news(category, backend = :w3dhub)
      body = URI.encode_www_form("data": JSON.dump({category: category}))
      response = post("/apis/w3dhub/1/get-news", FORM_ENCODED_HEADERS, body, backend)

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
    def self.package_details(packages, backend = :w3dhub)
      body = URI.encode_www_form("data": JSON.dump({ packages: packages }))
      response = post("/apis/launcher/1/get-package-details", FORM_ENCODED_HEADERS, body, backend)

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
    def self.events(app_id, backend = :w3dhub)
      body = URI.encode_www_form("data": JSON.dump({ serverPath: app_id }))
      response = post("/apis/w3dhub/1/get-server-events", FORM_ENCODED_HEADERS, body, backend)

      if response.status == 200
        array = JSON.parse(response.body, symbolize_names: true)
        array.map { |e| Event.new(e) }
      else
        false
      end
    end

    #! === Server List API === !#

    # SERVER_LIST_ENDPOINT = "https://gsh.w3dhub.com".freeze
    SERVER_LIST_ENDPOINT = "https://gsh.w3d.cyberarm.dev".freeze
    # SERVER_LIST_ENDPOINT = "http://127.0.0.1:9292".freeze

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
    def self.server_list(level = 1, backend = :gsh)
      response = get("/listings/getAll/v2?statusLevel=#{level}", DEFAULT_HEADERS, nil, backend)

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
    def self.server_details(id, level, backend = :gsh)
      return false unless id && level

      response = get("/listings/getStatus/v2/#{id}?statusLevel=#{level}", DEFAULT_HEADERS, nil, backend)

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
