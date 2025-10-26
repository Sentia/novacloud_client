# frozen_string_literal: true

module NovacloudClient
  # Holds configuration for a NovacloudClient::Client instance.
  class Configuration
    attr_accessor :app_key, :app_secret, :service_domain, :adapter

    def initialize
      @adapter = :net_http
    end

    def base_url
      "https://#{service_domain}"
    end

    def validate!
      raise ArgumentError, "app_key is required" if blank?(app_key)
      raise ArgumentError, "app_secret is required" if blank?(app_secret)
      raise ArgumentError, "service_domain is required" if blank?(service_domain)
    end

    private

    def blank?(value)
      return true if value.nil?
      return value.strip.empty? if value.is_a?(String)

      value.respond_to?(:empty?) ? value.empty? : false
    end
  end
end
