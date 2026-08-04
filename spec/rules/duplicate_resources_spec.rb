# frozen_string_literal: true

require "spec_helper"

RSpec.describe RouteGuard::Rules::DuplicateResources do
  let(:rule) { described_class.new }
  let(:report) { RouteGuard::Models::Report.new }

  it "reports duplicate resources calls in the same scope" do
    # When drawing, we enable RouteTracker and reload
    routes = draw_routes do
      resources :users
      resources :users
    end

    issues = rule.analyze(routes, report)
    expect(issues.size).to eq(1)
    expect(issues.first.rule_name).to eq(:duplicate_resources)
    expect(issues.first.severity).to eq(:warning)
    expect(issues.first.message).to include("Resource ':users'")
  end

  it "reports duplicate singular resource calls in the same scope" do
    routes = draw_routes do
      resource :profile
      resource :profile
    end

    issues = rule.analyze(routes, report)
    expect(issues.size).to eq(1)
    expect(issues.first.message).to include("Resource ':profile'")
  end

  it "does not report duplicate resources calls in different scopes" do
    routes = draw_routes do
      resources :users
      namespace :admin do
        resources :users
      end
    end

    issues = rule.analyze(routes, report)
    expect(issues).to be_empty
  end
end

