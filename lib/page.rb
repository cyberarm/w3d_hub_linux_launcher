class W3DHub
  class Page
    include CyberarmEngine::DSL
    include CyberarmEngine::Common

    attr_reader :menu_bar, :status_bar, :body

    def initialize(host:)
      @host = host
      # @header_bar_label = host.header_bar_label
      # @menu_bar = host.menu_bar
      # @status_bar = host.status_bar
      @body = host.body

      @options = {}
    end

    def options=(options)
      @options = options
    end

    def page(klass, options = {})
      @host.page(klass, options)
    end

    # def header_bar(text)
    #   @header_bar_label.value = text
    # end

    def setup
    end

    def focus
    end

    def blur
    end

    def draw
    end

    def update
    end

    def button_down(id)
    end

    def button_up(id)
    end
  end
end