# frozen_string_literal: true

require_relative "base"
require_relative "../objects/control_result"
require_relative "../objects/queued_request"

module NovacloudClient
  module Resources
    # Resource wrapper for control commands.
    class Control < Base
      MAX_BATCH = 100

      def brightness(player_ids:, brightness:, notice_url:)
        validate_player_ids!(player_ids, max: MAX_BATCH)
        validate_percentage!(brightness, "brightness")
        validate_notice_url!(notice_url)

        payload = {
          playerIds: player_ids,
          brightness: brightness,
          noticeUrl: notice_url
        }

        response = post("/v2/player/control/brightness", params: payload)
        Objects::QueuedRequest.new(response)
      end

      def volume(player_ids:, volume:, notice_url:)
        validate_player_ids!(player_ids, max: MAX_BATCH)
        validate_percentage!(volume, "volume")
        validate_notice_url!(notice_url)

        payload = {
          playerIds: player_ids,
          volume: volume,
          noticeUrl: notice_url
        }

        response = post("/v2/player/control/volume", params: payload)
        Objects::QueuedRequest.new(response)
      end

      def reboot(player_ids:, notice_url:)
        validate_player_ids!(player_ids, max: MAX_BATCH)
        validate_notice_url!(notice_url)

        payload = {
          playerIds: player_ids,
          noticeUrl: notice_url
        }

        response = post("/v2/player/control/reboot", params: payload)
        Objects::QueuedRequest.new(response)
      end

      def request_result(request_id:)
        raise ArgumentError, "request_id is required" if request_id.to_s.strip.empty?

        response = get("/v2/player/control/request-result", params: { requestId: request_id })
        Objects::ControlResult.new(response)
      end

      private

      def validate_percentage!(value, field)
        return if value.is_a?(Integer) && value.between?(0, 100)

        raise ArgumentError, "#{field} must be an integer between 0 and 100"
      end

      def validate_notice_url!(notice_url)
        raise ArgumentError, "notice_url is required" if notice_url.to_s.strip.empty?
      end
    end
  end
end
