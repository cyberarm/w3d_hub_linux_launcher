class W3DHub
  class Api
    class Package
      attr_reader :category, :subcategory, :name, :version, :size, :checksum, :checksum_chunk_size, :checksum_chunks

      def initialize(hash)
        @data = hash

        @category = @data[:category]
        @subcategory = @data[:subcategory]
        @name = @data[:name]
        @version = @data[:version]

        @size = @data[:size]
        @checksum = @data[:checksum]
        @checksum_chunk_size = @data[:"checksum-chunk-size"]
        @checksum_chunks = @data[:"checksum-chunks"]&.map { |c| Chunk.new(c) }
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
