class W3DHub
  class ApplicationManager
    class Importer < Task
      def initialize(app_id, channel, path = nil)
        super(app_id, channel)

        @path = path
      end
    end
  end
end
