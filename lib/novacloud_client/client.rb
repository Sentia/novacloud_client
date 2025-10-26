# frozen_string_literal: true

require 'faraday'
require 'json'

require_relative 'errors'
require_relative 'configuration'
require_relative 'middleware/authentication'
require_relative 'middleware/error_handler'

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

        case symbolized_method
        when :get, :delete
          req.params.update(params) unless params.empty?
        else
          unless params.empty?
            req.headers['Content-Type'] = 'application/json; charset=utf-8'
            req.body = JSON.generate(params)
          end
        end
      end

      parse_body(response)
    end

    private

    def build_connection
      Faraday.new(url: config.base_url) do |faraday|
        faraday.headers['Accept'] = 'application/json'

        faraday.use Middleware::Authentication,
                    app_key: config.app_key,
                    app_secret: config.app_secret
        faraday.use Middleware::ErrorHandler

        @faraday_block&.call(faraday)

        faraday.adapter config.adapter
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
