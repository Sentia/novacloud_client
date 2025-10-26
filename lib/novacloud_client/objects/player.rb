# frozen_string_literal: true

require_relative "base"

module NovacloudClient
  module Objects
    # Represents a player returned from NovaCloud player APIs.
    class Player < Base
      attr_accessor :player_id, :player_type, :name, :sn, :version, :ip
      attr_reader :last_online_time, :online_status

      def last_online_time=(value)
        @last_online_time = parse_timestamp(value)
      end

      def online_status=(value)
        @online_status = value.to_i
      end

      def online?
        online_status == 1
      end

      def offline?
        !online?
      end

      def synchronous?
        player_type.to_i == 1
      end

      def asynchronous?
        player_type.to_i == 2
      end
    end
  end
end
