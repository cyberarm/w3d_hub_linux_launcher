module W3DHubLauncher
  LARGE_PADDING = 40
  PADDING = 20
  HALF_PADDING = 10
  ALPHA_BLACK = 0x88_000000

  FONT_LIGHT = "./media/fonts/NotoSans-Light.ttf"
  FONT_REGULAR = "./media/fonts/NotoSans-Regular.ttf"
  FONT_BOLD = "./media/fonts/NotoSans-Bold.ttf"
  FONT_BLACK = "./media/fonts/NotoSans-Black.ttf"

  FONT_MONO = "./media/fonts/NotoSansMono-Regular.ttf"

  CTA_BUTTON_THEME = {
    background: 0xff_1a5fb4
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
    Button: {
      font: FONT_BOLD,
      text_shadow: false,
      background: 0x88_5e5c64,
      border_thickness: 1,
      border_color: 0xff_000000
    },
    EditLine: {
      font: FONT_REGULAR
    },
    ListBox: {
      text_align: :left,
      text_size: 24,
      font: FONT_REGULAR,
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
      background: 0xee_000000,
      border_color: 0xaa_000000,
      hover: {
        background: 0xee_222222
      },
      active: {
        background: 0xee_444444
      }
    }
  }
end
