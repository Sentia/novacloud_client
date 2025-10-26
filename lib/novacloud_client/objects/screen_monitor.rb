# frozen_string_literal: true

require_relative "base"

module NovacloudClient
  module Objects
    # Represents high-level monitoring metrics for a screen device.
    class ScreenMonitor < Base
      attr_accessor :display_device, :brightness, :env_brightness, :height, :width, :sn
    end
  end
end
