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
          setter = "#{key}="
          public_send(setter, value) if respond_to?(setter)
        end
      end

      def parse_timestamp(value)
        return nil if value.nil?
        return value if value.is_a?(Time)

        Time.parse(value.to_s)
      rescue ArgumentError
        value
      end
    end
  end
end
