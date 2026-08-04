# frozen_string_literal: true

require "spec_helper"

RSpec.describe RouteGuard::Rules::DuplicateRoutes do
  let(:rule) { described_class.new }
  let(:report) { RouteGuard::Models::Report.new }

  it "detects exact duplicate routes" do
    routes = draw_routes do
      get "/login", to: "sessions#new"
      get "/login", to: "accounts#login"
    end

    issues = rule.analyze(routes, report)
    expect(issues.size).to eq(1)
    expect(issues.first.rule_name).to eq(:duplicate_routes)
    expect(issues.first.severity).to eq(:error)
    expect(issues.first.message).to include("Duplicate Route")
  end

  it "does not report when verbs are different" do
    routes = draw_routes do
      get "/login", to: "sessions#new"
      post "/login", to: "sessions#create"
    end

    issues = rule.analyze(routes, report)
    expect(issues).to be_empty
  end
end
