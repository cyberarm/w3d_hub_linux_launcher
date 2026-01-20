class W3DHub
  class PingManager
    Container = Struct.new(:pinger, :last_ping_time_ms)
    PING_INTERVAL = 60_000

    def initialize
      @containers = {}
      @addresses = []
    end

    def monitor(task)
      task.async do |subtask|
        while BackgroundWorker.alive?
          # activate new addresses
          @addresses.each do |address|
            @containers[address] ||= Container.new(Ping.new(address: address), -PING_INTERVAL * 2)
          end

          # cleanup old addresses
          @containers.each_key do |key|
            @containers.delete(key) unless @addresses.find { |a| a == key }
          end

          # ping the pingers
          @containers.each_value do |container|
            next unless Gosu.milliseconds - container.last_ping_time_ms >= PING_INTERVAL

            container.last_ping_time_ms = Gosu.milliseconds

            subtask.async do
              container.pinger.ping
              pp [container.pinger.address, container.pinger.average_ping]
            end
          end

          sleep 0.001
        end
      end
    end

    def add_address(address)
      @addresses << address
      @addresses.uniq!
    end

    def ping_for(address)
      @containers[address]&.pinger&.average_ping&.round || -1
    end

    def remove_address(address)
      @addresses.delete(address)
    end
  end
end
