# frozen_string_literal: true

require_relative "base"
require_relative "../objects/control_log_entry"

module NovacloudClient
  module Resources
    # Resource wrapper for log-related endpoints.
    class Logs < Base
      # Retrieve remote control execution history for a player.
      #
      # @param player_id [String] NovaCloud player identifier
      # @param start [Integer] pagination offset (defaults to 0)
      # @param count [Integer] number of records to request (defaults to 20)
      # @param task_type [Integer, nil] optional numeric filter defined by NovaCloud
      # @return [Array<NovacloudClient::Objects::ControlLogEntry>]
      def control_history(player_id:, start: 0, count: 20, task_type: nil)
        validate_presence!(player_id, "player_id")

        params = {
          "playerId" => player_id,
          "start" => start.to_s,
          "count" => count.to_s
        }
        params["taskType"] = task_type.to_s if task_type

        response = get("/v2/logs/remote-control", params: params)
        rows = response.fetch("rows", [])
        rows.map { |attrs| Objects::ControlLogEntry.new(attrs) }
      end

      private

      def validate_presence!(value, field)
        raise ArgumentError, "#{field} is required" if value.to_s.strip.empty?
      end
    end
  end
end
