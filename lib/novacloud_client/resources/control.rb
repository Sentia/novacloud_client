# frozen_string_literal: true

require_relative "base"
require_relative "../objects/control_result"
require_relative "../objects/queued_request"

module NovacloudClient
  module Resources
    # Resource wrapper for control commands.
    #
    # @example Set player brightness
    #   client.control.brightness(
    #     player_ids: ["player-1"],
    #     brightness: 80,
    #     notice_url: "https://example.com/callback"
    #   )
    #
    # @example Check a queued request
    #   request = client.control.reboot(player_ids: ["player-1"], notice_url: callback)
    #   client.control.request_result(request_id: request.request_id)
    class Control < Base
      MAX_BATCH = 100

      # Adjust brightness asynchronously for a batch of players.
      #
      # @param player_ids [Array<String>] NovaCloud player identifiers (max #{MAX_BATCH})
      # @param brightness [Integer] percentage value between 0 and 100
      # @param notice_url [String] HTTPS callback endpoint for async results
      # @return [NovacloudClient::Objects::QueuedRequest]
      # @raise [ArgumentError] when validation fails
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

      # Adjust volume asynchronously for a batch of players.
      #
      # @param player_ids [Array<String>] NovaCloud player identifiers (max #{MAX_BATCH})
      # @param volume [Integer] percentage value between 0 and 100
      # @param notice_url [String] HTTPS callback endpoint for async results
      # @return [NovacloudClient::Objects::QueuedRequest]
      # @raise [ArgumentError] when validation fails
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

      # Reboot one or more players asynchronously.
      #
      # @param player_ids [Array<String>] NovaCloud player identifiers (max #{MAX_BATCH})
      # @param notice_url [String] HTTPS callback endpoint for async results
      # @return [NovacloudClient::Objects::QueuedRequest]
      # @raise [ArgumentError] when validation fails
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

      # Fetch the aggregated result of a previously queued control request.
      #
      # @param request_id [String] identifier returned by the queueing endpoints
      # @return [NovacloudClient::Objects::ControlResult]
      # @raise [ArgumentError] when the request ID is blank
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
