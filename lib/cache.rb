class W3DHub
  class Cache
    LOG_TAG = "W3DHub::Cache".freeze

    def self.path(uri)
      ext = File.basename(uri).split(".").last

      "#{CACHE_PATH}/#{Digest::SHA2.hexdigest(uri)}.#{ext}"
    end

    # Fetch a generic uri
    def self.fetch(uri:, force_fetch: false, backend: :w3dhub)
      path = path(uri)

      if !force_fetch && File.exist?(path)
        path
      else
        Api.fetch(uri, W3DHub::Api::DEFAULT_HEADERS, nil, backend) do |result|
          if result.okay?
            File.open(path, "wb") { |f| f.write result.data }
          end
        end
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
    def self.async_fetch_package(package, block)
      endpoint_download_url = package.download_url || "#{Api::W3DHUB_API_ENDPOINT}/apis/launcher/1/get-package"
      if package.download_url
        uri_path = package.download_url.split("/").last
        endpoint_download_url = package.download_url.sub(uri_path, URI.encode_uri_component(uri_path))
      end
      path = package_path(package.category, package.subcategory, package.name, package.version)
      headers = [["content-type", "application/x-www-form-urlencoded"], ["user-agent", Api::USER_AGENT]]
      headers << ["authorization", "Bearer #{Store.account.access_token}"] if Store.account && !package.download_url
      body = URI.encode_www_form("data": JSON.dump({ category: package.category, subcategory: package.subcategory, name: package.name, version: package.version }))
      start_from_bytes = package.custom_partially_valid_at_bytes

      logger.info(LOG_TAG) { "    Start from bytes: #{start_from_bytes} of #{package.size}" }

      create_directories(path)

      file = File.open(path, start_from_bytes.positive? ? "r+b" : "wb")

      if start_from_bytes.positive?
        headers << ["range", "bytes=#{start_from_bytes}-"]
        file.pos = start_from_bytes
      end

      result = false
      Sync do
        uri = URI(endpoint_download_url)

        response = W3DHub::Api.provision_http_client(uri.origin).send((package.download_url ? :get : :post), uri.request_uri, headers, body)
        if response.success?
          total_bytes = package.size

          response.each do |chunk|
            file.write(chunk)

            block.call(chunk, total_bytes - file.pos, total_bytes)
          end

          result = true
        end

        if response&.status == 200 || response&.status == 206
          result = true
        else
          logger.debug(LOG_TAG) { "    Failed to retrieve package: (#{package.category}:#{package.subcategory}:#{package.name}:#{package.version})" }
          logger.debug(LOG_TAG) { "      Download URL: #{endpoint_download_url}, response: #{response&.status || -1}" }

          result = false
        end
      rescue Async::Timeout => e
        logger.error(LOG_TAG) { "    Connection to \"#{endpoint_download_url}\" timed out after: #{W3DHub::Api::API_TIMEOUT} seconds" }
        logger.error(LOG_TAG) { e }
        logger.debug(LOG_TAG) { "    Failed to retrieve package: (#{package.category}:#{package.subcategory}:#{package.name}:#{package.version})" }
        logger.debug(LOG_TAG) { "      Download URL: #{endpoint_download_url}, response: #{response&.status || -1}" }

        result = false
      rescue StandardError => e
        logger.error(LOG_TAG) { "    Connection to \"#{endpoint_download_url}\" errored:" }
        logger.error(LOG_TAG) { e }
        logger.debug(LOG_TAG) { "    Failed to retrieve package: (#{package.category}:#{package.subcategory}:#{package.name}:#{package.version})" }
        logger.debug(LOG_TAG) { "      Download URL: #{endpoint_download_url}, response: #{response&.status || -1}" }

        result = false
      ensure
        file&.close
        response&.close
      end

      result
    end

    # Download a W3D Hub package
    def self.fetch_package(package, block)
      async_fetch_package(package, block)
    end

    def self.acquire_net_lock(key)
      Store["net_locks"] ||= {}

      if Store["net_locks"][key]
        false
      else
        Store["net_locks"][key] = true
      end
    end

    def self.release_net_lock(key)
      Store["net_locks"] ||= {}

      if Store["net_locks"][key]
        Store["net_locks"].delete(key)
      else
        warn "!!! net_lock not found for #{key.inspect}"
      end
    end

    def self.net_lock?(key)
      Store["net_locks"] ||= {}

      Store["net_locks"][key]
    end
  end
end
