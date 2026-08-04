# frozen_string_literal: true

require "spec_helper"

RSpec.describe RouteGuard::Rules::DuplicateHelpers do
  let(:rule) { described_class.new }
  let(:report) { RouteGuard::Models::Report.new }

  it "reports duplicate helper names pointing to different paths" do
    routes = draw_routes do
      get "/login", to: "sessions#new", as: :auth
      get "/signin", to: "accounts#login", as: :auth
    end

    issues = rule.analyze(routes, report)
    expect(issues.size).to eq(1)
    expect(issues.first.rule_name).to eq(:duplicate_helpers)
    expect(issues.first.severity).to eq(:error)
  end

  it "does not report duplicate helpers pointing to the same path" do
    routes = draw_routes do
      get "/login", to: "sessions#new", as: :auth
      post "/login", to: "sessions#create", as: :auth
    end

    issues = rule.analyze(routes, report)
    expect(issues).to be_empty
  end
end
