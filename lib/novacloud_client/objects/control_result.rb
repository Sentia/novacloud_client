# frozen_string_literal: true

require_relative "base"

module NovacloudClient
  module Objects
    # Represents the result of a control or queued request returning success/fail lists.
    class ControlResult < Base
      attr_reader :successes, :failures

      def initialize(attributes = {})
        @successes = []
        @failures = []
        super
      end

      def success=(value)
        @successes = Array(value)
      end

      def fail=(value)
        @failures = Array(value)
      end

      def all_successful?
        failures.empty?
      end

      def partial_success?
        successes.any? && failures.any?
      end

      def all_failed?
        successes.empty?
      end

      def success_count
        successes.size
      end

      def failure_count
        failures.size
      end

      # Maintain API compatibility with camelCase keys.
      def success
        successes
      end

      def fail
        failures
      end
    end
  end
end
