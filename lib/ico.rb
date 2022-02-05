require "stringio"

class W3DHub
  class ICO
    IconDirectory = Struct.new(:reserved, :type, :image_count)

    IconDirectoryEntity = Struct.new(
      :width,
      :height,
      :palette_size,
      :reserved,
      :color_planes,
      :bit_depth,
      :image_size,
      :image_offset
    )


    def initialize(file:)
      @file = StringIO.new(File.binread(file))

      @images = []

      parse
    end

    def directory
      @icon_directory
    end

    def images
      @images
    end

    # SEE: https://en.wikipedia.org/wiki/ICO_(file_format)
    def parse
      # Parse IconDirectory
      @icon_directory = IconDirectory.new(
        read_u16, read_u16, read_u16
      )

      @icon_directory.image_count.times do
        @images << IconDirectoryEntity.new(
          read_u8,
          read_u8,
          read_u8,
          read_u8,
          read_u16,
          read_u16,
          read_u32,
          read_u32
        )
      end
    end

    def read_u8
      @file.read(1).unpack1("C")
    end

    def read_u16
      @file.read(2).unpack1("v")
    end

    def read_u32
      @file.read(4).unpack1("V")
    end

    def to_rgba32_blob(image)
      @file.pos = image.image_offset
      buf = @file.read(image.image_size)

      File.write("TEMP.bmp", buf)
    end

    def select_pngs
      @images.select do |image|
        @file.pos = image.image_offset
        buf = @file.read(8).unpack1("a*")
        buf == "\211PNG\r\n\032\n".force_encoding("ASCII-8BIT")
      end
    end

    def select_bmps
    end
  end
end

data = W3DHub::ICO.new(file: "/home/cyberarm/Downloads/icos/ar.ico")
pp data.select_pngs.size, data.images.size
# data.to_rgba32_blob(data.images.first)
