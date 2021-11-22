class W3DHub
  class ApplicationManager
    class Updater < Task
      def type
        :updater
      end

      def exec_task
        # Fetch manifests
        # Load manifests
        # build file list
        # find new packages
        # unpack new packages
        # TODO: detect patch files and handle them
        # update installed game version
      end
    end
  end
end
