require "async"
require "socket"
require "securerandom"

class W3DHub
  class Ping
    ICMPHeader = Data.define(:type, :code, :checksum, :_ping_id, :_sequence_id, :data)
    EchoRequest = Struct.new(:ping_id, :sequence_id, :data, :time, :timed_out)

    ICMP_ECHOREPLY = 0
    ICMP_ECHO      = 8
    ICMP_SUBCODE   = 0

    BIT_PACKER = "C2 n3 A*".freeze
    MINIMUM_INTERVAL = 250 # ms # intervals below 200ms are considered rude and may be dropped due to flooding.
    ECHO_REQUEST_HISTORY = 30 # 100 # keep the last n requests

    attr_reader :address

    def initialize(address:, count: 10, ttl: 120, interval: 1_000, data: nil)
      @address = address
      @count = count
      @ttl = ttl
      @interval = interval.to_i < MINIMUM_INTERVAL ? MINIMUM_INTERVAL : interval # ms
      @data = data

      # circular buffer
      @echo_requests = Array.new(ECHO_REQUEST_HISTORY) { EchoRequest.new(-1, -1, "", nil, false) }
      @echo_requests_index = 0

      # NOTE: The PING_ID _might_ be overruled by the kernel and should not be used
      #       to check that any received echo replies are ours.
      #
      #       Sequence ID and Data appear to be unmodified.
      @ping_id = SecureRandom.hex.to_i(16) & 0xffff
      @sequence_id = SecureRandom.hex.to_i(16) & 0xffff

      addresses = Addrinfo.getaddrinfo(@address, nil, Socket::AF_INET, :DGRAM)
      raise "NO ADDRESSES!" if addresses.empty?

      @socket_address = addresses.sample.to_sockaddr

      @socket = Socket.new(Socket::AF_INET, Socket::SOCK_DGRAM, Socket::IPPROTO_ICMP)
      @socket.setsockopt(Socket::SOL_SOCKET, Socket::IP_TTL, @ttl)
    end

    # Perform a checksum on the message.  This is the sum of all the short
    # words and it folds the high order bits into the low order bits.
    def message_checksum(message)
      length    = message.length
      num_short = length / 2
      check     = 0

      message.unpack("n#{num_short}").each do |short|
        check += short
      end

      check += message[length - 1, 1].unpack1("C") << 8 if (length % 2).positive?

      check = (check >> 16) + (check & 0xffff)
      ~((check >> 16) + check) & 0xffff
    end

    def random_data
      SecureRandom.hex
    end

    def monotonic_time
      Process.clock_gettime(:CLOCK_MONOTONIC, :millisecond)
    end

    def verified?(message)
      data = message.unpack(BIT_PACKER)
      checksum = data[2]

      # set checksum in message to 0
      data[2] = 0

      checksum == message_checksum(data.pack(BIT_PACKER))
    end

    def request_complete?(request)
      request.timed_out || !request.time.nil?
    end

    def packet_loss
      completed_requests = @echo_requests.select { |r| request_complete?(r) }
      failed_requests = completed_requests.select(&:timed_out)

      # 0% packet loss 😎
      return 0.0 if failed_requests.empty?

      # 100% packet loss
      return 1.0 if failed_requests.size == completed_requests.size

      failed_requests.size / completed_requests.size.to_f
    end

    def average_ping
      times = @echo_requests.select { |r| request_complete?(r) && !r.timed_out }.map(&:time)

      return -1 unless times.size.positive?

      times.sum.to_f / times.size
    end

    # returns true if any echo requests have completed (reply received or timed out) and packet loss is less than 30%
    def okay?
      completed_requests = @echo_requests.select { |r| request_complete?(r) }.size

      completed_requests.positive? && packet_loss < 0.3
    end

    def ping(count = @count)
      return if count <= 0

      Async do |task|
        @count.times do
          task.Async do |subtask|
            @sequence_id = (@sequence_id + 1) % 0xffff
            data = @data || random_data

            checksum = 0
            message = [ICMP_ECHO, ICMP_SUBCODE, checksum, @ping_id, @sequence_id, data].pack(BIT_PACKER)
            checksum = message_checksum(message)
            message = [ICMP_ECHO, ICMP_SUBCODE, checksum, @ping_id, @sequence_id, data].pack(BIT_PACKER)

            @socket.send(message, 0, @socket_address)

            s = monotonic_time
            request = @echo_requests[@echo_requests_index]
            request.ping_id = @ping_id
            request.sequence_id = @sequence_id
            request.data = data
            request.time = nil
            request.timed_out = false
            @echo_requests_index = (@echo_requests_index + 1) % ECHO_REQUEST_HISTORY

            subtask.with_timeout(2) do
              loop do
                data, _addrinfo = @socket.recvfrom(1500)

                # ignore corruption
                next unless verified?(data)

                header = ICMPHeader.new(*data.unpack(BIT_PACKER))

                if header.type == ICMP_ECHOREPLY && header._sequence_id == request.sequence_id && header.data == request.data
                  duration = monotonic_time - s
                  request.time = duration

                  break
                end
              end
            rescue Async::TimeoutError
              request.timed_out = true
            end
          end

          # Don't send out pings in a flood, it's considered rude.
          sleep @interval / 1000.0
        end
      end
    end
  end
end
