require "socket"

ICMPHeader = Data.define(:type, :code, :checksum, :_ping_id, :_sequence_id, :data)

ICMP_ECHOREPLY = 0 # Echo reply
ICMP_ECHO      = 8 # Echo request
ICMP_SUBCODE   = 0

# Perform a checksum on the message.  This is the sum of all the short
# words and it folds the high order bits into the low order bits.
#
def checksum(msg)
  length    = msg.length
  num_short = length / 2
  check     = 0

  msg.unpack("n#{num_short}").each do |short|
    check += short
  end

  if (length % 2).positive?
    check += msg[length-1, 1].unpack1("C") << 8
  end

  check = (check >> 16) + (check & 0xffff)
  ~((check >> 16) + check) & 0xffff
end

ip_address = "127.0.0.1" # "example.com" # "timecrafters.org" #
@ping_id = 92_459_064_892 & 0xffff
@sequence = 1 % 65_536
data = ""
data_size = 56
data_size.times { |n| data << (n % 256).chr }

check = 0
packer = "C2 n3 A" << data_size.to_s
message = [ICMP_ECHO, ICMP_SUBCODE, check, @ping_id, @sequence, data].pack(packer)
check = checksum(message)
message = [ICMP_ECHO, ICMP_SUBCODE, check, @ping_id, @sequence, data].pack(packer)
message_header = ICMPHeader.new(*[ICMP_ECHO, ICMP_SUBCODE, check, @ping_id, @sequence, data])
socket = Socket.new(Socket::AF_INET, Socket::SOCK_DGRAM, Socket::IPPROTO_ICMP)
socket.send(message, 0, Socket.pack_sockaddr_in(0, ip_address))
s = Time.now
loop do
  data, _addrinfo = socket.recvfrom(1500)
  pp [message, data]
  header = ICMPHeader.new(*data.unpack("C2 n3 A*"))
  pp [message_header, header]
  # reply_type = data[20, 2].unpack1("C2")
  # pp reply_type

  ping_id = header._ping_id
  sequence = header._sequence_id

  case header.type
  when ICMP_ECHOREPLY
    puts "ECHOREPLY"
  end

  pp [@ping_id, ping_id]
  pp [@sequence, sequence]

  if ping_id == @ping_id && sequence == @sequence && reply_type == ICMP_ECHOREPLY
    puts "PING OKAY: #{Time.now - s}s"
    break
  end

  break
end
