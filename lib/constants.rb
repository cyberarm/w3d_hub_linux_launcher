module W3DHubLauncher
  DIRECTORY_NAME = "w3d-hub-linux-launcher".freeze

  ROOT_PATH = Dir.pwd
  CONFIG_PATH = "#{Dir.home}/.config/#{DIRECTORY_NAME}".freeze
  CACHE_PATH = "#{Dir.home}/.cache/#{DIRECTORY_NAME}".freeze
  DEFAULT_PACKAGE_CACHE_PATH = "#{CACHE_PATH}/packages".freeze
  DEFAULT_APPLICATIONS_PATH = "#{Dir.home}/.local/share/#{DIRECTORY_NAME}/applications".freeze

  USER_AGENT = "#{NAME} v#{VERSION}".freeze
end
