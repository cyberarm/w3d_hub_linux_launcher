class W3DHub
  class ApplicationManager
    class Status
      attr_reader :application, :channel, :step, :operations, :data
      attr_accessor :label, :value, :progress

      def initialize(application:, channel:, label: "", value: "", progress: 0.0, step: :pending, operations: {}, &callback)
        @application = application
        @channel = channel

        @label = label
        @value = value
        @progress = progress

        @step = step
        @operations = operations

        @callback = callback

        @data = {}
      end

      def step=(sym)
        @step = sym
        @callback&.call(self)
        @step
      end

      class Operation
        attr_accessor :label, :value, :progress

        def initialize(label:, value:, progress:)
          @label = label
          @value = value
          @progress = progress
        end
      end
    end
  end
end
