module W3DHubLauncher
  class Worker
    class Request
      Query = Data.define(:type, :request_id, :data)

      FETCH_URL = 0
      DOWNLOAD_URL = 1
      W3DHUB_API_CALL = 10
      LAUNCHER_SETTINGS = 1000
      LAUNCHER_UPDATE_SETTINGS = 1001

      STATUS_ERROR = -1 # request has failed
      STATUS_PENDING = 0 # request has not yet started
      STATUS_OK = 1 # request completed successfully
      STATUS_COMPLETE = STATUS_OK
      STATUS_IN_PROGRESS = 2 # request is in progress
      STATUS_BUSY = STATUS_IN_PROGRESS

      # NOT "Thread"/Ractor safe
      @request_id = 0
      @requests = []

      # NOT "Thread"/Ractor safe. Only call from main ractor
      # returns next available request id, and auto increments by 1
      def self.request_id
        @request_id += 1
      end

      # NOT "Thread"/Ractor safe.
      # returns an array of pending requests
      def self.requests
        @requests
      end

      attr_reader :type, :data, :request_id

      def initialize(type, data, request_id: Request.request_id, &block)
        @type = type.freeze
        @data = data.freeze
        @status = STATUS_PENDING

        @request_id = request_id
        @callback = block # only called on error or success

        enqueue(@type, @request_id, @data)
      end

      def enqueue(type, id, data)
        Request.requests << self
        W3DHubLauncher::WORKER.send(Query.new(type, id, data))
      end

      # event from Worker received
      def handle_event(event, data)
        pp [event, data]

        case event
        when STATUS_ERROR, STATUS_COMPLETE
          @callback&.call(data)
          Request.requests.delete(self)
        end
      end
    end
  end
end
