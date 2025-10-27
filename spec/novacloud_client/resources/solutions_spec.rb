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

    it "requires a page payload" do
      expect do
        resource.emergency_page(player_ids: ["p1"], attribute: { duration: 1000 }, page: nil)
      end.to raise_error(ArgumentError)
    end

    it "requires player_ids" do
      expect do
        resource.emergency_page(player_ids: [], attribute: {}, page: {})
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
      expect(result).not_to be_all_successful
    end

    it "requires player_ids" do
      expect do
        resource.cancel_emergency(player_ids: [])
      end.to raise_error(ArgumentError)
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

    it "works without a schedule" do
      stub_request(:post, "https://api.example.com/v2/player/program/normal")
        .with(body: {
          playerIds: ["p1"],
          pages: [{ name: "page1", widgets: [] }]
        }.to_json)
        .to_return(status: 200, body: { "success" => ["p1"], "fail" => [] }.to_json)

      result = resource.common_solution(
        player_ids: ["p1"],
        pages: [{ name: "page1", widgets: [] }]
      )

      expect(result).to be_all_successful
    end

    it "requires pages" do
      expect do
        resource.common_solution(player_ids: ["p1"], pages: [])
      end.to raise_error(ArgumentError)
    end

    it "requires player_ids" do
      expect do
        resource.common_solution(player_ids: [], pages: [{}])
      end.to raise_error(ArgumentError)
    end
  end

  describe "#offline_export" do
    it "camelizes payload and wraps the response" do
      stub_request(:post, "https://api.example.com/v2/player/program/offline-export")
        .with(body: {
          programType: 1,
          pages: [
            {
              name: "page-1",
              widgets: [
                { type: "PICTURE", md5: "abc", url: "http://example.com/image.jpg" }
              ]
            }
          ],
          planVersion: "V2",
          schedule: {
            startDate: "2024-01-01",
            endDate: "2024-12-31"
          }
        }.to_json)
        .to_return(
          status: 200,
          body: {
            "displaySolutions" => { "md5" => "123", "fileName" => "display.json", "url" => "https://cdn/display.json" },
            "planJson" => {
              "md5" => "456",
              "fileName" => "plan.json",
              "url" => "https://cdn/plan.json",
              "isSupportMd5Checkout" => true,
              "programName" => "API-202409241354552904-Program"
            }
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = resource.offline_export(
        program_type: 1,
        plan_version: "V2",
        pages: [
          {
            name: "page-1",
            widgets: [
              { type: "PICTURE", md5: "abc", url: "http://example.com/image.jpg" }
            ]
          }
        ],
        schedule: {
          start_date: "2024-01-01",
          end_date: "2024-12-31"
        }
      )

      expect(result).to be_a(NovacloudClient::Objects::Solutions::OfflineExportResult)
      expect(result.display_solutions.file_name).to eq("display.json")
      expect(result.display_solutions.md5).to eq("123")
      expect(result.plan_json.is_support_md5_checkout?).to be(true)
      expect(result.plan_json.program_name).to eq("API-202409241354552904-Program")
    end

    it "handles array artifacts" do
      stub_request(:post, "https://api.example.com/v2/player/program/offline-export")
        .with(body: hash_including("programType" => 1))
        .to_return(
          status: 200,
          body: {
            "playlists" => [
              { "md5" => "abc1", "fileName" => "playlist1.json", "url" => "https://cdn/p1.json" },
              { "md5" => "abc2", "fileName" => "playlist2.json", "url" => "https://cdn/p2.json" }
            ]
          }.to_json
        )

      result = resource.offline_export(program_type: 1, pages: [{ name: "test" }])

      expect(result.playlists).to be_an(Array)
      expect(result.playlists.size).to eq(2)
      expect(result.playlists.first.file_name).to eq("playlist1.json")
      expect(result.playlists.last.md5).to eq("abc2")
    end

    it "omits nil values from payload" do
      stub_request(:post, "https://api.example.com/v2/player/program/offline-export")
        .with(body: {
          programType: 1,
          pages: [{ name: "test" }]
        }.to_json)
        .to_return(status: 200, body: {}.to_json)

      resource.offline_export(
        program_type: 1,
        pages: [{ name: "test" }],
        plan_version: nil,
        schedule: nil
      )
    end

    it "requires a program_type" do
      expect do
        resource.offline_export(program_type: nil, pages: [{}])
      end.to raise_error(ArgumentError)
    end

    it "requires pages" do
      expect do
        resource.offline_export(program_type: 1, pages: [])
      end.to raise_error(ArgumentError)
    end

    it "accepts additional options" do
      stub_request(:post, "https://api.example.com/v2/player/program/offline-export")
        .with(body: hash_including("programType" => 1, "customField" => "value"))
        .to_return(status: 200, body: {}.to_json)

      result = resource.offline_export(
        program_type: 1,
        pages: [{ name: "test" }],
        custom_field: "value"
      )

      expect(result).to be_a(NovacloudClient::Objects::Solutions::OfflineExportResult)
    end
  end

  describe "#set_over_spec_detection" do
    it "validates boolean flag and player ids" do
      stub_request(:post, "https://api.example.com/v2/player/immediateControl/over-specification-options")
        .with(body: { playerIds: ["p1"], enable: false }.to_json)
        .to_return(status: 200, body: { "success" => ["p1"], "fail" => [] }.to_json)

      result = resource.set_over_spec_detection(player_ids: ["p1"], enable: false)

      expect(result).to be_a(NovacloudClient::Objects::Solutions::PublishResult)
      expect(result.successful).to eq(["p1"])
    end

    it "accepts true flag" do
      stub_request(:post, "https://api.example.com/v2/player/immediateControl/over-specification-options")
        .with(body: { playerIds: ["p1"], enable: true }.to_json)
        .to_return(status: 200, body: { "success" => ["p1"], "fail" => [] }.to_json)

      result = resource.set_over_spec_detection(player_ids: ["p1"], enable: true)

      expect(result).to be_all_successful
    end

    it "rejects non-boolean enable values" do
      expect do
        resource.set_over_spec_detection(player_ids: ["p1"], enable: "nope")
      end.to raise_error(ArgumentError, /must be true or false/)
    end

    it "rejects nil enable" do
      expect do
        resource.set_over_spec_detection(player_ids: ["p1"], enable: nil)
      end.to raise_error(ArgumentError)
    end

    it "requires player_ids" do
      expect do
        resource.set_over_spec_detection(player_ids: [], enable: true)
      end.to raise_error(ArgumentError)
    end
  end

  describe "#program_over_spec_detection" do
    it "camelizes payload and builds result objects" do
      stub_request(:post, "https://api.example.com/v2/player/program/over-specification-check")
        .with(body: {
          playerIds: ["p1"],
          pages: [
            {
              pageId: 1,
              widgets: [
                { widgetId: 1, type: "PICTURE", md5: "abc", url: "http://example.com/img.jpg" }
              ]
            }
          ]
        }.to_json)
        .to_return(
          status: 200,
          body: {
            "logid" => 111,
            "status" => 0,
            "data" => [
              {
                "overSpec" => true,
                "overSpecType" => 1,
                "playerIds" => ["p1"],
                "overSpecDetail" => [
                  {
                    "pageId" => 1,
                    "widgetId" => 1,
                    "overSpecErrorCode" => [-20, -21],
                    "recommend" => {
                      "width" => "1920",
                      "height" => "1080",
                      "fps" => "30",
                      "byteRate" => "78.000000",
                      "codec" => "h264"
                    }
                  }
                ]
              }
            ]
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = resource.program_over_spec_detection(
        player_ids: ["p1"],
        pages: [
          {
            page_id: 1,
            widgets: [
              { widget_id: 1, type: "PICTURE", md5: "abc", url: "http://example.com/img.jpg" }
            ]
          }
        ]
      )

      expect(result).to be_a(NovacloudClient::Objects::Solutions::OverSpecDetectionResult)
      expect(result.logid).to eq(111)
      expect(result.status).to eq(0)
      expect(result.items).to be_an(Array)
      expect(result.items.size).to eq(1)

      item = result.items.first
      expect(item).to be_over_spec
      expect(item.over_spec_type).to eq(1)
      expect(item.player_ids).to eq(["p1"])
      expect(item.details).to be_an(Array)

      detail = item.details.first
      expect(detail.page_id).to eq(1)
      expect(detail.widget_id).to eq(1)
      expect(detail.over_spec_error_codes).to eq([-20, -21])

      recommendation = detail.recommendation
      expect(recommendation).not_to be_nil
      expect(recommendation.fps).to eq("30")
      expect(recommendation.width).to eq("1920")
      expect(recommendation.codec).to eq("h264")
    end

    it "handles players without over-spec issues" do
      stub_request(:post, "https://api.example.com/v2/player/program/over-specification-check")
        .with(body: hash_including("playerIds" => ["p2"]))
        .to_return(
          status: 200,
          body: {
            "logid" => 222,
            "status" => 0,
            "data" => [
              {
                "overSpec" => false,
                "playerIds" => ["p2"]
              }
            ]
          }.to_json
        )

      result = resource.program_over_spec_detection(
        player_ids: ["p2"],
        pages: [{ page_id: 1, widgets: [] }]
      )

      item = result.items.first
      expect(item.over_spec?).to be(false)
      expect(item.details).to be_empty
    end

    it "handles multiple items in response" do
      stub_request(:post, "https://api.example.com/v2/player/program/over-specification-check")
        .to_return(
          status: 200,
          body: {
            "data" => [
              { "overSpec" => false, "playerIds" => ["p1"] },
              { "overSpec" => true, "overSpecType" => 1, "playerIds" => ["p2"], "overSpecDetail" => [] }
            ]
          }.to_json
        )

      result = resource.program_over_spec_detection(player_ids: %w[p1 p2], pages: [{}])

      expect(result.items.size).to eq(2)
      expect(result.items.first.over_spec?).to be(false)
      expect(result.items.last.over_spec?).to be(true)
    end

    it "requires player_ids" do
      expect do
        resource.program_over_spec_detection(player_ids: [], pages: [{}])
      end.to raise_error(ArgumentError)
    end

    it "requires pages" do
      expect do
        resource.program_over_spec_detection(player_ids: ["p1"], pages: [])
      end.to raise_error(ArgumentError)
    end
  end
end
