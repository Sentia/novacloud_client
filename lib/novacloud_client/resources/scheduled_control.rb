# frozen_string_literal: true

require_relative "base"
require_relative "../objects/control_result"
require_relative "../support/key_transform"

module NovacloudClient
  module Resources
    # Resource wrapper for scheduled control operations.
    class ScheduledControl < Base
      MAX_BATCH = 100

      # Configure scheduled screen status plans for players.
      def screen_status(player_ids:, schedules:)
        normalized = normalize_schedules(schedules) do |base, original|
          wk = fetch_optional(original, :week_days, "week_days", :weekDays, "weekDays")
          base[:week_days] = Array(wk || [])

          base[:exec_time] = fetch_required(original, :exec_time, "exec_time", :execTime, "execTime")

          status = fetch_required(original, :status, "status")
          base[:status] = normalize_screen_status(status)
          base
        end

        schedule_request(
          endpoint: "/v2/player/scheduled-control/screen-status",
          player_ids: player_ids,
          schedules: normalized
        )
      end

      # Configure scheduled reboots for players.
      def reboot(player_ids:, schedules:)
        normalized = normalize_schedules(schedules) do |base, original|
          base[:exec_time] = fetch_required(original, :exec_time, "exec_time", :execTime, "execTime")
          base
        end

        schedule_request(
          endpoint: "/v2/player/scheduled-control/reboot",
          player_ids: player_ids,
          schedules: normalized
        )
      end

      # Configure scheduled volume adjustments for players.
      def volume(player_ids:, schedules:)
        normalized = normalize_schedules(schedules) do |base, original|
          base[:exec_time] = fetch_required(original, :exec_time, "exec_time", :execTime, "execTime")

          value = fetch_required(original, :value, "value")
          validate_percentage!(value, "value")
          base[:value] = value.to_i

          wk = fetch_optional(original, :week_days, "week_days", :weekDays, "weekDays")
          base[:week_days] = Array(wk || [])
          base
        end

        schedule_request(
          endpoint: "/v2/player/scheduled-control/volume",
          player_ids: player_ids,
          schedules: normalized
        )
      end

      # Configure scheduled brightness adjustments for players.
      # @param auto_profile [Hash, nil] optional auto brightness profile
      def brightness(player_ids:, schedules:, auto_profile: nil)
        normalized = normalize_schedules(schedules) do |base, original|
          base[:exec_time] = fetch_required(original, :exec_time, "exec_time", :execTime, "execTime")

          type = fetch_required(original, :type, "type")
          base[:type] = type.to_i

          value = fetch_optional(original, :value, "value")
          base[:value] = value.to_i if value
          base
        end

        extra_payload = {}
        extra_payload[:auto_profile] = auto_profile if auto_profile

        schedule_request(
          endpoint: "/v2/player/scheduled-control/brightness",
          player_ids: player_ids,
          schedules: normalized,
          extra_payload: extra_payload
        )
      end

      # Configure scheduled video source switching for players.
      def video_source(player_ids:, schedules:)
        normalized = normalize_schedules(schedules) do |base, original|
          base[:exec_time] = fetch_required(original, :exec_time, "exec_time", :execTime, "execTime")

          source = fetch_required(original, :source, "source")
          base[:source] = source

          wk = fetch_optional(original, :week_days, "week_days", :weekDays, "weekDays")
          base[:week_days] = Array(wk) unless wk.nil?

          base
        end

        schedule_request(
          endpoint: "/v2/player/scheduled-control/video-source",
          player_ids: player_ids,
          schedules: normalized
        )
      end

      private

      def normalize_schedules(schedules)
        raise ArgumentError, "schedules must be provided" if schedules.nil?

        array = schedules.is_a?(Array) ? schedules : [schedules]
        raise ArgumentError, "schedules cannot be empty" if array.empty?

        array.map do |entry|
          base, original = build_base_schedule(entry)
          block_given? ? yield(base, original) : base
        end
      end

      def build_base_schedule(entry)
        hash = entry.respond_to?(:to_h) ? entry.to_h : entry
        raise ArgumentError, "schedule entries must be hash-like" unless hash.is_a?(Hash)

        # Only set date fields; callers append exec_time, values, and week_days
        # for each endpoint-specific payload requirement.
        base = {
          start_date: fetch_required(hash, :start_date, "start_date", :startDate, "startDate"),
          end_date: fetch_required(hash, :end_date, "end_date", :endDate, "endDate")
        }

        [base, hash]
      end

      def schedule_request(endpoint:, player_ids:, schedules:, extra_payload: {})
        validate_player_ids!(player_ids, max: MAX_BATCH)

        payload = {
          player_ids: player_ids,
          schedules: schedules
        }
        payload.merge!(extra_payload) if extra_payload && !extra_payload.empty?
        cleaned = cleanup_schedule_payload(endpoint, payload)

        response = post(endpoint, params: Support::KeyTransform.camelize_component(cleaned))
        Objects::ControlResult.new(response)
      end

      # Remove empty weekDays for endpoints that expect them omitted in tests/docs
      def cleanup_schedule_payload(endpoint, payload)
        return payload unless omit_empty_week_days?(endpoint)

        cleaned = Marshal.load(Marshal.dump(payload))
        Array(cleaned[:schedules]).each do |schedule|
          next unless schedule.key?(:week_days)

          schedule.delete(:week_days) if blank_week_days?(schedule[:week_days])
        end

        cleaned
      end

      def omit_empty_week_days?(endpoint)
        [
          "/v2/player/scheduled-control/brightness",
          "/v2/player/scheduled-control/video-source"
        ].include?(endpoint.to_s)
      end

      def blank_week_days?(values)
        return true if values.nil?
        return values.empty? if values.respond_to?(:empty?)

        false
      end

      def fetch_required(hash, *keys)
        value = fetch_optional(hash, *keys)
        raise ArgumentError, "#{keys.first} is required" if value.nil? || value.to_s.strip.empty?

        value
      end

      def fetch_optional(hash, *keys, default: nil)
        keys.each do |key|
          string_key = key.to_s
          return hash[key] if hash.key?(key)
          return hash[string_key] if hash.key?(string_key)

          symbol_key = string_key.to_sym
          return hash[symbol_key] if hash.key?(symbol_key)
        end

        default
      end

      def validate_percentage!(value, field)
        int_value = value.to_i
        return if int_value.between?(0, 100)

        raise ArgumentError, "#{field} must be between 0 and 100"
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
