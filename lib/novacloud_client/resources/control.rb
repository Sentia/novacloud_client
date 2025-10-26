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
        validate_percentage!(brightness, "brightness")
        enqueue_control(
          endpoint: "/v2/player/real-time-control/brightness",
          player_ids: player_ids,
          notice_url: notice_url,
          extra_payload: { brightness: brightness }
        )
      end

      # Adjust volume asynchronously for a batch of players.
      #
      # @param player_ids [Array<String>] NovaCloud player identifiers (max #{MAX_BATCH})
      # @param volume [Integer] percentage value between 0 and 100
      # @param notice_url [String] HTTPS callback endpoint for async results
      # @return [NovacloudClient::Objects::QueuedRequest]
      # @raise [ArgumentError] when validation fails
      def volume(player_ids:, volume:, notice_url:)
        validate_percentage!(volume, "volume")
        enqueue_control(
          endpoint: "/v2/player/real-time-control/volume",
          player_ids: player_ids,
          notice_url: notice_url,
          extra_payload: { volume: volume }
        )
      end

      # Switch the video input source (e.g., HDMI1) for the selected players.
      #
      # @param player_ids [Array<String>] NovaCloud player identifiers (max #{MAX_BATCH})
      # @param source [String] identifier for the input source defined by NovaCloud (e.g., "HDMI1")
      # @param notice_url [String] HTTPS callback endpoint for async results
      # @return [NovacloudClient::Objects::QueuedRequest]
      # @raise [ArgumentError] when validation fails
      def video_source(player_ids:, source:, notice_url:)
        validate_presence!(source, "source")
        enqueue_control(
          endpoint: "/v2/player/real-time-control/video-source",
          player_ids: player_ids,
          notice_url: notice_url,
          extra_payload: { videoSource: source }
        )
      end

      # Toggle screen power state for the selected players.
      #
      # @param player_ids [Array<String>] NovaCloud player identifiers (max #{MAX_BATCH})
      # @param state [Symbol, String, Integer, TrueClass, FalseClass] desired power state
      #   (:on, :off, true, false, 1, or 0)
      # @param notice_url [String] HTTPS callback endpoint for async results
      # @return [NovacloudClient::Objects::QueuedRequest]
      # @raise [ArgumentError] when validation fails
      def screen_power(player_ids:, state:, notice_url:)
        payload = { option: normalize_power_state(state) }
        enqueue_control(
          endpoint: "/v2/player/real-time-control/power",
          player_ids: player_ids,
          notice_url: notice_url,
          extra_payload: payload
        )
      end

      # Request a black screen/normal screen toggle for the selected players.
      #
      # @param player_ids [Array<String>] NovaCloud player identifiers (max #{MAX_BATCH})
      # @param status [String, Symbol] desired screen mode (:open, :close, "OPEN", "CLOSE")
      # @param notice_url [String] HTTPS callback endpoint for async results
      # @return [NovacloudClient::Objects::QueuedRequest]
      # @raise [ArgumentError] when validation fails
      def screen_status(player_ids:, status:, notice_url:)
        payload = { status: normalize_screen_status(status) }
        enqueue_control(
          endpoint: "/v2/player/real-time-control/screen-status",
          player_ids: player_ids,
          notice_url: notice_url,
          extra_payload: payload
        )
      end

      # Trigger screenshots for the selected players.
      #
      # @param player_ids [Array<String>] NovaCloud player identifiers (max #{MAX_BATCH})
      # @param notice_url [String] HTTPS callback endpoint receiving screenshot info
      # @return [NovacloudClient::Objects::QueuedRequest]
      # @raise [ArgumentError] when validation fails
      def screenshot(player_ids:, notice_url:)
        enqueue_control(
          endpoint: "/v2/player/real-time-control/screen-capture",
          player_ids: player_ids,
          notice_url: notice_url
        )
      end

      # Reboot one or more players asynchronously.
      #
      # @param player_ids [Array<String>] NovaCloud player identifiers (max #{MAX_BATCH})
      # @param notice_url [String] HTTPS callback endpoint for async results
      # @return [NovacloudClient::Objects::QueuedRequest]
      # @raise [ArgumentError] when validation fails
      def reboot(player_ids:, notice_url:)
        enqueue_control(
          endpoint: "/v2/player/real-time-control/reboot",
          player_ids: player_ids,
          notice_url: notice_url
        )
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

      def validate_presence!(value, field)
        raise ArgumentError, "#{field} is required" if value.to_s.strip.empty?
      end

      def enqueue_control(endpoint:, player_ids:, notice_url:, extra_payload: {})
        validate_player_ids!(player_ids, max: MAX_BATCH)
        validate_notice_url!(notice_url)

        payload = { playerIds: player_ids }
        payload.merge!(extra_payload)
        payload[:noticeUrl] = notice_url

        response = post(endpoint, params: payload)
        Objects::QueuedRequest.new(response)
      end

      def normalize_power_state(state)
        case state
        when true, :on, "on", "ON", 1 then 1
        when false, :off, "off", "OFF", 0 then 0
        else
          raise ArgumentError, "state must be one of :on, :off, true, false, or 0/1"
        end
      end

      def normalize_screen_status(status)
        case status
        when :open, "open", "OPEN" then "OPEN"
        when :close, "close", "CLOSE", :closed then "CLOSE"
        else
          raise ArgumentError, "status must be OPEN or CLOSE"
        end
      end
    end
  end
end
