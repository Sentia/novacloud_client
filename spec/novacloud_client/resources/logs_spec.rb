# frozen_string_literal: true

RSpec.describe NovacloudClient::Resources::Logs do
  subject(:resource) { described_class.new(client) }

  let(:client) do
    NovacloudClient::Client.new(
      app_key: "key",
      app_secret: "secret",
      service_domain: "api.example.com"
    )
  end

  describe "#control_history" do
    it "raises when player id is missing" do
      expect { resource.control_history(player_id: "") }.to raise_error(ArgumentError)
    end

    it "returns log entries" do
      stub_request(:get, "https://api.example.com/v2/logs/remote-control")
        .with(query: hash_including("playerId" => "p1", "start" => "0", "count" => "20"))
        .to_return(
          status: 200,
          body: {
            "rows" => [
              {
                "status" => 1,
                "executeTime" => "2024-07-02 04:55:48",
                "type" => "openScreen"
              }
            ]
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      logs = resource.control_history(player_id: "p1")

      expect(logs).to all(be_a(NovacloudClient::Objects::ControlLogEntry))
      expect(logs.first).to be_success
      expect(logs.first.execute_time).to be_a(Time)
    end
  end
end
