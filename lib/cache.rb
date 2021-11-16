class W3DHub
  class Cache
    def self.path(uri)
      ext = File.basename(uri).split(".").last

      "#{CACHE_PATH}/#{Digest::SHA2.hexdigest(uri)}.#{ext}"
    end

    # Fetch a generic uri
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

    def self.create_directories(path)
      target_directory = File.dirname(path)

      FileUtils.mkdir_p(target_directory) unless Dir.exist?(target_directory)
    end

    def self.package_path(category, subcategory, name, version)
      package_cache_dir = $window.settings[:package_cache_dir]

      "#{package_cache_dir}/#{category}/#{subcategory}/#{version}/#{name}.package"
    end

    # Download a W3D Hub package
    def self.fetch_package(socket, category, subcategory, name, version, block)
      path = package_path(category, subcategory, name, version)

      create_directories(path)

      file = File.open(path, "wb")

      streamer = lambda do |chunk, remaining_bytes, total_bytes|
        file.write(chunk)

        block.call(chunk, remaining_bytes, total_bytes)
        # puts "Remaining: #{remaining_bytes.to_f / total_bytes}%"
      end

      response = socket.post(
        path: "apis/launcher/1/get-package",
        headers: Api::DEFAULT_HEADERS.merge({"Content-Type": "application/x-www-form-urlencoded"}),
        body: "data=#{JSON.dump({ category: category, subcategory: subcategory, name: name, version: version })}",
        response_block: streamer
      )

      file.close

      response.status == 200
    end
  end
end
