class W3DHub
  class Game
    include CyberarmEngine::Common

    MenuItem = Struct.new(:image, :label, :block)
    PlayItem = Struct.new(:label, :block)

    @@games = []
    @@subclasses = []

    attr_reader :slot, :name, :icon, :news_feed, :background_color, :menu_items, :play_items

    def self.inherited(klass)
      super

      @@subclasses << klass
    end

    def self.load_games
      @@subclasses.each do |klass|
        i = klass.new
        i.setup

        @@games << i
      end

      @@games.sort! { |g| g.slot }
    end

    def self.games
      @@games
    end

    def initialize
      @slot = -1

      @name = "???"
      @icon = EMPTY_IMAGE
      @news_feed = "???"
      @background_color = 0xff_ffffff

      @menu_items = []
      @play_items = []
    end

    def set_slot(index)
      @slot = index
    end

    def set_name(name)
      @name = name
    end

    def set_icon(path_or_image)
      @icon = path_or_image.is_a?(Gosu::Image) ? path_or_image : path_or_image.nil? ? EMPTY_IMAGE : get_image(path_or_image)
    end

    def set_news_feed(uri)
      @news_feed = uri
    end

    def set_background_color(color)
      @background_color = color
    end

    def menu_item(path_or_image, label, &block)
      image = path_or_image.is_a?(Gosu::Image) ? path_or_image : path_or_image.nil? ? EMPTY_IMAGE : get_image(path_or_image)

      @menu_items << MenuItem.new(image, label, block)
    end

    def play_item(label, &block)
      @play_items << PlayItem.new(label, block)
    end
  end
end
