require "stringio"

class W3DHub
  class ICO
    PNG_IDENT = "\211PNG\r\n\032\n".force_encoding("ASCII-8BIT").freeze

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

        @images.last.width  = 256 if @images.last.width == 0
        @images.last.height = 256 if @images.last.height == 0
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

    def select_pngs
      @images.select do |image|
        image_png?(image)
      end
    end

    def image_png?(image)
      @file.pos = image.image_offset
      buf = @file.read(8).unpack1("a*")

      buf == PNG_IDENT
    end

    def select_bmps
      @images.select do |image|
        image_bmp?(image) && image.palette_size == 0 && image.bit_depth == 32
      end
    end

    def image_bmp?(image)
      !image_png?(image)
    end

    def to_rgba32_blob(image)
      @file.pos = image.image_offset
      buf = StringIO.new(@file.read(image.image_size))

      raise NotImplementedError "Cannot parse png based icons!" unless image_bmp?(image)

      raise NotImplementedError "Cannot parse #{image.bit_depth}" unless image.bit_depth == 32

      blob = "".force_encoding("ASCII-8BIT")

      width  = image.width
      height = image.height - 1

      image.height.times do |y|
        image.width.times do |x|
          buf.pos = ((height - y) * width + x + 10) * 4

          blue  = buf.read(1)
          green = buf.read(1)
          red   = buf.read(1)
          alpha = buf.read(1)

          blob << red
          blob << green
          blob << blue
          blob << alpha
        end
      end

      Gosu::Image.from_blob(image.width, image.height, blob)
    end

    def image_data(image)
      @file.pos = image.image_offset
      StringIO.new(@file.read(image.image_size)).string
    end

    def save(image, filename)
      if image_bmp?(image)
        to_rgba32_blob(image).save(filename)
      else
        File.open(filename, "wb") { |f| f.write(image_data(image)) }
      end
    end
  end
end
