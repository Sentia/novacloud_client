# frozen_string_literal: true

require "faraday"

require_relative "../errors"

module NovacloudClient
  module Middleware
    # Maps HTTP error responses to NovacloudClient exception classes.
    class ErrorHandler < Faraday::Middleware
      ERROR_MAP = {
        400 => NovacloudClient::BadRequestError,
        401 => NovacloudClient::AuthenticationError,
        403 => NovacloudClient::PermissionError,
        406 => NovacloudClient::NotAcceptableError,
        429 => NovacloudClient::RateLimitError,
        500 => NovacloudClient::InternalServerError,
        502 => NovacloudClient::BadGatewayError,
        503 => NovacloudClient::ServiceUnavailableError,
        504 => NovacloudClient::GatewayTimeoutError
      }.freeze

      def call(env)
        @app.call(env).on_complete do |response_env|
          handle_response(response_env)
        end
      end

      private

      def handle_response(env)
        status = env.status.to_i
        return if (200..299).cover?(status)

        error_class = ERROR_MAP[status] || fallback_error(status)
        message = "HTTP #{status}: #{summary_from(env)}"
        raise error_class.new(message, response: env)
      end

      def fallback_error(status)
        if (400..499).cover?(status)
          NovacloudClient::ClientError
        else
          NovacloudClient::ServerError
        end
      end

      def summary_from(env)
        body = env.body
        return "No response body" if body.nil?

        if body.is_a?(String)
          body.strip.empty? ? "Empty body" : body.strip[0, 200]
        elsif body.respond_to?(:to_json)
          body.to_json[0, 200]
        else
          body.to_s[0, 200]
        end
      end
    end
  end
end
