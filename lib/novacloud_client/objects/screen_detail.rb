# frozen_string_literal: true

require_relative "base"

module NovacloudClient
  module Objects
    # Represents detailed telemetry for a screen, including nested hardware info.
    class ScreenDetail < Base
      attr_accessor :identifier, :input_source, :mac, :master_control, :module,
                    :monitor_card, :receiving_card, :screen, :sid, :smart_module, :sn

      def initialize(attributes = {})
        super
        @input_source ||= {}
        @master_control ||= {}
        @module ||= {}
        @monitor_card ||= {}
        @receiving_card ||= {}
        @screen ||= {}
        @smart_module ||= {}
      end

      def inputSource=(value)
        self.input_source = value
      end

      def masterControl=(value)
        self.master_control = value
      end

      def monitorCard=(value)
        self.monitor_card = value
      end

      def receivingCard=(value)
        self.receiving_card = value
      end

      def smartModule=(value)
        self.smart_module = value
      end
    end
  end
end
