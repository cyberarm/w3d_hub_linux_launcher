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

    def self.create_directories(path, is_directory = false)
      target_directory = is_directory ? path : File.dirname(path)

      FileUtils.mkdir_p(target_directory) unless Dir.exist?(target_directory)
    end

    def self.package_path(category, subcategory, name, version)
      package_cache_dir = Store.settings[:package_cache_dir]

      "#{package_cache_dir}/#{category}/#{subcategory}/#{version}/#{name}.package"
    end

    def self.install_path(application, channel)
      app_install_dir = Store.settings[:app_install_dir]

      "#{app_install_dir}/#{application.category}/#{application.id}/#{channel.id}"
    end

    # Download a W3D Hub package
    def self.fetch_package(package, block)
      path = package_path(package.category, package.subcategory, package.name, package.version)
      headers = { "Content-Type": "application/x-www-form-urlencoded" }
      start_from_bytes = package.custom_partially_valid_at_bytes

      puts "    Start from bytes: #{start_from_bytes}"

      create_directories(path)

      file = File.open(path, "ab")
      if (start_from_bytes > 0)
        headers["Range"] = "bytes=#{start_from_bytes}-#{package.size}"
        file.pos = start_from_bytes
      end

      streamer = lambda do |chunk, remaining_bytes, total_bytes|
        file.write(chunk)

        block.call(chunk, remaining_bytes, total_bytes)
        puts "    Remaining: #{((remaining_bytes.to_f / total_bytes) * 100.0).round}% (#{W3DHub::format_size(total_bytes - remaining_bytes)} / #{W3DHub::format_size(total_bytes)})"
      end

      # Create a new connection due to some weirdness somewhere in Excon
      response = Excon.post(
        "#{Api::ENDPOINT}/apis/launcher/1/get-package",
        headers: Api::DEFAULT_HEADERS.merge(headers),
        body: "data=#{JSON.dump({ category: package.category, subcategory: package.subcategory, name: package.name, version: package.version })}",
        chunk_size: 4_000_000,
        response_block: streamer
      )

      file.close

      response.status == 200 || response.status == 206
    end
  end
end
