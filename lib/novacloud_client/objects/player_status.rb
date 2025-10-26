# frozen_string_literal: true

require_relative "base"

module NovacloudClient
  module Objects
    # Represents basic status information for a player.
    class PlayerStatus < Base
      attr_accessor :player_id, :sn
      attr_reader :online_status, :last_online_time

      def online_status=(value)
        @online_status = value.to_i
      end

      def last_online_time=(value)
        @last_online_time = parse_timestamp(value)
      end

      def online?
        online_status == 1
      end

      def offline?
        !online?
      end
    end
  end
end
