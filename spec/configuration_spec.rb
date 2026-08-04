# frozen_string_literal: true

require "spec_helper"

RSpec.describe RouteGuard::Configuration do
  let(:config) { described_class.new }

  describe "#enabled_rules" do
    it "returns all rules by default" do
      expect(config.enabled_rules).to eq(described_class::ALL_RULES)
    end

    it "filters rules by only" do
      config.only = [:duplicate_routes]
      expect(config.enabled_rules).to eq([:duplicate_routes])
    end

    it "filters rules by except" do
      config.except = [:statistics]
      expect(config.enabled_rules).not_to include(:statistics)
    end
  end
end
