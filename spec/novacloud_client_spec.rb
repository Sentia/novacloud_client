# frozen_string_literal: true

RSpec.describe NovacloudClient do
  it "has a version number" do
    expect(NovacloudClient::VERSION).not_to be nil
  end
  it "defines a base error class" do
    expect(NovacloudClient::Error).to be < StandardError
  end
end
