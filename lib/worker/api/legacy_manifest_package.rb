require "json"
require "digest/sha2"

module W3DHubBackend
  class Worker
    class Api
      class LegacyManifestPackage
        attr_reader :category, :subcategory, :version, :name, :error, :file_size,
                    :checksum_chunk_size, :sha256_checksum, :checksum_chunks

        def initialize(hash)
          @category = hash["category"]
          @subcategory = hash["subcategory"]
          @version = Gem::Version.new(hash["version"] || "0.0.0.0")
          @name = hash["name"]
          @error = hash["error"]
          @file_size = Integer(hash["size"] || 0)
          @checksum_chunk_size = Integer(hash["checksum-size"] || 0)
          @sha256_checksum = hash["checksum"]
          @checksum_chunks = hash["checksum-chunks"]
        end

        def error?
          @error
        end

        # checksum whole file and file chunks until a mismatch occurs or the whole file is verified.
        def verify_file(filename)
          file_size = File.size(filename)

          checksum_chunks = {}
          overall_checksum = ""
          overall_digest = Digest::SHA256.new
          chunk_digest = Digest::SHA256.new

          File.open(filename, "rb") do |f|
            f.pos = 0
            offset = 0

            while (chunk = f.read(@checksum_chunk_size))

              overall_digest << chunk

              checksum_chunks[offset] = chunk_digest.update(chunk).hexdigest.upcase

              offset += @checksum_chunk_size
              chunk_digest.reset
            end
          end

          overall_checksum = overall_digest.hexdigest.upcase

          # FIXME: Make this a nice Data struct object
          [overall_checksum, checksum_chunks, file_size]
        end
      end
    end

    def package_cache_filename(category, subcategory)
      if subcategory.empty?
        category
      else
        "#{category}-#{subcategory}"
      end
    end
  end
end
