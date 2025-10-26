# frozen_string_literal: true

require "spec_helper"
require "faraday"

RSpec.describe NovacloudClient::Middleware::ErrorHandler do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:connection) do
    Faraday.new do |faraday|
      faraday.use described_class
      faraday.adapter :test, stubs
    end
  end

  it "returns successful responses untouched" do
    stubs.get("/ok") { [200, {}, "success"] }

    response = connection.get("/ok")

    expect(response.body).to eq("success")
  end

  it "raises mapped client errors" do
    stubs.get("/unauthorized") { [401, {}, { "msg" => "nope" }] }

    expect { connection.get("/unauthorized") }.to raise_error(NovacloudClient::AuthenticationError, /401/)
  end

  it "raises mapped server errors" do
    stubs.get("/down") { [503, {}, "maintenance"] }

    expect { connection.get("/down") }.to raise_error(NovacloudClient::ServiceUnavailableError)
  end

  it "falls back to generic errors when unmapped" do
    stubs.get("/weird") { [418, {}, "teapot"] }

    expect { connection.get("/weird") }.to raise_error(NovacloudClient::ClientError)
  end
end
