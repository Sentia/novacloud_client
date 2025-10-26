# frozen_string_literal: true

require 'faraday'
require 'digest'
require 'securerandom'

module NovacloudClient
  module Middleware
    # Injects the NovaCloud authentication headers into every request.
    class Authentication < Faraday::Middleware
      def initialize(app, app_key:, app_secret:)
        super(app)
        @app_key = app_key
        @app_secret = app_secret
      end

      def call(env)
        cur_time = current_utc_timestamp
        nonce = generate_nonce
        checksum = checksum_for(nonce, cur_time)

        headers = env.request_headers
        headers['AppKey'] = @app_key
        headers['Nonce'] = nonce
        headers['CurTime'] = cur_time
        headers['CheckSum'] = checksum

        @app.call(env)
      end

      private

      def current_utc_timestamp
        Time.now.utc.to_i.to_s
      end

      def generate_nonce
        timestamp_component = (Time.now.utc.to_f * 1_000_000).to_i.to_s(36)
        random_component = SecureRandom.alphanumeric(16)
        (timestamp_component + random_component)[0, 16]
      end

      def checksum_for(nonce, cur_time)
        signature = @app_secret + nonce + cur_time
        Digest::SHA256.hexdigest(signature)
      end
    end
  end
end
