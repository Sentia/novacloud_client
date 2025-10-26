# frozen_string_literal: true

RSpec.describe NovacloudClient::Resources::Screens do
  subject(:resource) { described_class.new(client) }

  let(:client) do
    NovacloudClient::Client.new(
      app_key: "key",
      app_secret: "secret",
      service_domain: "api.example.com"
    )
  end

  describe "#list" do
    it "returns screen objects built from the response" do
      stub_request(:get, "https://api.example.com/v2/device-status-monitor/screen/list")
        .with(query: { start: 0, count: 20 })
        .to_return(
          status: 200,
          body: {
            "items" => [
              {
                "sid" => 1,
                "name" => "Screen A",
                "status" => 1,
                "camera" => 0,
                "brightness" => 80,
                "envBrightness" => 1200
              }
            ]
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      screens = resource.list

      expect(screens).to all(be_a(NovacloudClient::Objects::Screen))
      expect(screens.first).to be_online
      expect(screens.first).not_to be_camera_enabled
    end

    it "supports status filtering" do
      stub_request(:get, "https://api.example.com/v2/device-status-monitor/screen/list")
        .with(query: { start: 0, count: 20, status: 1 })
        .to_return(status: 200, body: { "items" => [] }.to_json)

      expect { resource.list(status: 1) }.not_to raise_error
    end
  end

  describe "#monitor" do
    it "retrieves single screen monitoring metrics" do
      stub_request(:get, "https://api.example.com/v2/device-status-monitor/screen/monitor/SN123")
        .to_return(
          status: 200,
          body: {
            "displayDevice" => "LED",
            "brightness" => 50,
            "envBrightness" => 100,
            "height" => 50,
            "width" => 100,
            "sn" => "SN123"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      monitor = resource.monitor(sn: "SN123")

      expect(monitor).to be_a(NovacloudClient::Objects::ScreenMonitor)
      expect(monitor.env_brightness).to eq(100)
    end

    it "requires an sn" do
      expect { resource.monitor(sn: " ") }.to raise_error(ArgumentError)
    end
  end

  describe "#detail" do
    it "returns detailed screen information" do
      stub_request(:post, "https://api.example.com/v2/device-status-monitor/all")
        .with(body: { snList: %w[SN123] }.to_json)
        .to_return(
          status: 200,
          body: {
            "value" => [
              {
                "identifier" => "screen-1",
                "sn" => "SN123",
                "masterControl" => { "status" => true }
              }
            ]
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      detail = resource.detail(sn_list: %w[SN123])

      expect(detail).to all(be_a(NovacloudClient::Objects::ScreenDetail))
      expect(detail.first.master_control).to eq("status" => true)
    end

    it "validates sn list size" do
      expect do
        resource.detail(sn_list: Array.new(11) { |i| "SN#{i}" })
      end.to raise_error(ArgumentError)
    end
  end
end
