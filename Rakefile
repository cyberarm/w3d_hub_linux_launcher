raise "OCRA doesn't work with Ruby 3.1.0" if RUBY_VERSION == "3.1.0"

# frozen_string_literal: true

require "releasy"
require "bundler/setup" # Releasy requires that your application uses bundler.
require_relative "lib/version"

Releasy::Project.new do
  name "W3D Hub Linux Launcher"
  version W3DHub::VERSION

  executable "w3d_hub_linux_launcher.rb"
  files ["lib/**/*.*", "locales/*", "media/**/**", "data/.gitkeep", "data/cache/.gitkeep", "data/logs/.gitkeep"]
  # exclude_encoding # Applications that don't use advanced encoding (e.g. Japanese characters) can save build size with this.
  verbose

  add_build :windows_folder do
    icon "media/icons/app.ico"
    executable_type :windows # :console # Assuming you don't want it to run with a console window.
    add_package :exe # Windows self-extracting archive.
  end
end