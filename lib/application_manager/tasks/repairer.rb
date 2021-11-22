class W3DHub
  class ApplicationManager
    class Repairer < Task
      def type
        :repairer
      end

      def exec_task
        # fetch manifests
        # load manifests
        # run presence and checksum checks
        # extract and re/place broken/missing files
        #   if a large number of files are missing from a single package
        #     simply reextract the whole thing
        # mark application as installed/repaired
      end
    end
  end
end