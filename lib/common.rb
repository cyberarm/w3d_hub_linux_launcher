module W3DHubLauncher
  def self.ca_bundle_path
    [
      "/etc/ssl/certs/ca-certificates.crt", # Debian/Ubuntu
      "/etc/pki/tls/certs/ca-bundle.crt",   # RHEL/Fedora/CentOS
      "/etc/ssl/ca-bundle.pem"              # Some other distros
    ].find { |path| File.exist?(path) }
  end
end
