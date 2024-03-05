class W3DHub
  REGULAR_FONT = "#{GAME_ROOT_PATH}/media/fonts/NotoSans-Regular.ttf"
  BOLD_FONT = "#{GAME_ROOT_PATH}/media/fonts/NotoSans-Bold.ttf"

  BORDER_COLOR = W3DHUB_DEVELOPER ? 0xff_ff8844 : 0xff_656565

  MAX_PAGE_WIDTH = 1200

  TESTING_BUTTON = {
    background: 0xff_ff8800,
    hover: {
      background: 0xff_ffaa00
    },
    active: {
      background: 0xff_ffec00
    }
  }

  UPDATE_BUTTON = TESTING_BUTTON

  THEME = {
    ToolTip: {
      background: 0xff_222222,
      color: 0xff_f2f2f2,
      text_size: 22,
      text_static: true,
      text_border: false,
      text_shadow: false
    },
    TextBlock: {
      font: REGULAR_FONT,
      color: 0xff_f2f2f2,
      text_static: true,
      text_border: false,
      text_shadow: true,
      text_shadow_size: 1,
      text_shadow_color: 0x88_000000
    },
    Banner: { # < TextBlock
      text_size: 48,
      font: BOLD_FONT
    },
    Title: { # < TextBlock
      text_size: 34,
      font: BOLD_FONT
    },
    Subtitle: { # < TextBlock
      text_size: 28,
      font: BOLD_FONT
    },
    Tagline: { # < TextBlock
      text_size: 26,
      font: BOLD_FONT
    },
    Caption: { # < TextBlock
      text_size: 24
    },
    Para: { # < TextBlock
      text_size: 22
    },
    Inscription: { # < TextBlock
      text_size: 18
    },
    Link: {
      color: 0xff_cdcdcd,
      hover: {
        color: 0xff_f2f2f2
      },
      active: {
        color: 0xff_eeeeee
      }
    },
    Button: {
      font: BOLD_FONT,
      color: 0xff_f2f2f2,
      text_size: 22,
      padding_top: 8,
      padding_left: 16,
      padding_right: 16,
      padding_bottom: 8,
      border_thickness: 2,
      border_color: Gosu::Color::NONE,
      background: 0xff_0074e0,
      hover: {
        color: 0xff_f2f2f2,
        background: 0xff_004c94,
        border_color: 0xff_0074e0
      },
      active: {
        color: 0xff_aaaaaa,
        background: 0xff_005aad,
        border_color: 0xff_0074e0
      }
    },
    EditLine: {
      font: REGULAR_FONT,
      color: 0xff_f2f2f2,
      background: 0xff_383838,
      border_thickness: 2,
      border_color: 0xff_0074e0,
      hover: {
        color: 0xff_f2f2f2,
        background: 0xff_323232,
        border_color: 0xff_0074e0
      },
      active: {
        color: 0xff_f2f2f2,
        background: 0xff_4b4b4b,
        border_color: 0xff_0074e0
      }
    },
    ToggleButton: {
      padding_left: 8,
      padding_right: 8,
      width: 18,
      image_width: 18,
      checkmark_image: "#{GAME_ROOT_PATH}/media/ui_icons/checkmark.png"
    },
    Progress: {
      background: 0xff_353535,
      fraction_background: 0xff_0074e0,
      border_thickness: 0
    },
    ListBox: {
      padding_left: 8,
      padding_right: 8
    },
    Slider: {
      border_color: 0xff_0074e0
    },
    Handle: {
      text_size: 22,
      padding_top: 8,
      padding_left: 2,
      padding_right: 2,
      padding_bottom: 8,
      border_color: Gosu::Color::NONE,
      background: 0xff_0074e0,
      hover: {
        background: 0xff_004c94
      },
      active: {
        background: 0xff_005aad
      }
    },
    Menu: {
      width: 200,
      border_color: 0xaa_efefef,
      border_thickness: 1
    },
    MenuItem: {
      width: 1.0,
      text_left: :left,
      margin: 0
    }
  }
end
