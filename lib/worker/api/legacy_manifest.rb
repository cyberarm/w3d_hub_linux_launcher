module W3DHubLauncher
  class Worker
    class Api
      class LegacyManifest
        attr_reader :game, :type, :version, :base_version, :files, :dependencies

        def initialize(file_path)
          @document = REXML::Document.new(File.read(file_path))
          root = @document.root

          @game = root["game"]
          @type = root["type"]
          @version = root["version"]
          @base_version = root["baseVersion"]

          @files = []
          @dependencies = []

          parse_files
          parse_dependencies
        end

        def patch?
          @type == "Patch"
        end

        def full?
          @type == "Full"
        end

        def parse_files
          @document.root.elements.each("//File") do |element|
            @files.push(ManifestFile.new(element, @version))
          end
        end

        def parse_dependencies
          @document.root.elements.each("//Dependency") do |element|
            @dependencies.push(Dependency.new(element))
          end
        end

        class ManifestFile
          attr_reader :name, :checksum, :package, :patch_package, :removed_since, :from, :version

          def initialize(xml, version)
            @data = xml

            @name = @data["name"]
            @checksum = @data["checksum"]
            @package = @data["package"]
            @removed_since = @data["removedsince"]

            xml.elements.each("Patch") do |patch|
              @patch = true

              @from = patch["from"]

              if @package.to_s.empty?
                @package = patch["package"]
              else
                @patch_package = patch["package"]
              end
            end

            @version = version
          end

          def removed?
            @removed_since
          end

          def patch?
            @patch
          end

          def full_and_patch?
            @package && @patch_package
          end
        end

        class Dependency
          attr_reader :name, :removed_since

          def initialize(xml)
            @data = xml

            @name = @data["name"]
            @removed_since = @data["removed_since"]
          end
        end
      end
    end
  end
end
