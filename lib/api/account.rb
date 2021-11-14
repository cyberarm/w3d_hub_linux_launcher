class W3DHub
  class Api
    class Account
      attr_reader :id, :username, :displayname, :avatar_uri, :user_level, :session_token,
                  :access_token, :access_token_expiry, :refresh_token, :studio_user_level

      def initialize(account, user_details)
        @data = account

        @id                  = @data[:userid]
        @username            = @data[:username]
        @displayname         = @data[:displayname]

        @avatar_uri          = user_details[:"avatar-uri"]

        @user_level          = @data[:userlevel]
        @session_token       = @data[:"session-token"]
        @access_token        = @data[:accessToken]
        @access_token_expiry = Time.at(@data[:accessTokenExpiry])
        @refresh_token       = @data[:refreshToken]

        @studio_user_level   = @data[:"studio-userlevel"] # Dunno?
      end
    end
  end
end
