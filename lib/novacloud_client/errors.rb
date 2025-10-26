# frozen_string_literal: true

module NovacloudClient
  # Base error class allowing access to the Faraday environment.
  class Error < StandardError
    attr_reader :response

    def initialize(message = nil, response: nil)
      super(message)
      @response = response
    end
  end

  class ClientError < Error; end
  class BadRequestError < ClientError; end
  class AuthenticationError < ClientError; end
  class PermissionError < ClientError; end
  class NotAcceptableError < ClientError; end
  class RateLimitError < ClientError; end

  class ServerError < Error; end
  class InternalServerError < ServerError; end
  class BadGatewayError < ServerError; end
  class ServiceUnavailableError < ServerError; end
  class GatewayTimeoutError < ServerError; end
end
