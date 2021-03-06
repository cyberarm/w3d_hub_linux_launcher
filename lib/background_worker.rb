class W3DHub
  class BackgroundWorker
    LOG_TAG = "W3DHub::BackgroundWorker"
    @@instance = nil
    @@alive = false

    def self.create
      raise "BackgroundWorker instance already exists!" if @@instance
      logger.info(LOG_TAG) { "Starting background job worker..." }


      @@alive = true
      @@run = true
      @@instance = self.new

      Async do
        @@instance.handle_jobs
      end
    end

    def self.instance
      @@instance
    end

    def self.run?
      @@run
    end

    def self.alive?
      @@alive
    end

    def self.shutdown!
      @@run = false
    end

    def self.job(job, callback, error_handler = nil)
      @@instance.add_job(Job.new(job: job, callback: callback, error_handler: error_handler))
    end

    def self.foreground_job(job, callback, error_handler = nil)
      @@instance.add_job(Job.new(job: job, callback: callback, error_handler: error_handler, deliver_to_queue: true))
    end

    def initialize
      @jobs = []
    end

    def handle_jobs
      while BackgroundWorker.run?
        job = @jobs.shift

        begin
          job&.do
        rescue => error
          job&.raise_error(error)
        end

        sleep 0.1
      end

      logger.info(LOG_TAG) { "Stopped background job worker." }
      @@alive = false
    end

    def add_job(job)
      @jobs << job
    end

    class Job
      def initialize(job:, callback:, error_handler: nil, deliver_to_queue: false)
        @job = job
        @callback = callback
        @error_handler = error_handler

        @deliver_to_queue = deliver_to_queue
      end

      def do
        result = @job.call
        deliver(result)
      end

      def deliver(result)
        if @deliver_to_queue
          Store.main_thread_queue << -> { @callback.call(result) }
        else
          @callback.call(result)
        end
      end

      def raise_error(error)
        logger.error error
        @error_handler&.call(error)
      end
    end
  end
end
