require "socket"
require "openssl"
require "ircparser"

require_relative "irc_profile"

class W3DHub
  class Asterisk
    class IRCClient
      TAG = "IRCClient"

      class SSL
        # Detect system CA bundle path for SSL verification
        def self.ca_bundle_path
          [
            '/etc/ssl/certs/ca-certificates.crt',      # Debian/Ubuntu
            '/etc/pki/tls/certs/ca-bundle.crt',        # RHEL/Fedora/CentOS
            '/etc/ssl/ca-bundle.pem'                   # Some other distros
          ].find { |path| File.exist?(path) }
        end

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
            context.cert_store = OpenSSL::X509::Store.new
            ca_file = ca_bundle_path
            if ca_file
              context.cert_store.add_file(ca_file)
            else
              context.cert_store.set_default_paths
            end
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

      def initialize(irc_profile)
        @irc_profile = irc_profile

        ssl_context = false

        if irc_profile.server_ssl
          ssl_context = irc_profile.server_verify_ssl ? SSL.default_context : SSL.no_verify
        end

        socket = dial(
          @irc_profile.server_hostname,
          @irc_profile.server_port,
          ssl_context: ssl_context
        )

        authenticate_with_brenbot!(socket)
      ensure
        close_socket(socket)
      end

      def dial(hostname, port = 6697, local_host: nil, local_port: nil, ssl_context: SSL.default_context)
        Socket.tcp(hostname, port, local_host, local_port).then do |socket|
          if ssl_context
            @ssl_socket = true

            ssl_context = SSL.send(ssl_context) if ssl_context.is_a?(Symbol)

            OpenSSL::SSL::SSLSocket.new(socket, ssl_context).tap do |ssl_socket|
              ssl_socket.hostname = hostname
              ssl_socket.connect
            end
          else
            socket
          end
        end
      rescue StandardError => e
        logger.error(TAG) { e }
        logger.error(TAG) { e.backtrace }
      end

      def authenticate_with_brenbot!(socket)
        username = @irc_profile.username.empty? ? @irc_profile.nickname : @irc_profile.username

        pass = IRCParser::Message.new(command: "PASS", parameters: [Base64.strict_decode64(@irc_profile.password)]) unless @irc_profile.password.empty?
        user = IRCParser::Message.new(command: "USER", parameters: [username, "0", "*", ":#{@irc_profile.nickname}"])
        nick = IRCParser::Message.new(command: "NICK", parameters: [@irc_profile.nickname])

        socket.puts(pass)
        socket.puts(user)
        socket.puts(nick)

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
            pm = IRCParser::Message.new(command: "PRIVMSG", parameters: [@irc_profile.bot_username, "!auth #{@irc_profile.bot_auth_username} #{Base64.strict_decode64(@irc_profile.bot_auth_password)}"])
            socket.puts(pm)

            quit = IRCParser::Message.new(command: "QUIT", parameters: ["Quiting from an Asterisk"])
            socket.puts(quit)
            socket.flush

            sleep 15
            close_socket(socket)
          elsif msg.command == "ERROR"
            close_socket(socket)
          end
        end
      end

      def close_socket(socket)
        return unless socket

        if @ssl_socket
          socket.sync_close = true
          socket.sysclose
        else
          socket.close
        end
      end
    end
  end
end
