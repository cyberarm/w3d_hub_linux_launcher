class W3DHub
  class Asterisk
    class ServerProfile
      attr_accessor :name, :nickname, :password,
                    :game_title, :launch_arguments,
                    :server_profile, :server_hostname, :server_port,
                    :irc_profile

      def initialize(hash = nil)
        return unless hash

        @name = hash[:name]
        @nickname = hash[:nickname]
        @password = hash[:password]
        @server_profile = hash[:server_profile]
        @server_hostname = hash[:server_hostname]
        @server_port = hash[:server_port]
        @game_title = hash[:game_title]
        @launch_arguments = hash[:launch_arguments]
        @irc_profile = hash[:irc_profile]
      end

      def to_json(options)
        {
          name: @name,
          nickname: @nickname,
          password: @password,
          server_profile: @server_profile,
          server_hostname: @server_hostname,
          server_port: @server_port,
          game_title: @game_title,
          launch_arguments: @launch_arguments,
          irc_profile: @irc_profile
        }.to_json(options)
      end
    end
  end
end
