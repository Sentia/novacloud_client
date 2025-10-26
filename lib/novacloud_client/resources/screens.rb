# frozen_string_literal: true

require_relative "base"
require_relative "../objects/screen"
require_relative "../objects/screen_monitor"
require_relative "../objects/screen_detail"

module NovacloudClient
  module Resources
    # Resource wrapper around VNNOXCare screen inventory endpoints.
    class Screens < Base
      # Retrieve paginated list of screens and monitoring metadata.
      #
      # @param start [Integer] pagination offset provided by VNNOXCare (defaults to 0)
      # @param count [Integer] number of records to request (defaults to 20)
      # @param status [Integer, nil] optional status filter defined by VNNOXCare (e.g., 1 for online)
      # @return [Array<NovacloudClient::Objects::Screen>]
      def list(start: 0, count: 20, status: nil)
        params = { start: start, count: count }
        params[:status] = status if status

        response = get("/v2/device-status-monitor/screen/list", params: params)
        items = response.fetch("items", [])
        items.map { |attrs| Objects::Screen.new(attrs) }
      end

      # Retrieve detailed monitoring metrics for a single screen by serial number.
      #
      # @param sn [String] screen serial number registered in VNNOXCare
      # @return [NovacloudClient::Objects::ScreenMonitor]
      # @raise [ArgumentError] when serial number is blank
      def monitor(serial_number: nil, **kwargs)
        serial = serial_number || kwargs[:sn]
        validate_presence!(serial, "serial_number")

        response = get("/v2/device-status-monitor/screen/monitor/#{serial}")
        Objects::ScreenMonitor.new(response)
      end

      # Retrieve deep detail payloads for up to 10 screens at once.
      #
      # @param sn_list [Array<String>] list of screen serial numbers (max 10)
      # @return [Array<NovacloudClient::Objects::ScreenDetail>]
      # @raise [ArgumentError] when validation fails
      def detail(sn_list:)
        validate_sn_list!(sn_list)

        response = post("/v2/device-status-monitor/all", params: { snList: sn_list })
        values = response.fetch("value", [])
        values.map { |attrs| Objects::ScreenDetail.new(attrs) }
      end

      private

      def validate_sn_list!(sn_list)
        validate_presence!(sn_list, "sn_list")
        raise ArgumentError, "sn_list cannot be empty" if sn_list.empty?
        raise ArgumentError, "maximum 10 screen serial numbers allowed" if sn_list.size > 10
      end

      def validate_presence!(value, field)
        raise ArgumentError, "#{field} is required" if value.to_s.strip.empty?
      end
    end
  end
end
