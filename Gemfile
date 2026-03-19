source "https://rubygems.org"

# "standard lib" gems
gem "base64"
gem "rexml"
gem "logger"

# networking libs
gem "async-http"
gem "async-websocket"

# "game" library gem
gem "cyberarm_engine"
gem "sdl2-bindings"

# misc. libs
gem "digest-crc"
gem "ircparser"
gem "rubyzip"

# file selection dialogs on windows (SDL3 has these built-in, but we're on SDL2)
gem "libui", platforms: [:windows]
# misc. windows only gems
gem "win32-process", platforms: [:windows]
gem "win32-security", platforms: [:windows]

# PACKAGING NOTES
# bundler 2.5.x doesn't seem to play nice with ocra[n]
# use `bundle _x.y.z_ COMMAND` to use this one...
# NOTE: Releasy needs to be installed as a system gem i.e. `rake install`
# NOTE: contents of the `gemhome` folder in the packaged folder need to be moved into the lib/ruby/gems\<RUBY_VERSION> folder
# group :windows_packaging do
#   gem "bundler", "~>2.4.3"
#   gem "rake"
#   gem "ocran"
#   gem "releasy"#, path: "../releasy"
# end
