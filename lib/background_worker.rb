class W3DHub
  class BackgroundWorker
    LOG_TAG = "W3DHub::BackgroundWorker"
    @@instance = nil
    @@alive = false

    def self.create
      raise "BackgroundWorker instance already exists!" if @@instance
      logger.info(LOG_TAG) { "Starting background job worker..." }


      @@thread = Thread.current
      @@alive = true
      @@run = true
      @@instance = self.new

      @@instance.handle_jobs
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

    def self.busy?
      instance&.busy?
    end

    def self.shutdown!
      @@run = false
    end

    def self.kill!
      @@thread.kill

      @@instance.kill!
    end

    def self.job(job, callback, error_handler = nil)
      @@instance.add_job(Job.new(job: job, callback: callback, error_handler: error_handler))
    end

    def self.parallel_job(job, callback, error_handler = nil)
      @@instance.add_parallel_job(Job.new(job: job, callback: callback, error_handler: error_handler))
    end

    def self.foreground_job(job, callback, error_handler = nil)
      @@instance.add_job(Job.new(job: job, callback: callback, error_handler: error_handler, deliver_to_queue: true))
    end

    def self.foreground_parallel_job(job, callback, error_handler = nil)
      @@instance.add_parallel_job(Job.new(job: job, callback: callback, error_handler: error_handler, deliver_to_queue: true))
    end

    def initialize
      @busy = false
      @jobs = []

      # Jobs which are order independent
      @parallel_busy = false
      @thread_pool = []
      @parallel_jobs = []
    end

    def kill!
      @thread_pool.each(&:kill)

      logger.info(LOG_TAG) { "Forcefully killed background job worker." }
      @@alive = false
    end

    def handle_jobs
      8.times do |i|
        Thread.new do
          @thread_pool << Thread.current

          while BackgroundWorker.run?
            job = @parallel_jobs.shift

            @parallel_busy = true

            begin
              job&.do
            rescue => e
              job&.raise_error(e)
            end

            @parallel_busy = !@parallel_jobs.empty?

            sleep 0.1
          end
        end
      end

      Thread.new do
        @thread_pool << Thread.current

        while BackgroundWorker.run?
          job = @jobs.shift

          @busy = true

          begin
            job&.do
          rescue => e
            job&.raise_error(e)
          end

          @busy = !@jobs.empty?

          sleep 0.1
        end

        logger.info(LOG_TAG) { "Stopped background job worker." }
        @@alive = false
      end
    end

    def add_job(job)
      @jobs << job
    end

    def add_parallel_job(job)
      @parallel_jobs << job
    end

    def busy?
      @busy || @parallel_busy
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
