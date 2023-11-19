class W3DHub
  class ApplicationManager
    class Uninstaller < Task
      LOG_TAG = "W3DHub::ApplicationManager::Uninstaller".freeze

      def type
        :uninstaller
      end

      def execute_task
        # TODO: cherrypick or nuke installation folder
        # A:
        #   fetch manifests
        #   load manifests
        #   build list of files
        #   delete list of files
        # B:
        #   Nuke installation folder
        # mark application as uninstalled

        show_application_taskbar

        remove_installation_directory
        mark_application_uninstalled

        sleep 1
        hide_application_taskbar

        true
      end

      def remove_installation_directory
        @status.operations.clear
        @status.label = "Uninstalling #{@application.name}"
        @status.value = "Purging installation folder..."
        @status.progress = Float::INFINITY

        @status.step = :uninstalling_application

        path = Cache.install_path(@application, @channel)

        logger.info(LOG_TAG) { path }
        # TODO: Do some sanity checking, i.e. DO NOT start launcher if `whoami` returns root, path makes sense,
        #       we're not on Windows trying to uninstall a game likely installed by the official launcher
        FileUtils.remove_dir(path)
      end

      def mark_application_uninstalled
        Store.application_manager.uninstalled!(self)

        @status.operations.clear
        @status.label = "Uninstalled #{@application.name}"
        @status.value = ""
        @status.progress = 1.0

        @status.step = :mark_application_uninstalled

        logger.info(LOG_TAG) { "#{@app_id} has been uninstalled." }
      end
    end
  end
end