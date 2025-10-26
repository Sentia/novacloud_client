# frozen_string_literal: true

require_relative "base"
require_relative "../objects/solutions/publish_result"
require_relative "../support/key_transform"

module NovacloudClient
  module Resources
    # Resource wrapper for solution publishing workflows.
    class Solutions < Base
      # Publish a single-page emergency insertion program.
      #
      # @param player_ids [Array<String>] target players
      # @param attribute [Hash, #to_h] emergency-specific metadata
      # @param page [Hash, #to_h] definition of the single emergency page
      # @return [NovacloudClient::Objects::Solutions::PublishResult]
      def emergency_page(player_ids:, attribute:, page:)
        validate_player_ids!(player_ids)
        validate_presence!(attribute, "attribute")
        validate_presence!(page, "page")

        payload = Support::KeyTransform.camelize_component(
          playerIds: player_ids,
          attribute: attribute,
          page: page
        )

        response = post("/v2/player/emergency-program/page", params: payload)
        build_publish_result(response)
      end

      # Cancel any active emergency program for the provided players.
      #
      # @param player_ids [Array<String>]
      # @return [NovacloudClient::Objects::Solutions::PublishResult]
      def cancel_emergency(player_ids:)
        validate_player_ids!(player_ids)

        payload = Support::KeyTransform.camelize_component(playerIds: player_ids)
        response = post("/v2/player/emergency-program/cancel", params: payload)
        build_publish_result(response)
      end

      # Publish a normal (common) solution schedule to the given players.
      #
      # @param player_ids [Array<String>] target players
      # @param pages [Array<Hash, #to_h>] program pages to publish
      # @param schedule [Hash, #to_h, nil] optional schedule definition
      # @return [NovacloudClient::Objects::Solutions::PublishResult]
      def common_solution(player_ids:, pages:, schedule: nil)
        validate_player_ids!(player_ids)
        validate_presence!(pages, "pages")

        payload = Support::KeyTransform.camelize_component(
          playerIds: player_ids,
          pages: pages
        )
        payload[:schedule] = Support::KeyTransform.camelize_component(schedule) if schedule

        response = post("/v2/player/program/normal", params: payload)
        build_publish_result(response)
      end

      private

      def build_publish_result(response)
        Objects::Solutions::PublishResult.new(response || {})
      end

      def validate_presence!(value, field)
        return unless value.nil? || (value.respond_to?(:empty?) && value.empty?)

        raise ArgumentError, "#{field} is required"
      end
    end
  end
end
