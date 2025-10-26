# frozen_string_literal: true

require_relative "base"

module NovacloudClient
  module Objects
    # Represents an execution record for a remote control command.
    class ControlLogEntry < Base
      attr_accessor :status, :type
      attr_reader :execute_time

      def execute_time=(value)
        @execute_time = parse_timestamp(value)
      end

      def success?
        status.to_i.zero? ? false : status.to_i == 1
      end

      def executeTime=(value)
        self.execute_time = value
      end
    end
  end
end
