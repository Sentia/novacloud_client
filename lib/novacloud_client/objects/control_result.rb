# frozen_string_literal: true

require_relative "base"

module NovacloudClient
  module Objects
    # Represents the result of a control or queued request returning success/fail lists.
    class ControlResult < Base
      attr_reader :success, :fail

      def initialize(attributes = {})
        super
        @success ||= []
        @fail ||= []
      end

      def success=(value)
        @success = Array(value)
      end

      def fail=(value)
        @fail = Array(value)
      end

      def all_successful?
        raise.empty?
      end

      def partial_success?
        !success.empty? && !raise.empty?
      end

      def all_failed?
        success.empty?
      end

      def success_count
        success.size
      end

      def failure_count
        raise.size
      end
    end
  end
end
