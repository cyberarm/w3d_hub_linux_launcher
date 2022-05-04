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
      background: 0xff_dedede,
      color: 0xaa_000000,
      text_size: 18,
      text_border: false,
      text_shadow: false
    },
    TextBlock: {
      font: BOLD_FONT,
      text_border: false,
      text_shadow: true,
      text_shadow_size: 1,
      text_shadow_color: 0x88_000000
    },
    EditLine: {
      border_thickness: 2,
      border_color: Gosu::Color::WHITE,
      hover: { color: Gosu::Color::WHITE }
    },
    Link: {
      color: 0xff_cdcdcd,
      hover: {
        color: Gosu::Color::WHITE
      },
      active: {
        color: 0xff_eeeeee
      }
    },
    Button: {
      text_size: 18,
      padding_top: 8,
      padding_left: 16,
      padding_right: 16,
      padding_bottom: 8,
      border_color: Gosu::Color::NONE,
      background: 0xff_00acff,
      hover: {
        background: 0xff_bee6fd
      },
      active: {
        background: 0xff_add5ec
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
      fraction_background: 0xff_00acff,
      border_thickness: 0
    }
  }
end
