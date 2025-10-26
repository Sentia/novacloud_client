# frozen_string_literal: true

RSpec.describe NovacloudClient::Resources::Control do
  subject(:resource) { described_class.new(client) }

  let(:client) do
    NovacloudClient::Client.new(
      app_key: "key",
      app_secret: "secret",
      service_domain: "api.example.com"
    )
  end

  describe "#brightness" do
    it "validates numeric range" do
      expect do
        resource.brightness(player_ids: %w[p1], brightness: 150, notice_url: "url")
      end.to raise_error(ArgumentError)
    end

    it "enqueues a brightness command" do
      stub_request(:post, "https://api.example.com/v2/player/control/brightness")
        .with(body: {
          playerIds: %w[p1 p2],
          brightness: 70,
          noticeUrl: "https://callback.example.com"
        }.to_json)
        .to_return(
          status: 200,
          body: { "success" => %w[p1], "requestId" => "req-123" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = resource.brightness(
        player_ids: %w[p1 p2],
        brightness: 70,
        notice_url: "https://callback.example.com"
      )

      expect(result).to be_a(NovacloudClient::Objects::QueuedRequest)
  expect(result.success_count).to eq(1)
  expect(result.request_id).to eq("req-123")
    end
  end

  describe "#volume" do
    it "requires notice URL" do
      expect do
        resource.volume(player_ids: %w[p1], volume: 50, notice_url: " ")
      end.to raise_error(ArgumentError)
    end

    it "enqueues a volume command" do
      stub_request(:post, "https://api.example.com/v2/player/control/volume")
        .with(body: {
          playerIds: %w[p1],
          volume: 20,
          noticeUrl: "https://callback.example.com"
        }.to_json)
        .to_return(
          status: 200,
          body: { "success" => %w[p1], "requestId" => "req-456" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = resource.volume(
        player_ids: %w[p1],
        volume: 20,
        notice_url: "https://callback.example.com"
      )

      expect(result).to be_a(NovacloudClient::Objects::QueuedRequest)
  expect(result).to be_all_successful
  expect(result.request_id).to eq("req-456")
    end
  end

  describe "#reboot" do
    it "enqueues reboot command" do
      stub_request(:post, "https://api.example.com/v2/player/control/reboot")
        .with(body: {
          playerIds: %w[p1],
          noticeUrl: "https://callback.example.com"
        }.to_json)
        .to_return(
          status: 200,
          body: { "success" => %w[p1], "requestId" => "req-789" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = resource.reboot(
        player_ids: %w[p1],
        notice_url: "https://callback.example.com"
      )

      expect(result).to be_a(NovacloudClient::Objects::QueuedRequest)
  expect(result).to be_all_successful
  expect(result.request_id).to eq("req-789")
    end
  end

  describe "#request_result" do
    it "fetches the request result" do
      stub_request(:get, "https://api.example.com/v2/player/control/request-result")
        .with(query: { requestId: "123" })
        .to_return(
          status: 200,
          body: {
            "success" => %w[p1],
            "fail" => []
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = resource.request_result(request_id: "123")

      expect(result).to be_a(NovacloudClient::Objects::ControlResult)
      expect(result).to be_all_successful
    end

    it "requires a request id" do
      expect { resource.request_result(request_id: " ") }.to raise_error(ArgumentError)
    end
  end
end
