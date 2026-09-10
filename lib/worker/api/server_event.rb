module W3DHubLauncher
  class Worker
    class Api
      class ServerEvent
        attr_reader :title, :image_uri, :app_id, :start_time, :end_time, :timestamp
        def initialize(data)
          @title = data["title"]
          @image_uri = data["image"]
          @app_id = data["server"]
          @start_time = Time.parse(data["starttime"], in: "UTC").localtime
          @end_time = Time.parse(data["endtime"], in: "UTC").localtime
          @timestamp = Time.parse(data["dateTime"], in: "UTC").localtime
        end
      end
    end
  end
end
