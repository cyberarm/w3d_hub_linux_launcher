require "digest"

class W3DHub

  # https://github.com/TheUnstoppable/MixLibrary used for reference
  class Mixer
    class MixParserException < RuntimeError; end
    class MixFormatException < RuntimeError; end

    class Reader
      attr_reader :package

      def initialize(file_path:, ignore_crc_mismatches: false)
        @package = Package.new
        @file = File.open(file_path)

        @file.pos = 0

        # Valid header
        if read_i32 == 0x3158494D
          file_data_offset = read_i32
          file_names_offset = read_i32

          @file.pos = file_names_offset
          file_count = read_i32

          file_count.times do
            @package.files << Package::File.new(name: read_string)
          end

          @file.pos = file_data_offset
          _file_count = read_i32

          file_count.times do |i|
            file = @package.files[i]

            file.mix_crc = read_u32.to_s(16)
            file.content_offset = read_u32
            file.content_length = read_u32

            if file.mix_crc != file.file_crc && !ignore_crc_mismatches
              raise MixParserException, "CRC mismatch for #{file.name}. #{file.mix_crc.inspect} != #{file.file_crc.inspect}"
            end

            pos = @file.pos
            @file.pos = file.content_offset
            file.data = @file.read(file.content_length)
            @file.pos = pos
          end
        else
          raise MixParserException, "Invalid MIX file"
        end

      ensure
        @file&.close
      end

      def read_i32
        @file.read(4).unpack1("l")
      end

      def read_u32
        @file.read(4).unpack1("L")
      end

      def read_string
        buffer = ""

        length = @file.readbyte

        length.times do
          buffer << @file.readbyte
        end

        buffer.strip
      end
    end

    class Writer
      attr_reader :package

      def initialize(file_path:, package:)
        @package = package

        @file = File.open(file_path, "wb")
        @file.pos = 0

        @file.write("MIX1")

        files = @package.files.sort { |a, b| a.file_crc <=> b.file_crc }

        @file.pos = 16

        files.each do |file|
          file.content_offset = @file.pos
          file.content_length = file.data.length
          @file.write(file.data)

          @file.pos += -@file.pos & 7
        end

        file_data_offset = @file.pos
        write_i32(files.count)

        files.each do |file|
          write_u32(file.file_crc.to_i(16))
          write_u32(file.content_offset)
          write_u32(file.content_length)
        end

        file_name_offset = @file.pos
        write_i32(files.count)

        files.each do |file|
          write_byte(file.name.length + 1)
          @file.write("#{file.name}\0")
        end

        @file.pos = 4
        write_i32(file_data_offset)
        write_i32(file_name_offset)

        @file.pos = 0
        @file.flush
      ensure
        @file&.close
      end

      def write_i32(int)
        @file.write([int].pack("l"))
      end

      def write_u32(uint)
        @file.write([uint].pack("L"))
      end

      def write_byte(byte)
        @file.write([byte].pack("c"))
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
          Digest::CRC32.hexdigest(@name.upcase)
        end

        def data_crc
          Digest::CRC32.hexdigest(@data)
        end
      end
    end
  end
end