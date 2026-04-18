module W3DHubLauncher
  module Attribution
    Item = Data.define(:name, :description, :url, :license, :license_url)

    SPECIAL_THANKS = [
      Item.new("Yukihiro \"matz\" Matsumoto", "Creating the Ruby language", "https://matz.rubyist.net", "", ""),
      Item.new("Kenney", "Creating awesome game assets and releasing them completely for free.\nThe launcher uses their UI Icon pack.", "https://kenney.nl", "CC0", "https://creativecommons.org/publicdomain/zero/1.0/")
    ]

    LIBRARIES = [
      Item.new("Ruby", "Programming language. A Programmer's Best Friend", "https://ruby-lang.org", "2-clause BSDL", "https://www.ruby-lang.org/en/about/license.txt"),
      Item.new("gosu", "Light-weight game library", "https://libgosu.org", "MIT", "https://github.com/gosu/gosu/blob/master/COPYING"),
      Item.new("SDL2", "Simple DirectMedia Layer", "https://libsdl.org", "MIT", "https://github.com/libsdl-org/SDL/blob/SDL2/LICENSE.txt"),
      Item.new("MojoAL", "OpenAL sound library implementation in a single C file", "https://icculus.org/mojoAL/", "MIT", "https://github.com/icculus/mojoAL/blob/main/LICENSE.txt"),
    ]
  end
end
