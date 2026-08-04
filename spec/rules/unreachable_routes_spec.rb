# frozen_string_literal: true

require "spec_helper"

RSpec.describe RouteGuard::Rules::UnreachableRoutes do
  let(:rule) { described_class.new }
  let(:report) { RouteGuard::Models::Report.new }

  it "reports any routes defined after a catch-all wildcard route" do
    routes = draw_routes do
      get "/*path", to: "errors#not_found"
      get "/users", to: "users#index"
    end

    issues = rule.analyze(routes, report)
    expect(issues.size).to eq(1)
    expect(issues.first.rule_name).to eq(:unreachable_routes)
    expect(issues.first.severity).to eq(:error)
  end

  it "does not report routes before the catch-all wildcard" do
    routes = draw_routes do
      get "/users", to: "users#index"
      get "/*path", to: "errors#not_found"
    end

    issues = rule.analyze(routes, report)
    expect(issues).to be_empty
  end
end
