class W3DHub
  class Api
    class Event
      def initialize(data)
        @data = data
      end

      def server
        @data[:server]
      end

      def title
        @data[:title]
      end

      def start_time
        @start_time ||= Time.parse(@data[:starttime]).localtime
      end

      def end_time
        @end_time ||= Time.parse(@data[:endtime]).localtime
      end

      def date_time
        @data[:dateTime]
      end

      def image
        @data[:image]
      end
    end
  end
end
