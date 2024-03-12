source "https://rubygems.org"

gem "base64"
gem "excon"
gem "cyberarm_engine"
gem "sdl2-bindings"
gem "libui", platforms: [:windows]
gem "digest-crc"
gem "i18n"
gem "ircparser"
gem "rexml"
gem "rubyzip"
gem "websocket-client-simple"
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