# frozen_string_literal: true

require_relative "control_result"

module NovacloudClient
  module Objects
    # Represents the enqueue result for asynchronous player commands.
    class QueuedRequest < ControlResult
      attr_reader :request_id

      # Queue responses include a request ID used to poll for results later.
      def request_id=(value)
        @request_id = value&.to_s
      end
    end
  end
end
