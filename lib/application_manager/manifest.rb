class W3DHub
  class ApplicationManager
    class Manifest
      attr_reader :game, :type, :version, :base_version, :files, :dependencies

      def initialize(category, subcategory, name, version)
        manifest = File.read(Cache.package_path(category, subcategory, name, version))
        @document = REXML::Document.new(manifest)
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

      # TODO: Support patches
      class ManifestFile
        attr_reader :name, :checksum, :package, :removed_since, :from, :version

        def initialize(xml, version)
          @data = xml

          @name = @data["name"]
          @checksum = @data["checksum"]
          @package = @data["package"]
          @removed_since = @data["removedsince"]

          xml.elements.each("Patch") do |patch|
            @patch = true

            @from = patch["from"]
            @package = patch["package"]
          end

          @version = version
        end

        def removed?
          @removed_since
        end

        def patch?
          @patch
        end
      end

      class Dependency
        attr_reader :name

        def initialize(xml)
          @data = xml

          @name = @data["name"]
        end
      end
    end
  end
end
