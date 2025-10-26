# frozen_string_literal: true

require "spec_helper"
require "digest"
require "json"

RSpec.describe NovacloudClient::Client do
  let(:app_key) { "app_key" }
  let(:app_secret) { "app_secret" }
  let(:service_domain) { "open-us.vnnox.com" }
  let(:client) { described_class.new(app_key: app_key, app_secret: app_secret, service_domain: service_domain) }
  let(:fixed_time) { Time.utc(2023, 1, 1, 0, 0, 0) }

  describe "initialization" do
    it "requires an app_key" do
      expect do
        described_class.new(app_key: "", app_secret: "secret", service_domain: "domain")
      end.to raise_error(ArgumentError, /app_key is required/)
    end

    it "requires an app_secret" do
      expect do
        described_class.new(app_key: "key", app_secret: nil, service_domain: "domain")
      end.to raise_error(ArgumentError, /app_secret is required/)
    end

    it "requires a service_domain" do
      expect do
        described_class.new(app_key: "key", app_secret: "secret", service_domain: "")
      end.to raise_error(ArgumentError, /service_domain is required/)
    end
  end

  describe "#request" do
    before do
      allow(Time).to receive(:now).and_return(fixed_time)
    end

    it "performs a GET request with query params and authentication headers" do
      captured_headers = nil

      stub_request(:get, "https://open-us.vnnox.com/v2/player/list")
        .with(query: hash_including("pageNum" => "1", "pageSize" => "10"))
        .to_return do |request|
          captured_headers = request.headers
          {
            status: 200,
            body: { "code" => 0 }.to_json,
            headers: { "Content-Type" => "application/json" }
          }
        end

      response = client.request(
        http_method: :get,
        endpoint: "/v2/player/list",
        params: { pageNum: 1, pageSize: 10 }
      )

      expect(response).to eq("code" => 0)
      normalized_headers = captured_headers.transform_keys { |key| key.to_s.downcase }
      expect(normalized_headers["appkey"]).to eq(app_key)
      expect(normalized_headers["curtime"]).to eq(fixed_time.to_i.to_s)
      expect(normalized_headers["accept"]).to eq("application/json")
      nonce = normalized_headers["nonce"]
      checksum = Digest::SHA256.hexdigest(app_secret + nonce + normalized_headers["curtime"])
      expect(normalized_headers["checksum"]).to eq(checksum)
    end

    it "serializes POST params as JSON" do
      captured_body = nil

      stub_request(:post, "https://open-us.vnnox.com/v2/player/program")
        .to_return do |request|
          captured_body = request.body
          {
            status: 200,
            body: { "success" => true }.to_json,
            headers: { "Content-Type" => "application/json" }
          }
        end

      response = client.request(
        http_method: :post,
        endpoint: "/v2/player/program",
        params: { playerIds: [1, 2], brightness: 80 }
      )

      expect(JSON.parse(captured_body)).to eq("playerIds" => [1, 2], "brightness" => 80)
      expect(response).to eq("success" => true)
    end

    it "raises specific errors from middleware" do
      stub_request(:get, "https://open-us.vnnox.com/v2/player/list")
        .to_return(status: 401, body: { "code" => 401 }.to_json, headers: { "Content-Type" => "application/json" })

      expect do
        client.request(http_method: :get, endpoint: "/v2/player/list")
      end.to raise_error(NovacloudClient::AuthenticationError)
    end

    it "allows middleware customization via block" do
      custom_client = described_class.new(
        app_key: app_key,
        app_secret: app_secret,
        service_domain: service_domain
      ) do |faraday|
        faraday.headers["X-Custom-Header"] = "custom"
      end

      custom_header = nil

      stub_request(:get, "https://open-us.vnnox.com/v2/player/list")
        .to_return do |request|
          custom_header = request.headers["X-Custom-Header"]
          {
            status: 200,
            body: { "ok" => true }.to_json,
            headers: { "Content-Type" => "application/json" }
          }
        end

      custom_client.request(http_method: :get, endpoint: "/v2/player/list")

      expect(custom_header).to eq("custom")
    end

    it "returns nil for empty bodies" do
      stub_request(:get, "https://open-us.vnnox.com/v2/player/list")
        .to_return(status: 200, body: "", headers: {})

      response = client.request(http_method: :get, endpoint: "/v2/player/list")

      expect(response).to be_nil
    end

    it "returns raw body when JSON parsing fails" do
      stub_request(:get, "https://open-us.vnnox.com/v2/player/list")
        .to_return(status: 200, body: "not-json", headers: { "Content-Type" => "text/plain" })

      response = client.request(http_method: :get, endpoint: "/v2/player/list")

      expect(response).to eq("not-json")
    end
  end
end
