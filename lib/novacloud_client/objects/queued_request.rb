# frozen_string_literal: true

require_relative "control_result"

module NovacloudClient
  module Objects
    # Represents the enqueue result for asynchronous player commands.
    class QueuedRequest < ControlResult
    end
  end
end
