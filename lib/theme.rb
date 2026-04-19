module W3DHubLauncher
  LARGE_PADDING = 40
  PADDING = 20
  HALF_PADDING = 10
  ALPHA_BLACK = 0x88_000000
  ALPHA_GRAY = 0x88_5e5c64

  FONT_LIGHT = "./media/fonts/NotoSans-Light.ttf"
  FONT_REGULAR = "./media/fonts/NotoSans-Regular.ttf"
  FONT_BOLD = "./media/fonts/NotoSans-Bold.ttf"
  FONT_BLACK = "./media/fonts/NotoSans-Black.ttf"

  FONT_MONO = "./media/fonts/NotoSansMono-Regular.ttf"

  NINE_SLICE_EDGE = 8
  NINE_SLICE_EDGE_SMALL = 4
  NINE_SLICE_EDGE_TINY = 2
  NINE_SLICE_ROUNDED = "./media/ui/rounded.png"
  NINE_SLICE_ROUNDED_SMALL = "./media/ui/rounded_small.png"
  NINE_SLICE_ROUNDED_TINY = "./media/ui/rounded_small.png"
  NINE_SLICE_ROUNDED_LEFT = "./media/ui/rounded_left.png"
  NINE_SLICE_ROUNDED_RIGHT = "./media/ui/rounded_right.png"
  NINE_SLICE_ROUNDED_TOP = "./media/ui/rounded_top.png"
  NINE_SLICE_ROUNDED_BOTTOM = "./media/ui/rounded_bottom.png"
  NINE_SLICE_SQUARE = "./media/ui/square.png"

  CTA_BUTTON_THEME = {
    color: 0xff_ffffff,
    background_nine_slice_color: 0xff_1c71d8,
    hover: {
      color: 0xff_ffffff,
      background_nine_slice_color: 0xff_3584e4
    },
    active: {
      color: 0xff_ffffff,
      background_nine_slice_color: 0xff_1a5fb4
    }
  }

  THEME = {
    TextBlock: {
      text_static: true,
      font: FONT_REGULAR,
      text_shadow: true,
      text_shadow_color: 0x44_000000
    },
    Link: {
      font: FONT_REGULAR,
      color: 0xff_bbbbbb,
      hover: {
        color: 0xff_ffffff
      },
      active: {
        color: 0xff_888888
      }
    },
    Inscription: {
      text_size: 18
    },
    Para: {
      text_size: 20
    },
    Caption: {
      font: FONT_BOLD
    },
    Tagline: {
      font: FONT_BOLD
    },
    Title: {
      font: FONT_BOLD
    },
    Banner: {
      font: FONT_BLACK
    },
    Button: {
      font: FONT_BOLD,
      text_shadow: false,
      color: 0xff_ffffff,
      background: 0,#x88_5e5c64,
      background_nine_slice: NINE_SLICE_ROUNDED,
      background_nine_slice_from_edge: NINE_SLICE_EDGE,
      background_nine_slice_mode: :stretched,
      background_nine_slice_color: 0x88_5e5c64,
      border_thickness: 0,
      hover: {
        color: 0xcc_ffffff,
        background: 0,
        background_nine_slice_color: 0xff_5e5c64
      },
      active: {
        color: 0x88_ffffff,
        background: 0,
        background_nine_slice_color: 0xaa_5e5c64
      }
    },
    EditLine: {
      font: FONT_REGULAR
    },
    ListBox: {
      text_align: :left,
      text_size: 24,
      font: FONT_REGULAR,
      padding_left: HALF_PADDING
      # background: 0xaa_000000,
      # border_color: 0xff_000000,
      # hover: {
      #   background: 0xaa_222222
      # },
      # active: {
      #   background: 0xaa_444444
      # }
    },
    Menu: {
      border_thickness: 1,
      border_color: 0xff_000000
    },
    MenuItem: {
      text_size: 24,
      text_align: :left,
      font: FONT_REGULAR,
      background_nine_slice: NINE_SLICE_SQUARE,
      background: 0xee_000000,
      border_color: 0xaa_000000,
      hover: {
        background: 0xee_222222
      },
      active: {
        background: 0xee_444444
      }
    },
    Progress: {
      height: NINE_SLICE_EDGE_TINY * 2,
      background: 0,
      background_nine_slice: NINE_SLICE_ROUNDED_TINY,
      background_nine_slice_from_edge: NINE_SLICE_EDGE_TINY,
      background_nine_slice_mode: :stretched,
      background_nine_slice_color: 0x88_5e5c64,
      fraction_background: 0xff_1a5fb4,
      border_thickness: 0,
    },
    ToolTip: {
      delay: 500,
      text_size: 24,
      background: 0,#x88_5e5c64,
      background_nine_slice: NINE_SLICE_ROUNDED,
      background_nine_slice_from_edge: NINE_SLICE_EDGE,
      background_nine_slice_mode: :stretched,
      background_nine_slice_color: 0xcc_000000,
      border_thickness: 0
    }
  }
end
