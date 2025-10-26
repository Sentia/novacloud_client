# frozen_string_literal: true

RSpec.describe NovacloudClient::Resources::Players do
  subject(:resource) { described_class.new(client) }

  let(:client) do
    NovacloudClient::Client.new(
      app_key: "key",
      app_secret: "secret",
      service_domain: "api.example.com"
    )
  end

  describe "#list" do
    it "returns player objects built from the response" do
      stub_request(:get, "https://api.example.com/v2/player/list")
        .with(query: { start: 0, count: 20 })
        .to_return(
          status: 200,
          body: {
            "rows" => [
              {
                "player_id" => "p1",
                "player_type" => 1,
                "name" => "Player One",
                "online_status" => 1,
                "last_online_time" => "2023-01-01T12:00:00Z"
              }
            ]
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      players = resource.list

      expect(players).to all(be_a(NovacloudClient::Objects::Player))
      expect(players.first).to have_attributes(
        player_id: "p1",
        name: "Player One"
      )
      expect(players.first).to be_online
    end
  end

  describe "#statuses" do
    it "raises when no ids are provided" do
      expect { resource.statuses }.to raise_error(ArgumentError)
    end

    it "sends provided player IDs and returns status objects" do
      stub_request(:post, "https://api.example.com/v2/player/current/online-status")
        .with(body: { playerIds: %w[p1 p2] }.to_json)
        .to_return(
          status: 200,
          body: [
            { "player_id" => "p1", "online_status" => 1 },
            { "player_id" => "p2", "online_status" => 0 }
          ].to_json,
          headers: { "Content-Type" => "application/json" }
        )

      statuses = resource.statuses(player_ids: %w[p1 p2])

      expect(statuses).to all(be_a(NovacloudClient::Objects::PlayerStatus))
      expect(statuses.map(&:player_id)).to contain_exactly("p1", "p2")
      expect(statuses.count(&:online?)).to eq(1)
    end

    it "supports player serial numbers" do
      stub_request(:post, "https://api.example.com/v2/player/current/online-status")
        .with(body: { playerSns: %w[sn1] }.to_json)
        .to_return(
          status: 200,
          body: [].to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect { resource.statuses(player_sns: %w[sn1]) }.not_to raise_error
    end
  end

  describe "#running_status" do
    let(:payload) do
      {
        playerIds: %w[p1],
        commands: ["screenshot"],
        noticeUrl: "https://callback.example.com"
      }
    end

    it "validates required fields" do
      expect do
        resource.running_status(player_ids: [], commands: ["cmd"], notice_url: "url")
      end.to raise_error(ArgumentError)

      expect do
        resource.running_status(player_ids: %w[p1], commands: [], notice_url: "url")
      end.to raise_error(ArgumentError)

      expect do
        resource.running_status(player_ids: %w[p1], commands: ["cmd"], notice_url: " ")
      end.to raise_error(ArgumentError)
    end

    it "returns a queued request object" do
      stub_request(:post, "https://api.example.com/v2/player/current/running-status")
        .with(body: payload.to_json)
        .to_return(
          status: 200,
          body: { "request_id" => "abc" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = resource.running_status(
        player_ids: %w[p1],
        commands: ["screenshot"],
        notice_url: "https://callback.example.com"
      )

      expect(result).to be_a(NovacloudClient::Objects::QueuedRequest)
      expect(result.success).to eq([])
    end
  end
end
