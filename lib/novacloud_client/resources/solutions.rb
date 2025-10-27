# frozen_string_literal: true

require_relative "base"
require_relative "../objects/solutions/publish_result"
require_relative "../objects/solutions/offline_export_result"
require_relative "../objects/solutions/over_spec_detection_result"
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

      # Export an offline program bundle without publishing it to devices.
      #
      # @param program_type [Integer] NovaCloud program type identifier
      # @param pages [Array<Hash, #to_h>] program pages to include
      # @param plan_version [String, nil] optional plan version (defaults to V2 when provided)
      # @param schedule [Hash, #to_h, nil] optional playback schedule definition
      # @param options [Hash] additional top-level attributes supported by the API
      # @return [NovacloudClient::Objects::Solutions::OfflineExportResult]
      def offline_export(program_type:, pages:, plan_version: nil, schedule: nil, **options)
        validate_presence!(pages, "pages")
        raise ArgumentError, "program_type is required" if program_type.nil?

        payload = {
          program_type: program_type,
          pages: pages,
          plan_version: plan_version,
          schedule: schedule
        }.merge(options)

        camelized = Support::KeyTransform.camelize_component(compact_hash(payload))

        response = post("/v2/player/program/offline-export", params: camelized)
        Objects::Solutions::OfflineExportResult.new(response || {})
      end

      # Enable or disable over-specification detection on the selected players.
      #
      # @param player_ids [Array<String>] target players
      # @param enable [Boolean] whether detection should be enabled
      # @return [NovacloudClient::Objects::Solutions::PublishResult]
      def set_over_spec_detection(player_ids:, enable:)
        validate_player_ids!(player_ids)
        validate_boolean!(enable, "enable")

        payload = {
          playerIds: player_ids,
          enable: enable
        }

        response = post("/v2/player/immediateControl/over-specification-options", params: payload)
        build_publish_result(response)
      end

      # Validate whether a program will exceed the hardware specifications.
      #
      # @param player_ids [Array<String>] players against which to test
      # @param pages [Array<Hash, #to_h>] the program definition to analyse
      # @return [NovacloudClient::Objects::Solutions::OverSpecDetectionResult]
      def program_over_spec_detection(player_ids:, pages:)
        validate_player_ids!(player_ids)
        validate_presence!(pages, "pages")

        payload = Support::KeyTransform.camelize_component(
          playerIds: player_ids,
          pages: pages
        )

        response = post("/v2/player/program/over-specification-check", params: payload)
        Objects::Solutions::OverSpecDetectionResult.new(response || {})
      end

      private

      def compact_hash(hash)
        hash.each_with_object({}) do |(key, value), result|
          next if value.nil?

          result[key] = value
        end
      end

      def build_publish_result(response)
        Objects::Solutions::PublishResult.new(response || {})
      end

      def validate_presence!(value, field)
        return unless value.nil? || (value.respond_to?(:empty?) && value.empty?)

        raise ArgumentError, "#{field} is required"
      end

      def validate_boolean!(value, field)
        return if [true, false].include?(value)

        raise ArgumentError, "#{field} must be true or false"
      end
    end
  end
end
