class W3DHub
  class Asterisk
    class Game
      attr_accessor :title, :path

      def initialize(hash = nil)
        return unless hash

        @title = hash[:title]
        @path = hash[:path]
      end

      def to_json(options)
        {
          title: @title,
          path: @path
        }.to_json(options)
      end
    end
  end
end
