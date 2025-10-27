# frozen_string_literal: true

module NovacloudClient
  module Support
    # Utilities for converting snake_case hashes to camelCase payloads.
    module KeyTransform
      module_function

      def camelize_component(component)
        case component
        when Hash
          component.each_with_object({}) do |(key, value), result|
            result[camelize_key(key)] = camelize_component(value)
          end
        when Array
          component.map { |item| camelize_component(item) }
        else
          component.respond_to?(:to_h) ? camelize_component(component.to_h) : component
        end
      end

      def camelize_key(key)
        return key unless key.is_a?(String) || key.is_a?(Symbol)

        string = key.to_s
        normalized = string.gsub(/([a-z\d])([A-Z])/, "\\1_\\2").gsub("-", "_").downcase
        parts = normalized.split("_")
        parts.map.with_index { |segment, index| index.zero? ? segment : segment.capitalize }.join
      end
    end
  end
end
