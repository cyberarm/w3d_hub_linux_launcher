module W3DHubLauncher
  class Worker
    class Api
      class TestEvent
        attr_reader :title, :image_uri, :timestamp

        def initialize(data)
          @title = data["name"]
          # @title = data["title"]
          @image_uri = data["image"]
          # @app_id = data["server"]
          # @start_time = Time.parse(data["starttime"]).localtime
          # @end_time = Time.parse(data["endtime"]).localtime
          @timestamp = Time.parse(data["dateTime"], in: "UTC").localtime
        end
      end
    end
  end
end
