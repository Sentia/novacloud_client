# frozen_string_literal: true

module NovacloudClient
  module Resources
    # Shared helpers for resource classes built on top of the client.
    class Base
      attr_reader :client

      def initialize(client)
        @client = client
      end

      private

      def get(endpoint, params: {})
        client.request(http_method: :get, endpoint: endpoint, params: params)
      end

      def post(endpoint, params: {})
        client.request(http_method: :post, endpoint: endpoint, params: params)
      end

      def validate_player_ids!(ids, max: 100)
        raise ArgumentError, "player_ids cannot be empty" if ids.nil? || ids.empty?
        raise ArgumentError, "maximum #{max} player IDs allowed" if ids.size > max
      end
    end
  end
end
