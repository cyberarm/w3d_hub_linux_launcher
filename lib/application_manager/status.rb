class W3DHub
  class ApplicationManager
    class Status
      attr_reader :application, :channel, :operations, :data
      attr_accessor :label, :value, :progress, :step

      def initialize(application:, channel:, label: "", value: "", progress: 0.0, step: :pending, operations: {})
        @application = application
        @channel = channel

        @label = label
        @value = value
        @progress = progress

        @step = step
        @operations = operations


        @data = {}
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
