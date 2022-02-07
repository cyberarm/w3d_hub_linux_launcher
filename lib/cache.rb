class W3DHub
  class Cache
    def self.path(uri)
      ext = File.basename(uri).split(".").last

      "#{CACHE_PATH}/#{Digest::SHA2.hexdigest(uri)}.#{ext}"
    end

    # Fetch a generic uri
    def self.fetch(uri, force_fetch = false)
      path = path(uri)

      if !force_fetch && File.exist?(path)
        path
      else
        internet = Async::HTTP::Internet.instance

        response = internet.get(uri, W3DHub::Api::DEFAULT_HEADERS)

        if response.success?
          response.save(path, "wb")

          return path
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

      if version.to_s.length.zero?
        "#{package_cache_dir}/#{category}/#{subcategory}/#{name}.package"
      else
        "#{package_cache_dir}/#{category}/#{subcategory}/#{version}/#{name}.package"
      end
    end

    def self.install_path(application, channel)
      game_data = Store.settings[:games]&.dig(:"#{application.id}_#{channel.id}")

      return game_data[:install_directory] if game_data && game_data[:install_directory]

      "#{Store.settings[:app_install_dir]}/#{application.category}/#{application.id}/#{channel.id}"
    end

    # Download a W3D Hub package
    def self.fetch_package(package, block)
      path = package_path(package.category, package.subcategory, package.name, package.version)
      headers = { "Content-Type": "application/x-www-form-urlencoded", "User-Agent": Api::USER_AGENT }
      headers["Authorization"] = "Bearer #{Store.account.access_token}" if Store.account
      start_from_bytes = package.custom_partially_valid_at_bytes

      puts "    Start from bytes: #{start_from_bytes} of #{package.size}"

      create_directories(path)

      file = File.open(path, start_from_bytes.positive? ? "r+b" : "wb")

      if start_from_bytes.positive?
        headers["Range"] = "bytes=#{start_from_bytes}-"
        file.pos = start_from_bytes
      end

      streamer = lambda do |chunk, remaining_bytes, total_bytes|
        file.write(chunk)

        block.call(chunk, remaining_bytes, total_bytes)
        # puts "    Remaining: #{((remaining_bytes.to_f / total_bytes) * 100.0).round}% (#{W3DHub::format_size(total_bytes - remaining_bytes)} / #{W3DHub::format_size(total_bytes)})"
      end

      # Create a new connection due to some weirdness somewhere in Excon
      response = Excon.post(
        "#{Api::ENDPOINT}/apis/launcher/1/get-package",
        tcp_nodelay: true,
        headers: headers,
        body: "data=#{JSON.dump({ category: package.category, subcategory: package.subcategory, name: package.name, version: package.version })}",
        chunk_size: 4_000_000,
        response_block: streamer
      )

      response.status == 200 || response.status == 206
    ensure
      file&.close
    end
  end
end
