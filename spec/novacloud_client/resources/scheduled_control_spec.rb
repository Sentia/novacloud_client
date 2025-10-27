# frozen_string_literal: true

RSpec.describe NovacloudClient::Resources::ScheduledControl do
  subject(:resource) { described_class.new(client) }

  let(:client) do
    NovacloudClient::Client.new(
      app_key: "key",
      app_secret: "secret",
      service_domain: "api.example.com"
    )
  end

  describe "#screen_status" do
    it "normalizes status values and camelizes schedule keys" do
      stub_request(:post, "https://api.example.com/v2/player/scheduled-control/screen-status")
        .with(body: {
          playerIds: ["p1"],
          schedules: [
            {
              startDate: "2025-01-01",
              endDate: "2025-12-31",
              weekDays: [1, 2],
              execTime: "06:30:00",
              status: "OPEN"
            }
          ]
        }.to_json)
        .to_return(status: 200, body: { "success" => ["p1"], "fail" => [] }.to_json)

      result = resource.screen_status(
        player_ids: ["p1"],
        schedules: {
          start_date: "2025-01-01",
          end_date: "2025-12-31",
          week_days: [1, 2],
          exec_time: "06:30:00",
          status: :open
        }
      )

      expect(result).to be_a(NovacloudClient::Objects::ControlResult)
      expect(result).to be_all_successful
    end

    it "requires schedules" do
      expect do
        resource.screen_status(player_ids: ["p1"], schedules: [])
      end.to raise_error(ArgumentError)
    end
  end

  describe "#brightness" do
    it "supports optional auto profile" do
      stub_request(:post, "https://api.example.com/v2/player/scheduled-control/brightness")
        .with(body: {
          playerIds: ["p1"],
          schedules: [
            {
              startDate: "2025-01-01",
              endDate: "2025-12-31",
              execTime: "07:00:00",
              type: 1,
              value: 40
            }
          ],
          autoProfile: {
            failValue: 50,
            segments: [
              {
                id: 0,
                environmentBrightness: 500,
                screenBrightness: 20
              }
            ]
          }
        }.to_json)
        .to_return(status: 200, body: { "success" => ["p1"], "fail" => [] }.to_json)

      result = resource.brightness(
        player_ids: ["p1"],
        schedules: [
          {
            start_date: "2025-01-01",
            end_date: "2025-12-31",
            exec_time: "07:00:00",
            type: 1,
            value: 40
          }
        ],
        auto_profile: {
          fail_value: 50,
          segments: [
            {
              id: 0,
              environment_brightness: 500,
              screen_brightness: 20
            }
          ]
        }
      )

      expect(result).to be_all_successful
    end
  end

  describe "#volume" do
    it "schedules volume changes" do
      stub_request(:post, "https://api.example.com/v2/player/scheduled-control/volume")
        .with(body: {
          playerIds: ["p1"],
          schedules: [
            {
              startDate: "2025-01-01",
              endDate: "2025-12-31",
              execTime: "08:00:00",
              value: 55,
              weekDays: []
            }
          ]
        }.to_json)
        .to_return(status: 200, body: { "success" => ["p1"], "fail" => [] }.to_json)

      result = resource.volume(
        player_ids: ["p1"],
        schedules: {
          start_date: "2025-01-01",
          end_date: "2025-12-31",
          exec_time: "08:00:00",
          value: 55
        }
      )

      expect(result).to be_all_successful
    end

    it "raises when schedules are nil" do
      expect do
        resource.volume(player_ids: ["p1"], schedules: nil)
      end.to raise_error(ArgumentError)
    end

    it "validates volume limits" do
      expect do
        resource.volume(player_ids: ["p1"], schedules: {
                          start_date: "2025-01-01",
                          end_date: "2025-12-31",
                          exec_time: "08:00:00",
                          value: 120
                        })
      end.to raise_error(ArgumentError)
    end
  end

  describe "#video_source" do
    it "passes the video source option" do
      stub_request(:post, "https://api.example.com/v2/player/scheduled-control/video-source")
        .with(body: {
          "playerIds" => ["p1"],
          "schedules" => [
            {
              "startDate" => "2025-01-01",
              "endDate" => "2025-12-31",
              "execTime" => "09:00:00",
              "source" => 1
            }
          ]
        }.to_json)
        .to_return(status: 200, body: { "success" => ["p1"], "fail" => [] }.to_json)

      resource.video_source(
        player_ids: ["p1"],
        schedules: {
          start_date: "2025-01-01",
          end_date: "2025-12-31",
          exec_time: "09:00:00",
          source: 1
        }
      )
    end
  end
end
