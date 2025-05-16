require "digest"
require "stringio"

class W3DHub

  # https://github.com/TheUnstoppable/MixLibrary used for reference
  class Mixer
    DEFAULT_BUFFER_SIZE = 32_000_000
    MIX1_HEADER = 0x3158494D
    MIX2_HEADER = 0x3258494D

    class MixParserException < RuntimeError; end
    class MixFormatException < RuntimeError; end

    class MemoryBuffer
      def initialize(file_path:, mode:, buffer_size:, encoding: Encoding::ASCII_8BIT)
        @mode = mode

        @file = File.open(file_path, mode == :read ? "rb" : "wb")
        @file.pos = 0
        @file_size = File.size(file_path)

        @buffer_size = buffer_size
        @chunk = 0
        @last_chunk = 0
        @max_chunks = @file_size / @buffer_size
        @last_cached_chunk = nil

        @encoding = encoding

        @last_buffer_pos = 0
        @buffer = @mode == :read ? StringIO.new(@file.read(@buffer_size)) : StringIO.new
        @buffer.set_encoding(encoding)

        # Cache frequently accessed chunks to reduce disk hits
        @cache = {}
      end

      def pos
        @chunk * @buffer_size + @buffer.pos
      end

      def pos=(offset)
        last_chunk = @chunk
        @chunk = offset / @buffer_size

        raise "No backsies! #{offset} (#{@chunk}/#{last_chunk})" if @mode == :write && @chunk < last_chunk

        fetch_chunk(@chunk) if @mode == :read

        @buffer.pos = offset % @buffer_size
      end

      # string of bytes
      def write(bytes)
        length = bytes.length

        # Crossing buffer boundry
        if @buffer.pos + length > @buffer_size

          edge_size = @buffer_size - @buffer.pos
          buffer_edge = bytes[0...edge_size]

          bytes_to_write = bytes.length - buffer_edge.length
          chunks_to_write = (bytes_to_write / @buffer_size.to_f).ceil
          bytes_written = buffer_edge.length

          @buffer.write(buffer_edge)
          flush_chunk

          chunks_to_write.times do |i|
            i += 1

            @buffer.write(bytes[bytes_written...bytes_written + @buffer_size])
            bytes_written += @buffer_size

            flush_chunk if string.length == @buffer_size
          end
        else
          @buffer.write(bytes)
        end

        bytes
      end

      def write_header(data_offset:, name_offset:)
        flush_chunk

        @file.pos = 4
        write_i32(data_offset)
        write_i32(name_offset)

        @file.pos = 0
      end

      def write_i32(int)
        @file.write([int].pack("l"))
      end

      def read(bytes = nil)
        raise ArgumentError, "Cannot read whole file" if bytes.nil?
        raise ArgumentError, "Cannot under read buffer" if bytes.negative?

        # Long read, need to fetch next chunk while reading, mostly defeats this class...?
        if @buffer.pos + bytes > buffered
          buff = string[@buffer.pos..buffered]

          bytes_to_read = bytes - buff.length
          chunks_to_read = (bytes_to_read / @buffer_size.to_f).ceil

          chunks_to_read.times do |i|
            i += 1

            fetch_chunk(@chunk + 1)

            if i == chunks_to_read # read partial
              already_read_bytes = (chunks_to_read - 1) * @buffer_size
              bytes_more_to_read = bytes_to_read - already_read_bytes

              buff << @buffer.read(bytes_more_to_read)
            else
              buff << @buffer.read
            end
          end

          buff
        else
          fetch_chunk(@chunk) if @last_chunk != @chunk

          @buffer.read(bytes)
        end
      end

      def readbyte
        fetch_chunk(@chunk + 1) if @buffer.pos + 1 > buffered

        @buffer.readbyte
      end

      def fetch_chunk(chunk)
        raise ArgumentError, "Cannot fetch chunk #{chunk}, only #{@max_chunks} exist!" if chunk > @max_chunks
        @last_chunk = @chunk
        @chunk = chunk
        @last_buffer_pos = @buffer.pos

        cached = @cache[chunk]

        if cached
          @buffer.string = cached
        else
          @file.pos = chunk * @buffer_size
          buff = @buffer.string = @file.read(@buffer_size)

          # Cache the active chunk (implementation bounces from @file_data_chunk and back to this for each 'file' processed)
          if @chunk != @file_data_chunk && @chunk != @last_cached_chunk
            @cache.delete(@last_cached_chunk) unless @last_cached_chunk == @file_data_chunk
            @cache[@chunk] = buff
            @last_cached_chunk = @chunk
          end

          buff
        end
      end

      # This is accessed quite often, keep it around
      def cache_file_data_chunk!
        @file_data_chunk = @chunk

        last_buffer_pos = @buffer.pos
        @buffer.pos = 0
        @cache[@chunk] = @buffer.read
        @buffer.pos = last_buffer_pos
      end

      def flush_chunk
        @last_chunk = @chunk
        @chunk += 1

        @file.pos = @last_chunk * @buffer_size
        @file.write(string)

        @buffer.string = "".force_encoding(@encoding)
      end

      def string
        @buffer.string
      end

      def buffered
        @buffer.string.length
      end

      def close
        @file&.close
      end
    end

    class Reader
      attr_reader :package

      def initialize(file_path:, ignore_crc_mismatches: false, metadata_only: false, buffer_size: DEFAULT_BUFFER_SIZE)
        @package = Package.new

        @buffer = MemoryBuffer.new(file_path: file_path, mode: :read, buffer_size: buffer_size)

        @buffer.pos = 0

        @encrypted = false

        # Valid header
        if (mime = read_i32) && (mime == MIX1_HEADER || mime == MIX2_HEADER)
          @encrypted = mime == MIX2_HEADER

          file_data_offset = read_i32
          file_names_offset = read_i32

          @buffer.pos = file_names_offset
          file_count = read_i32

          file_count.times do
            @package.files << Package::File.new(name: read_string)
          end

          @buffer.pos = file_data_offset
          @buffer.cache_file_data_chunk!

          _file_count = read_i32

          file_count.times do |i|
            file = @package.files[i]

            file.mix_crc = read_u32.to_s(16).rjust(8, "0")
            file.content_offset = read_u32
            file.content_length = read_u32

            if !ignore_crc_mismatches && file.mix_crc != file.file_crc
              raise MixParserException, "CRC mismatch for #{file.name}. #{file.mix_crc.inspect} != #{file.file_crc.inspect}"
            end

            pos = @buffer.pos
            @buffer.pos = file.content_offset
            file.data = @buffer.read(file.content_length) unless metadata_only
            @buffer.pos = pos
          end
        else
          raise MixParserException, "Invalid MIX file: Expected \"#{MIX1_HEADER}\" or \"#{MIX2_HEADER}\", got \"0x#{mime.to_s(16).upcase}\"\n(#{file_path})"
        end

      ensure
        @buffer&.close
        @buffer = nil # let GC collect
      end

      def read_i32
        @buffer.read(4).unpack1("l")
      end

      def read_u32
        @buffer.read(4).unpack1("L")
      end

      def read_string
        buffer = ""

        length = @buffer.readbyte

        length.times do
          buffer << @buffer.readbyte
        end

        buffer.strip
      end

      def encrypted?
        @encrypted
      end
    end

    class Writer
      attr_reader :package

      def initialize(file_path:, package:, memory_buffer: false, buffer_size: DEFAULT_BUFFER_SIZE, encrypted: false)
        @package = package

        @buffer = MemoryBuffer.new(file_path: file_path, mode: :write, buffer_size: buffer_size)
        @buffer.pos = 0

        @encrypted = encrypted

        @buffer.write(encrypted? ? "MIX2" : "MIX1")

        files = @package.files.sort { |a, b| a.file_crc <=> b.file_crc }

        @buffer.pos = 16

        files.each do |file|
          file.content_offset = @buffer.pos
          file.content_length = file.data.length
          @buffer.write(file.data)

          @buffer.pos += -@buffer.pos & 7
        end

        file_data_offset = @buffer.pos
        write_i32(files.count)

        files.each do |file|
          write_u32(file.file_crc.to_i(16))
          write_u32(file.content_offset)
          write_u32(file.content_length)
        end

        file_name_offset = @buffer.pos
        write_i32(files.count)

        files.each do |file|
          write_byte(file.name.length + 1)
          @buffer.write("#{file.name}\0")
        end

        @buffer.write_header(data_offset: file_data_offset, name_offset: file_name_offset)
      ensure
        @buffer&.close
      end

      def write_i32(int)
        @buffer.write([int].pack("l"))
      end

      def write_u32(uint)
        @buffer.write([uint].pack("L"))
      end

      def write_byte(byte)
        @buffer.write([byte].pack("c"))
      end

      def encrypted?
        @encrypted
      end
    end

    # Eager loads patch file and streams target file metadata (doen't load target file data or generate CRCs)
    # after target file metadata is loaded, create a temp file and merge patched files into list then
    # build ordered file list and stream patched files and target file chunks into temp file,
    # after that is done, replace target file with temp file
    class Patcher
      def initialize(patch_files:, target_file:, temp_file:, buffer_size: DEFAULT_BUFFER_SIZE)
        @patch_files = patch_files.to_a.map { |f| Reader.new(file_path: f) }
        @target_file = File.open(target_file)
        @temp_file = File.open(temp_file, "a+b")
        @buffer_size = buffer_size
      end
    end

    class Package
      attr_reader :files

      def initialize(files: [])
        @files = files
      end

      class File
        attr_accessor :name, :mix_crc, :content_offset, :content_length, :data

        def initialize(name:, mix_crc: nil, content_offset: nil, content_length: nil, data: nil)
          @name = name
          @mix_crc = mix_crc
          @content_offset = content_offset
          @content_length = content_length
          @data = data
        end

        def file_crc
          return "e6fe46b8" if @name.downcase == ".w3dhub.patch"

          Digest::CRC32.hexdigest(@name.upcase)
        end

        def data_crc
          Digest::CRC32.hexdigest(@data)
        end
      end
    end
  end
end