# frozen_string_literal: true

require_relative "base"

module NovacloudClient
  module Objects
    # Represents detailed telemetry for a screen, including nested hardware info.
    class ScreenDetail < Base
      attr_accessor :identifier, :input_source, :mac, :master_control, :module,
                    :monitor_card, :receiving_card, :screen, :sid, :smart_module, :sn

      NESTED_HASH_FIELDS = %i[input_source master_control module monitor_card receiving_card screen smart_module].freeze

      def initialize(attributes = {})
        super
        ensure_nested_hashes!
      end

      private

      def ensure_nested_hashes!
        NESTED_HASH_FIELDS.each do |field|
          value = public_send(field)
          public_send("#{field}=", value || {})
        end
      end
    end
  end
end
