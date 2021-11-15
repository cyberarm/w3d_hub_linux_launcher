class W3DHub
  class Cache
    def self.path(uri)
      ext = File.basename(uri).split(".").last

      "#{CACHE_PATH}/#{Digest::SHA2.hexdigest(uri)}.#{ext}"
    end

    def self.fetch(uri)
      path = path(uri)

      if File.exist?(path)
        path
      else
        response = Excon.get(uri)

        if response.status == 200
          File.open(path, "wb") do |f|
            f.write(response.body)
          end

          path
        end

        false
      end
    end

    def self.fetch_package(*args)
    end
  end
end
