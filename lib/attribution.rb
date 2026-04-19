module W3DHubLauncher
  module Attribution
    Item = Data.define(:name, :description, :url, :license, :license_url)

    SPECIAL_THANKS = [
      Item.new("W3D Hub", "Creating awesome games and mods for free", "https://w3dhub.com", "", ""),
      Item.new("Yukihiro \"matz\" Matsumoto", "Creating the Ruby language", "https://matz.rubyist.net", "", ""),
      Item.new("Samuel \"ioquatix\" Williams", "Creating and maintaining the async libraries for Ruby", "https://www.codeotaku.com", "", ""),
      Item.new("Kenney", "Creating awesome game assets and releasing them completely for free\nThe launcher uses their UI Icon pack", "https://kenney.nl", "CC0", "https://creativecommons.org/publicdomain/zero/1.0/"),
    ]

    LIBRARIES = [
      Item.new("Ruby", "Programming language. A Programmer's Best Friend", "https://ruby-lang.org", "BSD 2-Clause", "https://www.ruby-lang.org/en/about/license.txt"),
      Item.new("gosu", "Light-weight game library", "https://libgosu.org", "MIT", "https://github.com/gosu/gosu/blob/master/COPYING"),
      Item.new("SDL2", "Simple DirectMedia Layer", "https://libsdl.org", "MIT", "https://github.com/libsdl-org/SDL/blob/SDL2/LICENSE.txt"),
      Item.new("MojoAL", "OpenAL sound library implementation in a single C file", "https://icculus.org/mojoAL/", "MIT", "https://github.com/icculus/mojoAL/blob/main/LICENSE.txt"),

      Item.new("async", "Asynchronous event-driven reactor for Ruby", "https://github.com/socketry/async", "MIT", "https://github.com/socketry/async/blob/main/license.md"),
      Item.new("async-http", "Asynchronous http(s) client/server for Ruby", "https://github.com/socketry/async-http", "MIT", "https://github.com/socketry/async-http/blob/main/license.md"),
      Item.new("async-websocket", "Asynchronous websockets for Ruby", "https://github.com/socketry/async-websocket", "MIT", "https://github.com/socketry/async-websocket/blob/main/license.md"),
      Item.new("rubyzip", "Ruby library for reading and writing zip files", "https://github.com/rubyzip/rubyzip", "BSD 2-Clause", "https://github.com/rubyzip/rubyzip/blob/main/LICENSE.md"),
      Item.new("digest-crc", "Ruby library for reading and writing zip files", "https://github.com/postmodern/digest-crc", "MIT", "https://github.com/postmodern/digest-crc/blob/main/LICENSE.txt"),
      Item.new("ircparser", "Ruby parser for the IRCv3 message format", "https://codeberg.org/sadiepowell/ircparser-ruby", "MIT", "https://codeberg.org/sadiepowell/ircparser-ruby#license"),

      Item.new("base64", "Ruby library for encoding and decoding base64", "https://github.com/ruby/base64", "BSD 2-Clause", "https://github.com/ruby/base64/blob/master/COPYING"),
      Item.new("rexml", "Ruby library for parsing XML", "https://github.com/ruby/rexml", "BSD 2-Clause", "https://github.com/ruby/rexml/blob/master/LICENSE.txt"),
      Item.new("logger", "Ruby logging library", "https://github.com/ruby/logger", "BSD 2-Clause", "https://github.com/ruby/logger/blob/master/COPYING"),
    ]
  end
end
