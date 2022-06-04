class W3DHub
  class Asterisk
    class Settings
      attr_accessor :theme, :preload_app, :enable_preload_app, :post_launch_app, :enable_post_launch_app

      def initialize(hash)
        @theme = hash[:theme].to_sym

        @preload_app = hash[:preload_app]
        @enable_preload_app = hash[:enable_preload_app]
        @post_launch_app = hash[:post_launch_app]
        @enable_post_launch_app = hash[:enable_post_launch_app]
      end

      def to_json(options)
        {
          theme: @theme,
          preload_app: @preload_app,
          enable_preload_app: @enable_preload_app,
          post_launch_app: @post_launch_app,
          enable_post_launch_app: @enable_post_launch_app
        }.to_json(options)
      end
    end
  end
end
