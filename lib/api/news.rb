class W3DHub
  class Api
    class News
      attr_reader :items

      def initialize(response)
        @data = JSON.parse(response, symbolize_names: true)

        @items = (@data[:news] && @data[:news].is_a?(Array)) ? @data[:news].map { |item| Item.new(item) } : []
      end

      class Item
        attr_reader :topic_id, :title, :blurb, :image, :uri, :author, :author_uri, :timestamp, :date, :time

        def initialize(hash)
          @data = hash

          @topic_id = Integer(@data[:"topic-id"])
          @title = @data[:title]
          @blurb = @data[:blurb]
          @image = @data[:image].strip
          @uri = @data[:uri].strip
          @author = @data[:author]
          @author_uri = @data[:"author-uri"].strip
          @timestamp = Time.at(Integer(@data[:timestamp]))
          @date = @data[:date]
          @time = @data[:time]
        end
      end
    end
  end
end
