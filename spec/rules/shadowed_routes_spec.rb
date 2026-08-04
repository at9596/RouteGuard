# frozen_string_literal: true

require "spec_helper"

RSpec.describe RouteGuard::Rules::ShadowedRoutes do
  let(:rule) { described_class.new }
  let(:report) { RouteGuard::Models::Report.new }

  it "warns when a dynamic segment shadows a literal segment" do
    routes = draw_routes do
      get "/users/:id", to: "users#show"
      get "/users/new", to: "users#new"
    end

    issues = rule.analyze(routes, report)
    expect(issues.size).to eq(1)
    expect(issues.first.rule_name).to eq(:shadowed_routes)
    expect(issues.first.severity).to eq(:warning)
    expect(issues.first.message).to include("shadowed by")
  end

  it "does not warn if the dynamic segment is constrained and does not match the literal segment" do
    routes = draw_routes do
      get "/users/:id", to: "users#show", constraints: { id: /\d+/ }
      get "/users/new", to: "users#new"
    end

    issues = rule.analyze(routes, report)
    expect(issues).to be_empty
  end

  it "warns if the dynamic segment constraint matches the literal segment" do
    routes = draw_routes do
      get "/users/:id", to: "users#show", constraints: { id: /new|\d+/ }
      get "/users/new", to: "users#new"
    end

    issues = rule.analyze(routes, report)
    expect(issues.size).to eq(1)
  end

  it "warns if a prefix wildcard shadows a nested route" do
    routes = draw_routes do
      get "/admin/*path", to: "admin#index"
      get "/admin/users", to: "users#index"
    end

    issues = rule.analyze(routes, report)
    expect(issues.size).to eq(1)
  end
end
