# frozen_string_literal: true

require "spec_helper"
require "digest"

RSpec.describe NovacloudClient::Middleware::Authentication do
  let(:app) { ->(env) { env } }
  let(:middleware) { described_class.new(app, app_key: "app_key", app_secret: "app_secret") }

  describe "#call" do
    it "injects authentication headers" do
      allow(middleware).to receive(:current_utc_timestamp).and_return("1672531200")
      allow(middleware).to receive(:generate_nonce).and_return("NONCE1234567890")

      env = Struct.new(:request_headers).new({})

      middleware.call(env)

      expect(env.request_headers["AppKey"]).to eq("app_key")
      expect(env.request_headers["Nonce"]).to eq("NONCE1234567890")
      expect(env.request_headers["CurTime"]).to eq("1672531200")
      expected_checksum = Digest::SHA256.hexdigest("app_secretNONCE12345678901672531200")
      expect(env.request_headers["CheckSum"]).to eq(expected_checksum)
    end
  end

  describe "nonce generation" do
    it "creates a 16-character alphanumeric string" do
      nonce = middleware.send(:generate_nonce)
      expect(nonce.length).to eq(16)
      expect(nonce).to match(/\A[0-9a-zA-Z]+\z/)
    end
  end

  describe "checksum calculation" do
    it "computes SHA256 of secret + nonce + cur_time" do
      checksum = middleware.send(:checksum_for, "noncevalue", "1672531200")
      expect(checksum).to eq(Digest::SHA256.hexdigest("app_secretnoncevalue1672531200"))
    end
  end
end
