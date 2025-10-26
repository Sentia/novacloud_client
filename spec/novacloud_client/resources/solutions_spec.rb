# frozen_string_literal: true

RSpec.describe NovacloudClient::Resources::Solutions do
  subject(:resource) { described_class.new(client) }

  let(:client) do
    NovacloudClient::Client.new(
      app_key: "key",
      app_secret: "secret",
      service_domain: "api.example.com"
    )
  end

  describe "#emergency_page" do
    it "serializes snake_case keys to the API payload" do
      stub_request(:post, "https://api.example.com/v2/player/emergency-program/page")
        .with(body: {
          playerIds: ["p1"],
          attribute: {
            duration: 20_000,
            normalProgramStatus: "PAUSE",
            spotsType: "IMMEDIATELY"
          },
          page: {
            name: "urgent",
            widgets: [
              {
                type: "PICTURE",
                zIndex: 1,
                duration: 10_000,
                layout: { x: "0%", y: "0%", width: "100%", height: "100%" },
                inAnimation: { type: "NONE", duration: 1_000 }
              }
            ]
          }
        }.to_json)
        .to_return(
          status: 200,
          body: { "success" => ["p1"], "fail" => [] }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = resource.emergency_page(
        player_ids: ["p1"],
        attribute: { duration: 20_000, normal_program_status: "PAUSE", spots_type: "IMMEDIATELY" },
        page: {
          name: "urgent",
          widgets: [
            {
              type: "PICTURE",
              z_index: 1,
              duration: 10_000,
              layout: { x: "0%", y: "0%", width: "100%", height: "100%" },
              in_animation: { type: "NONE", duration: 1_000 }
            }
          ]
        }
      )

      expect(result).to be_a(NovacloudClient::Objects::Solutions::PublishResult)
      expect(result).to be_all_successful
      expect(result.successful).to eq(["p1"])
    end

    it "requires an attribute payload" do
      expect do
        resource.emergency_page(player_ids: ["p1"], attribute: nil, page: { name: "test" })
      end.to raise_error(ArgumentError)
    end
  end

  describe "#cancel_emergency" do
    it "publishes a cancel command" do
      stub_request(:post, "https://api.example.com/v2/player/emergency-program/cancel")
        .with(body: { playerIds: %w[p1 p2] }.to_json)
        .to_return(status: 200, body: { "success" => ["p1"], "fail" => ["p2"] }.to_json)

      result = resource.cancel_emergency(player_ids: %w[p1 p2])

      expect(result.failed).to eq(["p2"])
      expect(result.successful).to eq(["p1"])
    end
  end

  describe "#common_solution" do
    it "camelizes nested schedule and widget keys" do
      stub_request(:post, "https://api.example.com/v2/player/program/normal")
        .with(body: {
          playerIds: ["p1"],
          pages: [
            {
              name: "main",
              widgets: [
                {
                  type: "VIDEO",
                  zIndex: 2,
                  duration: 0,
                  url: "https://cdn.example.com/video.mp4",
                  layout: { x: "0%", y: "0%", width: "100%", height: "100%" }
                }
              ]
            }
          ],
          schedule: {
            startDate: "2024-01-01",
            endDate: "2024-12-31",
            plans: [
              {
                weekDays: [1, 2, 3, 4, 5],
                startTime: "08:00:00",
                endTime: "18:00:00"
              }
            ]
          }
        }.to_json)
        .to_return(status: 200, body: { "success" => ["p1"], "fail" => [] }.to_json)

      result = resource.common_solution(
        player_ids: ["p1"],
        pages: [
          {
            name: "main",
            widgets: [
              {
                type: "VIDEO",
                z_index: 2,
                duration: 0,
                url: "https://cdn.example.com/video.mp4",
                layout: { x: "0%", y: "0%", width: "100%", height: "100%" }
              }
            ]
          }
        ],
        schedule: {
          start_date: "2024-01-01",
          end_date: "2024-12-31",
          plans: [
            {
              week_days: [1, 2, 3, 4, 5],
              start_time: "08:00:00",
              end_time: "18:00:00"
            }
          ]
        }
      )

      expect(result).to be_all_successful
    end

    it "requires pages" do
      expect do
        resource.common_solution(player_ids: ["p1"], pages: [])
      end.to raise_error(ArgumentError)
    end
  end
end
