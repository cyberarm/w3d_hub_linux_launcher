class W3DHub
  class ApplicationManager
    class Pool
      def initialize(workers:)
        @workers = workers.times.collect { Worker.new }
        @jobs = []
      end

      def add_job(job)
        @jobs << job
      end

      def manage_pool
        while @jobs.size.positive? || @workers.any?(&:busy?)
          feed_pool unless @jobs.size.zero?

          sleep 0.1
        end
      end

      def feed_pool
        @workers.select(&:available?).each do |worker|
          worker.feed(@jobs.shift)
        end
      end

      class Worker
        def initialize
          @die = false
          @job = nil

          Thread.new do
            until (@die)
              @job.process if @job&.waiting?
              @job = nil
              sleep 0.1
            end
          end
        end

        def feed(job)
          raise "Worker already processing a job!" if @job&.processing?

          @job = job
        end

        def die!
          @die = true
        end

        def available?
          @job.nil?
        end

        def busy?
          !available?
        end
      end

      class Job
        def initialize(block)
          @block = block

          @state = :waiting
        end

        def waiting?
          @state == :waiting
        end

        def processing?
          @state == :processing
        end

        def complete?
          @state == :complete
        end

        def process
          @state = :processing

          @block.call

          @state == :complete
        end
      end
    end
  end
end