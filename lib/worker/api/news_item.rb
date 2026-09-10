module W3DHubLauncher
  class Worker
    class Api
      class NewsItem
        attr_reader :topic_id, :title, :blurb, :uri, :image_uri, :author_id, :author, :author_uri, :timestamp

        def initialize(data)
          @topic_id = Integer(data["topic-id"] || 0)
          @title = data["title"].to_s
          @blurb = clean_and_scrub_blurb(data["blurb"].to_s)
          @uri = data["uri"].to_s
          @image_uri = data["image"].to_s

          @author_id = data["author-id"].to_s
          @author = data["author"].to_s
          @author_uri = data["author-uri"].to_s

          @timestamp = Time.at(Integer(data["timestamp"] || 0), in: "UTC").localtime
        end

        # Replaces multiple newlines with a single newline, and trims off any leading and trailing whitespace.
        def clean_and_scrub_blurb(string)
          string.gsub(/\n+/, "\n").strip
        end
      end
    end
  end
end
