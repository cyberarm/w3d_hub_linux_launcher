module W3DHubLauncher
  def self.ca_bundle_path
    [
      "/etc/ssl/certs/ca-certificates.crt", # Debian/Ubuntu
      "/etc/pki/tls/certs/ca-bundle.crt",   # RHEL/Fedora/CentOS
      "/etc/ssl/ca-bundle.pem"              # Some other distros
    ].find { |path| File.exist?(path) }
  end

  def self.format_size(bytes)
    case bytes
    when 0..1023 # Bytes
      "#{bytes} B"
    when 1024..1_048_575 # KiloBytes
      "#{format_size_number(bytes / 1024.0)} KB"
    when 1_048_576..1_073_741_999 # MegaBytes
      "#{format_size_number(bytes / 1_048_576.0)} MB"
    else # GigaBytes
      "#{format_size_number(bytes / 1_073_742_000.0)} GB"
    end
  end

  def self.format_size_number(i)
    format("%0.2f", i)
  end
end
