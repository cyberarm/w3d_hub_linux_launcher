class W3DHub
  class Asterisk
    class IRCProfile
      attr_accessor :name,
                    :username, :nickname, :password,
                    :server_hostname, :server_port, :server_ssl, :server_verify_ssl,
                    :bot_username, :bot_auth_username, :bot_auth_password

      def initialize(hash = nil)
        return unless hash

        @name = hash[:name]
        @username = hash[:username] || hash[:nickname]
        @nickname = hash[:nickname]
        @password = hash[:password]
        @server_hostname = hash[:server_hostname]
        @server_port = hash[:server_port]
        @server_ssl = hash[:server_ssl]
        @server_verify_ssl = hash[:server_verify_ssl]
        @bot_username = hash[:bot_username]
        @bot_auth_username = hash[:bot_auth_username]
        @bot_auth_password = hash[:bot_auth_password]
      end

      def to_json(options)
        {
          name: @name,
          username: @username,
          nickname: @nickname,
          password: @password,
          server_hostname: @server_hostname,
          server_port: @server_port,
          server_ssl: @server_ssl,
          server_verify_ssl: @server_verify_ssl,
          bot_username: @bot_username,
          bot_auth_username: @bot_auth_username,
          bot_auth_password: @bot_auth_password
        }.to_json(options)
      end
    end
  end
end
