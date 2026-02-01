require "digest"
require "stringio"

class W3DHub
  # Reimplementating MIX1 reader/writer with years more
  # experience working with these formats and having then
  # advantage of being able to reference the renegade source
  # code :)
  class WWMix
    MIX1_HEADER = 0x3158494D
    MIX2_HEADER = 0x3258494D

    MixHeader = Struct.new(
      :mime_type, # int32
      :file_data_offset, # int32
      :file_names_offset, # int32
      :_reserved # int32
    )

    EntryInfoHeader = Struct.new(
      :crc32, # uint32
      :content_offset, # uint32
      :content_length # uint32
    )

    class Entry
      attr_accessor :path, :name, :info, :blob, :is_blob

      def initialize(name:, path:, info:, blob: nil)
        @name = name
        @path = path
        @info = info
        @blob = blob

        @info.content_length = blob.size if blob?
      end

      def blob?
        @blob
      end

      def calculate_crc32
        Digest::CRC32.hexdigest(@name.upcase).upcase.to_i(16)
      end

      # Write entry's data to stream.
      # Caller is responsible for ensuring stream is valid for writing
      def copy_to(stream)
        if blob?
          return false if @blob.size.zero?

          stream.write(blob)
          return true
        else
          if read
            stream.write(@blob)
            @blob = nil
            return true
          end
        end

        false
      end

      def read
        return false unless File.exist?(@path)
        return false if File.directory?(@path)
        return false if File.size(@path) < @info.content_offset + @info.content_length

        @blob = File.binread(@path, @info.content_length, @info.content_offset)

        true
      end
    end

    attr_reader :path, :encrypted, :entries, :error_reason

    def initialize(path:, encrypted: false)
      @path = path
      @encrypted = encrypted
      @entries = []

      @error_reason = ""
    end

    # Load entries from MIX file. Entry data is NOT loaded.
    # @return true on success or false on failure. Check m_error_reason for why.
    def load
      unless File.exist?(@path)
        @error_reason = format("Path does not exist: %s", @path)
        return false
      end

      if File.directory?(@path)
        @error_reason = format("Path is a directory: %s", @path)
        return false
      end

      File.open(@path, "rb") do |f|
        header = MixHeader.new(0, 0, 0, 0)
        header.mime_type = read_i32(f)
        header.file_data_offset = read_i32(f)
        header.file_names_offset = read_i32(f)
        header._reserved = read_i32(f)

        unless header.mime_type == MIX1_HEADER || header.mime_type == MIX2_HEADER
          @error_reason = format("Invalid mime type: %d", header.mime_type)
          return false
        end

        @encrypted = header.mime_type == MIX2_HEADER

        # Read entry info
        f.pos = header.file_data_offset
        file_count = read_i32(f)

        file_count.times do |i|
          entry_info = EntryInfoHeader.new(0, 0, 0)
          entry_info.crc32 = read_u32(f)
          entry_info.content_offset = read_u32(f)
          entry_info.content_length = read_u32(f)

          @entries << Entry.new(name: "", path: @path, info: entry_info)
        end

        # Read entry names
        f.pos = header.file_names_offset
        file_count = read_i32(f)

        file_count.times do |i|
          @entries[i].name = read_string(f)
        end
      end

      true
    end

    def save
      unless @entries.size.positive?
        @error_reason = "No entries to write."
        return false
      end

      if File.directory?(@path)
        @error_reason = format("Path is a directory: %s", @path)
        return false
      end

      File.open(@path, "wb") do |f|
        header = MixHeader.new(encrypted? ? MIX2_HEADER : MIX1_HEADER, 0, 0, 0)

        # write mime type
        write_i32(f, header.mime_type)

        f.pos = 16

        # sort entries by crc32 of their name
        sort_entries

        # write file blobs
        @entries.each do |entry|
          # store current io position
          pos = f.pos

          # copy entry to stream
          entry.copy_to(f)

          # update entry with new offset
          entry.info.content_offset = pos

          # add alignment padding
          padding = (-f.pos & 7)
          padding.times do |i|
            write_u8(f, 0)
          end
        end

        # Save file data offset
        header.file_data_offset = f.pos

        # write number of entries
        write_i32(f, @entries.size)

        # write entries file data
        @entries.each do |entry|
          write_u32(f, entry.info.crc32)
          write_u32(f, entry.info.content_offset)
          write_u32(f, entry.info.content_length)
        end

        # save file names offset
        header.file_names_offset = f.pos

        # write number of entries
        write_i32(f, @entries.size)

        # write entry names
        @entries.each do |entry|
          write_string(f, entry.name)
        end

        # jump to io_position 4
        f.pos = 4
        # write rest of header

        write_i32(f, header.file_data_offset)
        write_i32(f, header.file_names_offset)
        write_i32(f, header._reserved)
      end

      true
    end

    def valid?
      # ALL entries MUST have unique case-insensitive names
      @entries.each do |a|
        @entries.each do |b|
          next if a == b

          return false if a.name.upcase == b.name.upcase
        end
      end

      true
    end

    def encrypted?
      @encrypted
    end

    def add_file(path:, replace: false)
      return false unless File.exist?(path)
      return false if File.directory?(path)

      entry = Entry.new(name: File.basename(path), path: path, info: EntryInfoHeader.new(0, 0, File.size(path)))
      add_entry(entry: entry, replace: replace)
    end

    def add_blob(path:, blob:, replace: false)
      info = EntryInfoHeader.new(0, 0, blob.size)
      entry = Entry.new(name: File.basename(path), path: path, info: info, blob: blob)
      into.crc32 = @entries.last.calculate_crc32

      add_entry(entry: entry, replace: replace)
    end

    def add_entry(entry:, replace: false)
      duplicate = @entries.find { |e| e.name.upcase == entry.name.upcase }

      if duplicate
        if replace
          @entries.delete(duplicate)
        else
          return false
        end
      end

      @entries << entry
      true
    end

    def sort_entries
      return false if @entries.any? { |e| e.info.crc32 == 0 }

      @entries.sort! { |a, b| a.info.crc32 <=> b.info.crc32 }

      true
    end

    def read_i32(f) = f.read(4).unpack1("l")
    def read_u32(f) = f.read(4).unpack1("L")
    def read_u8(f) = f.read(1).unpack1("c")
    def read_string(f)
      f.read(read_u8(f)).strip
    end

    def write_i32(f, value) = f.write([value].pack("l"))
    def write_u32(f, value) = f.write([value].pack("L"))
    def write_u8(f, value) = f.write([value].pack("c"))
    def write_string(f, string)
      length = string.size + 1 # include null byte
      write_u8(f, length)
      f.write(string)
      write_u8(f, 0) # null byte
    end
  end
end
