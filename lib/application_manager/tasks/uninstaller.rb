class W3DHub
  class ApplicationManager
    class Uninstaller < Task
      def type
        :uninstaller
      end

      def exec_task
        # TODO: cherrypick or nuke installation folder
        # A:
        #   fetch manifests
        #   load manifests
        #   build list of files
        #   delete list of files
        # B:
        #   Nuke installation folder
        # mark application as uninstalled
      end
    end
  end
end