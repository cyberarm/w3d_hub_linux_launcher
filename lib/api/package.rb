class W3DHub
  class Api
    class Package
      attr_reader :category, :subcategory, :name, :version, :size, :checksum, :checksum_chunk_size, :checksum_chunks,
                  :custom_partially_valid_at_bytes

      def initialize(hash)
        @data = hash

        @category = @data[:category]
        @subcategory = @data[:subcategory]
        @name = @data[:name]
        @version = @data[:version]

        @size = @data[:size]
        @checksum = @data[:checksum]
        @checksum_chunk_size = @data[:"checksum-chunk-size"]
        @checksum_chunks = @data[:"checksum-chunks"]

        @custom_partially_valid_at_bytes = 0
      end

      def chunk(key)
        @checksum_chunks[:"#{key}"]
      end

      def partially_valid_at_bytes=(i)
        @custom_partially_valid_at_bytes = i
      end

      class Chunk
        attr_reader :chunk, :checksum

        def initialize(array)
          @data = array

          @chunk = @data[0]
          @checksum = @data[1]
        end
      end
    end
  end
end
