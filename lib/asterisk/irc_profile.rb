class W3DHub
  class Asterisk
    class IRCProfile
      attr_accessor :name, :nickname, :password, :server_hostname, :server_port, :server_bot

      def initialize(hash = nil)
        return unless hash

        @name = hash[:name]
        @nickname = hash[:nickname]
        @password = hash[:password]
        @server_hostname = hash[:server_hostname]
        @server_port = hash[:server_port]
        @server_bot = hash[:server_bot]
      end

      def to_json(options)
        {
          name: @name,
          nickname: @nickname,
          password: @password,
          server_hostname: @server_hostname,
          server_port: @server_port,
          server_bot: @server_bot
        }.to_json(options)
      end
    end
  end
end
