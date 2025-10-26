# frozen_string_literal: true

require "time"

module NovacloudClient
  module Objects
    # Base class providing attribute assignment and coercion helpers.
    class Base
      def initialize(attributes = {})
        assign_attributes(attributes)
      end

      private

      def assign_attributes(attributes)
        attributes.each do |key, value|
          writer = "#{key}="
          if respond_to?(writer)
            public_send(writer, value)
            next
          end

          normalized_writer = normalize_writer(key)
          next if normalized_writer == writer

          public_send(normalized_writer, value) if respond_to?(normalized_writer)
        end
      end

      def parse_timestamp(value)
        return nil if value.nil?
        return value if value.is_a?(Time)

        Time.parse(value.to_s)
      rescue ArgumentError
        value
      end

      def normalize_writer(key)
        normalized = key.to_s
        normalized = normalized.gsub(/([A-Z\d]+)([A-Z][a-z])/, "\\1_\\2")
                               .gsub(/([a-z\d])([A-Z])/, "\\1_\\2")
                               .tr("-", "_")
                               .downcase
        "#{normalized}="
      end
    end
  end
end
