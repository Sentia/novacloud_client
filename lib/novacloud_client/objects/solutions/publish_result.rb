# frozen_string_literal: true

require_relative "../base"

module NovacloudClient
  module Objects
    module Solutions
      # Represents the publish result structure returned by solution endpoints.
      class PublishResult < Base
        attr_reader :successful, :failed

        def success=(value)
          @successful = Array(value).compact
        end

        def fail=(value)
          @failed = Array(value).compact
        end

        def all_successful?
          failed.empty?
        end

        def failed
          @failed ||= []
        end

        def successful
          @successful ||= []
        end
      end
    end
  end
end
