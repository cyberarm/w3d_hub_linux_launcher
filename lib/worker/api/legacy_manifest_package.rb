require "json"
require "digest/sha2"

module W3DHubLauncher
  class Worker
    class Api
      class LegacyManifestPackage
        attr_reader :category, :subcategory, :version, :name, :error, :file_size,
                    :checksum_chunk_size, :sha256_checksum, :checksum_chunks, :download_url

        def initialize(hash)
          @category = hash["category"]
          @subcategory = hash["subcategory"]
          @version = Gem::Version.new(hash["version"] || "0.0.0.0")
          @name = hash["name"]
          @error = hash["error"]
          @file_size = Integer(hash["size"] || 0)
          @checksum_chunk_size = Integer(hash["checksum-chunk-size"] || 0)
          @sha256_checksum = hash["checksum"]
          @checksum_chunks = hash["checksum-chunks"]
          @download_url = hash["download_url"]
        end

        def error?
          @error
        end

        def version?
          @version != Gem::Version.new("0.0.0.0")
        end

        # checksum whole file and file chunks until a mismatch occurs or the whole file is verified.
        def verify_file(filename)
          return false unless File.exist?(filename) && !File.directory?(filename)

          file_size = File.size(filename)

          overall_digest = Digest::SHA256.new
          chunk_digest = Digest::SHA256.new

          File.open(filename, "rb") do |f|
            f.pos = 0
            offset = 0
            last_valid_offset = 0

            while (chunk = f.read(@checksum_chunk_size))
              overall_digest << chunk

              # return last valid chunk on invalid chunk
              return last_valid_offset unless @checksum_chunks[offset.to_s] == chunk_digest.update(chunk).hexdigest.upcase

              last_valid_offset = offset
              offset += @checksum_chunk_size
              chunk_digest.reset
            end
          end

          # return boolean after completely digesting file
          @sha256_checksum == overall_digest.hexdigest.upcase
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
