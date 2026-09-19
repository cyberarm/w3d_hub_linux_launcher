require "stringio"

module W3DHubLauncher
  class DDS
    # https://docs.microsoft.com/en-us/windows/win32/direct3ddds/dds-header
    # https://docs.microsoft.com/en-us/windows/win32/direct3ddds/dds-pixelformat
    # https://docs.microsoft.com/en-us/windows/win32/direct3ddds/dx-graphics-dds-pguide
    # https://docs.microsoft.com/en-us/windows/win32/direct3ddds/dds-file-layout-for-textures

    DXT1 = 827611204
    DXT2 = 844388420
    DXT3 = 861165636
    DXT4 = 877942852
    DXT5 = 894720068

    DDSD_CAPS        = 0x1
    DDSD_HEIGHT      = 0x2
    DDSD_WIDTH       = 0x4
    DDSD_PITCH       = 0x8
    DDSD_PIXELFORMAT = 0x1000
    DDSD_MIPMAPCOUNT = 0x20_000
    DDSD_LINEARSIZE  = 0x80_000
    DDSD_DEPTH       = 0x800_000

    DDSCAPS_COMPLEX = 0x8
    DDSCAPS_MIPMAP  = 0x400_000
    DDSCAPS_TEXTURE = 0x1000

    DDSCAPS2_CUBEMAP           = 0x200
    DDSCAPS2_CUBEMAP_POSITIVEX = 0x400
    DDSCAPS2_CUBEMAP_NEGATIVEX = 0x800
    DDSCAPS2_CUBEMAP_POSITIVEY = 0x1000
    DDSCAPS2_CUBEMAP_NEGATIVEY = 0x2000
    DDSCAPS2_CUBEMAP_POSITIVEZ = 0x4000
    DDSCAPS2_CUBEMAP_NEGATIVEZ = 0x8000
    DDSCAPS2_VOLUME            = 0x200_000

    DDPF_ALPHAPIXELS = 0x1
    DDPF_ALPHA       = 0x2
    DDPF_FOURCC      = 0x4
    DDPF_RGB         = 0x40
    DDPF_YUV         = 0x200
    DDPF_LUMINANCE   = 0x20_000

    Header = Struct.new(
      :byte_size, :flags, :height, :width, :pitch_or_linear_size,
      :depth, :mipmap_count, :reserved1, :pixel_format,
      :caps, :caps2, :caps3, :caps4, :reserved2
    )

    HeaderX10 = Struct.new(:value)

    PixelFormat = Struct.new(
      :byte_size, :flags, :four_cc, :rgb_bit_count,
      :red_bit_mask, :green_bit_mask, :blue_bit_mask, :alpha_bit_mask
    )

    Image = Struct.new(:data, :width, :height)

    attr_reader :header, :images
    def initialize(path: nil, io: nil, shallow: true)
      if path
        @data = StringIO.new(File.binread(path))
      elsif io
        @data = io
      else
        raise "Nah man."
      end

      @shallow = shallow
      @images = []

      decode_header
      decode_images
    end

      # typedef struct {
      #   DWORD           dwSize;
      #   DWORD           dwFlags;
      #   DWORD           dwHeight;
      #   DWORD           dwWidth;
      #   DWORD           dwPitchOrLinearSize;
      #   DWORD           dwDepth;
      #   DWORD           dwMipMapCount;
      #   DWORD           dwReserved1[11];
      #   DDS_PIXELFORMAT ddspf;
      #   DWORD           dwCaps;
      #   DWORD           dwCaps2;
      #   DWORD           dwCaps3;
      #   DWORD           dwCaps4;
      #   DWORD           dwReserved2;
      # } DDS_HEADER;

    def decode_header
      @data.pos = 0

      raise "File is not a DDS" unless read_u32 == 0x20534444 # magic byte "DDS"

      size = read_u32
      flags = read_u32
      height = read_u32
      width = read_u32
      pitch_or_linear_size = read_u32
      depth = read_u32
      mipmap_count = read_u32
      reserved1 = 11.times.map { read_u32 }

      pixel_format = read_pixelformat

      caps = read_u32
      caps2 = read_u32
      caps3 = read_u32
      caps4 = read_u32
      reserved2 = read_u32

      @header = Header.new(
        size, flags, height, width, pitch_or_linear_size, depth, mipmap_count,
        reserved1, pixel_format, caps, caps2, caps3, caps4, reserved2
      )

      @header.freeze

      raise "Invalid dds header size: #{size}, expected 124" unless size == 124
      raise "Invalid pixel format header size: #{pixel_format.byte_size}, expected 32" unless pixel_format.byte_size == 32
    end

    def decode_images
      pixel_format = @header.pixel_format

      raise "Unsupported dds format: #{pixel_format.four_cc}" unless (pixel_format.four_cc == DXT1 || pixel_format.four_cc == DXT3 || pixel_format.four_cc == DXT5)
      raise "Unsupported pixel format: #{pixel_format.flags}" unless pixel_format.flags == DDPF_FOURCC

      width = @header.width
      height = @header.height
      mipmap_count = [1, @header.mipmap_count].max
      mipmap_count = 1 if @shallow
      block_bytes = 8
      block_bytes = 16 if pixel_format.four_cc == DXT3 || pixel_format.four_cc == DXT5
      data_offset = @header.byte_size + 4

      mipmap_count.times do
        data_length = [4, width].max / 4 * [4, height].max / 4 * block_bytes

        @data.pos = data_offset
        image = Image.new(
          to_rgba(@data.read(data_length), width, height, pixel_format.four_cc == DXT1),
          width,
          height
        )

        @images << image

        data_offset += data_length
        width /= 2
        height /= 2
      end
    end

    def read_u32
      @data.read(4).unpack1("L")
    end

    # struct DDS_PIXELFORMAT {
    #   DWORD dwSize;
    #   DWORD dwFlags;
    #   DWORD dwFourCC;
    #   DWORD dwRGBBitCount;
    #   DWORD dwRBitMask;
    #   DWORD dwGBitMask;
    #   DWORD dwBBitMask;
    #   DWORD dwABitMask;
    # };

    def read_pixelformat

      size = read_u32
      flags = read_u32
      four_cc = read_u32
      rgb_bit_count = read_u32
      red_bit_mask = read_u32
      green_bit_mask = read_u32
      blue_bit_mask = read_u32
      alpha_bit_mask = read_u32

      PixelFormat.new(
        size, flags, four_cc, rgb_bit_count,
        red_bit_mask, green_bit_mask, blue_bit_mask, alpha_bit_mask
      )
    end

    # https://github.com/kchapelier/decode-dxt/
    def to_rgba(data, width, height, dxt1 = false)
      conversion_started = Gosu.milliseconds

      data = StringIO.new(data)
      rgba = Array.new(width * height * 4, 0) # StringIO.new("\0" * (width * height * 4), "wb") #
      width_4 = (width / 4) | 0
      height_4 = (height / 4) | 0
      stride = 4

      height_4.times do |h|
        width_4.times do |w|
          a, b, index = data.read(8).unpack("vvV")
          color_values = interpolate_color_values(a, b, dxt1)
          color_indices = index

          4.times do |y|
            4.times do |x|
              pixel_index = (3 - x) + (y * 4)
              rgba_index = (h * 4 + 3 - y) * width * 4 + (w * 4 + x) * 4
              color_index = (color_indices >> (2 * (15 - pixel_index))) & 0x03

              rgba[rgba_index]     = color_values[color_index * 4]
              rgba[rgba_index + 1] = color_values[color_index * 4 + 1]
              rgba[rgba_index + 2] = color_values[color_index * 4 + 2]
              rgba[rgba_index + 3] = color_values[color_index * 4 + 3]
            end
          end
        end
      end


      puts "Inital set complete after: #{Gosu.milliseconds - conversion_started}ms"
      v = rgba.pack("C*") #.map { |v| v.chr }.join
      puts "type set complete after: #{Gosu.milliseconds - conversion_started}ms"

      v
    end

    def interpolate_color_values(a, b, dxt1 = false)
        first_color  = convert_565_byte_to_rgb(a)
        second_color = convert_565_byte_to_rgb(b)

        color_values = [
          first_color[0], first_color[1], first_color[2], 255,
          second_color[0], second_color[1], second_color[2], 255
        ]

        if (dxt1 && a <= b)
          color_values.push(
            (first_color[0] + second_color[0]) / 2,
            (first_color[1] + second_color[1]) / 2,
            (first_color[2] + second_color[2]) / 2,
            255,

            0,
            0,
            0,
            0
          )
        else
          color_values.push(
            lerp(first_color[0], second_color[0], 1 / 3),
            lerp(first_color[1], second_color[1], 1 / 3),
            lerp(first_color[2], second_color[2], 1 / 3),
            255,

            lerp(first_color[0], second_color[0], 2 / 3),
            lerp(first_color[1], second_color[1], 2 / 3),
            lerp(first_color[2], second_color[2], 2 / 3),
            255
          )
        end

      color_values
    end

    def convert_565_byte_to_rgb(byte)
      [
        ((byte >> 11) & 31) * (255 / 31),
        ((byte >> 5) & 63) * (255 / 63),
        (byte & 31) * (255 / 31)
      ]
    end

    def lerp(a, b, r)
      a * (1 - r) + b * r
    end
  end
end
