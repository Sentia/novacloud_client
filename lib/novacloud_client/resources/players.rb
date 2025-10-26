# frozen_string_literal: true

require_relative "base"
require_relative "../objects/player"
require_relative "../objects/player_status"
require_relative "../objects/queued_request"

module NovacloudClient
  module Resources
    # Resource wrapper for player-related endpoints.
    class Players < Base
      MAX_BATCH = 100

      def list(start: 0, count: 20, name: nil)
        params = { start: start, count: count }
        params[:name] = name if name

        response = get("/v2/player/list", params: params)
        rows = response.fetch("rows", [])
        rows.map { |attrs| Objects::Player.new(attrs) }
      end

      def statuses(player_ids: nil, player_sns: nil)
        payload = build_status_payload(player_ids: player_ids, player_sns: player_sns)
        response = post("/v2/player/current/online-status", params: payload)
        Array(response).map { |attrs| Objects::PlayerStatus.new(attrs) }
      end

      def running_status(player_ids:, commands:, notice_url:)
        validate_player_ids!(player_ids, max: MAX_BATCH)
        raise ArgumentError, "commands cannot be empty" if commands.nil? || commands.empty?
        raise ArgumentError, "notice_url is required" if notice_url.to_s.strip.empty?

        payload = {
          playerIds: player_ids,
          commands: commands,
          noticeUrl: notice_url
        }

        response = post("/v2/player/current/running-status", params: payload)
        Objects::QueuedRequest.new(response)
      end

      private

      def build_status_payload(player_ids:, player_sns:)
        payload = {}
        if player_ids
          validate_player_ids!(player_ids, max: MAX_BATCH)
          payload[:playerIds] = player_ids
        end
        if player_sns
          validate_player_ids!(player_sns, max: MAX_BATCH)
          payload[:playerSns] = player_sns
        end

        raise ArgumentError, "provide player_ids or player_sns" if payload.empty?

        payload
      end
    end
  end
end
