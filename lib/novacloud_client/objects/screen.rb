# frozen_string_literal: true

require_relative "base"

module NovacloudClient
  module Objects
    # Represents a screen/device entry from VNNOXCare APIs.
    class Screen < Base
      attr_accessor :sid, :name, :mac, :sn, :address, :longitude, :latitude,
                    :status, :camera, :brightness, :env_brightness

      def online?
        status.to_i == 1
      end

      def camera_enabled?
        camera.to_i == 1
      end
    end
  end
end
