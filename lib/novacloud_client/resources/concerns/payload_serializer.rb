# frozen_string_literal: true

module NovacloudClient
  module Resources
    module Concerns
      # Provides camelCase serialization helpers for API payloads.
      module PayloadSerializer
        private

        def serialize_component(component)
          case component
          when nil
            nil
          when Hash
            component.each_with_object({}) do |(key, value), result|
              result[camelize_key(key)] = serialize_component(value)
            end
          when Array
            component.map { |item| serialize_component(item) }
          else
            component.respond_to?(:to_h) ? serialize_component(component.to_h) : component
          end
        end

        def camelize_key(key)
          return key unless key.is_a?(String) || key.is_a?(Symbol)

          string = key.to_s
          normalized = string
                       .gsub(/([a-z\d])([A-Z])/, "\\1_\\2")
                       .tr("-", "_")
                       .downcase

          parts = normalized.split("_")
          camelized = parts.map.with_index do |segment, index|
            next segment if index.zero?

            segment.capitalize
          end

          camelized.join
        end
      end
    end
  end
end
