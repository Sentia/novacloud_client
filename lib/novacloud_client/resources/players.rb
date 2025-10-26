# frozen_string_literal: true

require_relative "base"
require_relative "../objects/player"
require_relative "../objects/player_status"
require_relative "../objects/queued_request"

module NovacloudClient
  module Resources
    # Resource wrapper for player-related endpoints.
    #
    # @example Fetch the first page of configured players
    #   client.players.list(count: 50)
    #
    # @example Fetch online status by player IDs
    #   client.players.statuses(player_ids: ["player-1", "player-2"])
    #
    # @example Request running status callbacks
    #   client.players.running_status(
    #     player_ids: ["player-1"],
    #     commands: ["screenshot"],
    #     notice_url: "https://example.com/callback"
    #   )
    class Players < Base
      MAX_BATCH = 100
      CONFIG_STATUS_COMMANDS = %w[
        volumeValue
        brightnessValue
        videoSourceValue
        timeValue
        screenPowerStatus
        syncPlayStatus
        powerStatus
      ].freeze

      # Retrieve players with optional pagination and fuzzy name filtering.
      #
      # @param start [Integer] pagination offset provided by NovaCloud (defaults to 0)
      # @param count [Integer] number of records to request (NovaCloud default is 20)
      # @param name [String, nil] optional fuzzy match on the player name
      # @return [Array<NovacloudClient::Objects::Player>]
      def list(start: 0, count: 20, name: nil)
        params = { start: start, count: count }
        params[:name] = name if name

        response = get("/v2/player/list", params: params)
        rows = response.fetch("rows", [])
        rows.map { |attrs| Objects::Player.new(attrs) }
      end

      # Retrieve current online status for a set of players.
      #
      # @param player_ids [Array<String>, nil] NovaCloud player identifiers (max #{MAX_BATCH})
      # @param player_sns [Array<String>, nil] player serial numbers (max #{MAX_BATCH})
      # @return [Array<NovacloudClient::Objects::PlayerStatus>]
      # @raise [ArgumentError] when no identifiers are provided
      def statuses(player_ids: nil, player_sns: nil)
        payload = build_status_payload(player_ids: player_ids, player_sns: player_sns)
        response = post("/v2/player/current/online-status", params: payload)
        Array(response).map { |attrs| Objects::PlayerStatus.new(attrs) }
      end

      # Enqueue a running-status command and receive a queued request reference.
      #
      # @param player_ids [Array<String>] NovaCloud player identifiers (max #{MAX_BATCH})
      # @param commands [Array<String>] running status command names defined by NovaCloud
      # @param notice_url [String] HTTPS callback endpoint for async results
      # @return [NovacloudClient::Objects::QueuedRequest]
      # @raise [ArgumentError] when validation fails
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

      # Convenience wrapper around `running_status` for configuration polling.
      # Uses NovaCloud's recommended command set by default.
      def config_status(player_ids:, notice_url:, commands: CONFIG_STATUS_COMMANDS)
        running_status(player_ids: player_ids, commands: commands, notice_url: notice_url)
      end

      # Delegate to the control resource for NTP time synchronization settings.
      def ntp_sync(player_ids:, server:, enable:)
        client.control.ntp_sync(player_ids: player_ids, server: server, enable: enable)
      end

      # Delegate to the control resource for synchronous playback toggles.
      def synchronous_playback(player_ids:, option:)
        client.control.synchronous_playback(player_ids: player_ids, option: option)
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
