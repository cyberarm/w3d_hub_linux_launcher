class W3DHub
  class Cache
    def self.path(uri)
      ext = File.basename(uri).split(".").last

      "#{CACHE_PATH}/#{Digest::SHA2.hexdigest(uri)}.#{ext}"
    end

    # Fetch a generic uri
    def self.fetch(internet, uri, force_fetch = false)
      path = path(uri)

      if !force_fetch && File.exist?(path)
        path
      else
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

      "#{package_cache_dir}/#{category}/#{subcategory}/#{version}/#{name}.package"
    end

    def self.install_path(application, channel)
      game_data = Store.settings[:games]&.dig(:"#{application.id}_#{channel.id}")

      return game_data[:install_directory] if game_data && game_data[:install_directory]

      "#{Store.settings[:app_install_dir]}/#{application.category}/#{application.id}/#{channel.id}"
    end

    # Download a W3D Hub package
    def self.fetch_package(internet, package, block)
      path = package_path(package.category, package.subcategory, package.name, package.version)
      start_from_bytes = package.custom_partially_valid_at_bytes

      puts "    Start from bytes: #{start_from_bytes}"

      create_directories(path)

      offset = start_from_bytes
      parts = []
      chunk_size = 4_000_000
      workers = 4

      file = File.open(path, offset.positive? ? "r+b" : "wb")

      amount_written = 0

      while (offset < package.size)
        byte_range_start = offset
        byte_range_end   = [offset + chunk_size, package.size].min
        parts << (byte_range_start...byte_range_end)

        offset += chunk_size
      end

      semaphore = Async::Semaphore.new(workers)
      barrier   = Async::Barrier.new(parent: semaphore)

      while !parts.empty?
        barrier.async do
          part = parts.shift

          range_header = [["range", "bytes=#{part.min}-#{part.max}"]]

          body = "data=#{JSON.dump({ category: package.category, subcategory: package.subcategory, name: package.name, version: package.version })}"
          response = internet.post("#{Api::ENDPOINT}/apis/launcher/1/get-package", W3DHub::Api::FORM_ENCODED_HEADERS + range_header, body)

          if response.success?
            chunk = response.read
            written = 0
            if W3DHub.unix?
              written = file.pwrite(chunk, part.min)
            else
              # probably not "thread safe"
              file.pos = part.min
              written = file.write(chunk)
            end

            amount_written += written
            remaining_bytes = package.size - amount_written
            total_bytes = package.size

            block.call(chunk, remaining_bytes, total_bytes)
            # puts "    Remaining: #{((remaining_bytes.to_f / total_bytes) * 100.0).round}% (#{W3DHub::format_size(total_bytes - remaining_bytes)} / #{W3DHub::format_size(total_bytes)})"
          end
        end

        barrier.wait
      end
    ensure
      file&.close
    end
  end
end
