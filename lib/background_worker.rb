class W3DHub
  class BackgroundWorker
    @@instance = nil
    @@alive = false

    def self.create
      raise "BackgroundWorker instance already exists!" if @@instance

      @@alive = true
      @@instance = self.new

      Async do
        @@instance.handle_jobs
      end
    end

    def self.instance
      @@instance
    end

    def self.alive?
      @@alive
    end

    def self.shutdown!
      @@alive = false
    end

    def self.job(job, callback)
      @@instance.add_job(Job.new(job, callback))
    end

    def self.foreground_job(job, callback)
      @@instance.add_job(Job.new(job, callback, true))
    end

    def initialize
      @jobs = []
    end

    def handle_jobs
      while BackgroundWorker.alive?
        job = @jobs.shift

        job&.do

        sleep 0.1
      end
    end

    def add_job(job)
      @jobs << job
    end

    class Job
      def initialize(job, callback, deliver_to_queue = false)
        @job = job
        @callback = callback

        @deliver_to_queue = deliver_to_queue
      end

      def do
        result = @job.call
        deliver(result)
      end

      def deliver(result)
        if @deliver_to_queue
          $window.main_thread_queue << -> { @callback.call(result) }
        else
          @callback.call(result)
        end
      end
    end
  end
end
