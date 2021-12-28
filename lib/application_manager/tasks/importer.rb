class W3DHub
  class ApplicationManager
    class Importer < Task
      def type
        :importer
      end

      def execute_task
        path = ask_file

        unless File.exist?(path) && !File.directory?(path)
          fail!("File #{path.inspect} does not exist or is a directory")
          fail_silently! if path.nil? || path&.length&.zero? # User likely canceled the file selection
        end

        return false if failed?

        Store.application_manager.imported!(self, path)

        true
      end

      def ask_file(title: "Open File", filter: "*game*.exe")
        if W3DHub.unix?
          # search for command
          cmds = %w{ zenity matedialog qarma kdialog }

          command = cmds.find do |cmd|
            cmd if system("which #{cmd}")
          end

          path = case File.basename(command)
          when "zenity", "matedialog", "qarma"
            `#{command} --file-selection --title "#{title}" --file-filter "#{filter}"`
          when "kdialog"
            `#{command} --title "#{title}" --getopenfilename . "#{filter}"`
          else
            raise "No known command found for system file selection dialog!"
          end

          path.strip
        else
          raise NotImplementedError
        end
      end
    end
  end
end
