# frozen_string_literal: true

require "faraday"
require "json"

require_relative "errors"
require_relative "configuration"
require_relative "middleware/authentication"
require_relative "middleware/error_handler"
require_relative "resources/players"
require_relative "resources/control"
require_relative "resources/scheduled_control"
require_relative "resources/solutions"
require_relative "resources/screens"
require_relative "resources/logs"

module NovacloudClient
  # Central entry point for interacting with the NovaCloud API.
  class Client
    attr_reader :config

    def initialize(app_key:, app_secret:, service_domain:, &faraday_block)
      @config = Configuration.new
      @config.app_key = app_key
      @config.app_secret = app_secret
      @config.service_domain = service_domain
      @config.validate!

      @faraday_block = faraday_block
    end

    def connection
      @connection ||= build_connection
    end

    def request(http_method:, endpoint:, params: {})
      symbolized_method = http_method.to_sym
      response = connection.public_send(symbolized_method) do |req|
        req.url endpoint
        apply_request_payload(req, symbolized_method, params)
      end

      parse_body(response)
    end

    def players
      @players ||= Resources::Players.new(self)
    end

    def control
      @control ||= Resources::Control.new(self)
    end

    def scheduled_control
      @scheduled_control ||= Resources::ScheduledControl.new(self)
    end

    def solutions
      @solutions ||= Resources::Solutions.new(self)
    end

    def screens
      @screens ||= Resources::Screens.new(self)
    end

    def logs
      @logs ||= Resources::Logs.new(self)
    end

    private

    def build_connection
      Faraday.new(url: config.base_url) do |faraday|
        faraday.headers["Accept"] = "application/json"

        faraday.use Middleware::Authentication,
                    app_key: config.app_key,
                    app_secret: config.app_secret
        faraday.use Middleware::ErrorHandler

        @faraday_block&.call(faraday)

        faraday.adapter config.adapter
      end
    end

    def apply_request_payload(request, http_method, params)
      return if params.empty?

      case http_method
      when :get, :delete
        request.params.update(params)
      else
        request.headers["Content-Type"] = "application/json; charset=utf-8"
        request.body = JSON.generate(params)
      end
    end

    def parse_body(response)
      body = response.body
      return nil if body.nil?
      return body unless body.is_a?(String)
      return nil if body.strip.empty?

      JSON.parse(body)
    rescue JSON::ParserError
      body
    end
  end
end
