require "socket"
require "openssl"
require "ircparser"

require_relative "irc_profile"

class W3DHub
  class Asterisk
    class IRCClient
      class SSL
        def self.default_context
          verify_peer_and_hostname
        end

        def self.verify_peer_and_hostname
          verify_peer.tap do |context|
            context.verify_hostname = true
          end
        end

        def self.verify_peer
          no_verify.tap do |context|
            context.verify_mode = OpenSSL::SSL::VERIFY_PEER
            context.cert_store = OpenSSL::X509::Store.new.tap(&:set_default_paths)
          end
        end

        def self.verify_hostname_only
          no_verify.tap do |context|
            context.verify_hostname = true
          end
        end

        def self.no_verify
          OpenSSL::SSL::SSLContext.new
        end
      end

      attr_reader :status

      def initialize(irc_profile = nil)
        @irc_profile = irc_profile

        socket = dial(
          @irc_profile.server_hostname,
          @irc_profile.server_port,
          ssl_context: irc_profile.server_ssl ? irc_profile.server_verify_ssl ? SSL.default_context : SSL.no_verify : false
        )

        authenticate_with_brenbot!(socket)
      ensure
        socket&.close
      end

      def dial(hostname, port = 6697, local_host: nil, local_port: nil, ssl_context: SSL.default_context)
        Socket.tcp(hostname, port, local_host, local_port).then do |socket|
          if ssl_context
            ssl_context = SSL.send(ssl_context) if ssl_context.is_a? Symbol

            OpenSSL::SSL::SSLSocket.new(socket, ssl_context).tap do |ssl_socket|
              ssl_socket.hostname = hostname
              ssl_socket.connect
            end
          else
            socket
          end
        end
      end

      def authenticate_with_brenbot!(socket)
        pp @irc_profile, "#{@irc_profile.nickname}!#{@irc_profile.username.split("/").first}"
        # exit

        pass = IRCParser::Message.new(command: "PASS", parameters: [@irc_profile.password])
        user = IRCParser::Message.new(command: "USER", parameters: [@irc_profile.username, "0", "*", ":#{@irc_profile.nickname}"])
        nick = IRCParser::Message.new(command: "NICK", parameters: [@irc_profile.nickname])

        socket.puts(pass)
        socket.puts(user)
        socket.puts(nick)

        pp socket
        socket.flush

        until socket.closed?
          raw = socket.gets
          next if raw.to_s.empty?

          msg = IRCParser::Message.parse(raw)

          if msg.command == "PING"
            pong = IRCParser::Message.new(command: "PONG", parameters: [msg.parameters.first.sub("\r\n", "")])
            socket.puts("#{pong}")
            socket.flush
          elsif msg.command == "001" && msg.parameters.join.include?("#{@irc_profile.nickname}!#{@irc_profile.username.split("/").first}")
            pm = IRCParser::Message.new(command: "PRIVMSG", parameters: [@irc_profile.server_bot, "!auth #{@irc_profile.bot_auth_username} password"])
            socket.puts(pm)

            quit = IRCParser::Message.new(command: "QUIT", parameters: ["Quiting from an Asterisk"])
            socket.puts(quit)
            socket.flush

            socket.close
          end
        end
      end
    end
  end
end

W3DHub::Asterisk::IRCClient.new
