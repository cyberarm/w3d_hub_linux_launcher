module CyberarmEngine
  class GuiState < CyberarmEngine::GameState
    def menu(host_element, items:, width: 200)
      container = CyberarmEngine::Element::Stack.new(
        parent: host_element.parent,
        width: width,
        theme: W3DHub::THEME,
        border_color: 0xff_000000,
        border_thickness: 1
      )

      container.instance_variable_set(:"@__menu", host_element)

      container.define_singleton_method(:recalculate_menu) do
        @x = @__menu.x
        @y = @__menu.y + @__menu.height

        @y = @__menu.y - height if @y + height > window.height
      end

      def container.recalculate
        super

        recalculate_menu
      end

      items.each do |item|
        btn = CyberarmEngine::Element::Button.new(
          item[:label],
          {
            parent: container,
            width: 1.0,
            text_align: :left,
            theme: W3DHub::THEME,
            border_thickness: 0,
            margin: 0
          },
          proc do
            item[:block]&.call
          end
        )
        container.add(btn)
      end

      container.recalculate
      container.recalculate
      container.recalculate

      show_menu(container)
    end
  end
end
