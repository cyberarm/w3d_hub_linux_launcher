class W3DHub
  THEME = {
    ToolTip: {
      background: 0xff_dedede,
      color: 0xaa_000000,
      text_size: 18,
      text_border: false,
      text_shadow: false
    },
    TextBlock: {
      # font: "Inconsolata",
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
      padding_left: 32,
      padding_right: 32,
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