# frozen_string_literal: true

require "spec_helper"

RSpec.describe RouteGuard::Rules::Complexity do
  let(:rule) { described_class.new }
  let(:report) { RouteGuard::Models::Report.new }

  it "starts at 100 and applies penalties" do
    # Populate stats
    report.stats = {
      maximum_nesting_depth: 5, # -10 points (5 - 3) * 5
      average_nesting_depth: 2.5, # -5 points ((2.5 - 2.0) * 10)
      wildcards: 2 # -4 points
    }

    # Add issues
    issue1 = RouteGuard::Models::Issue.new(
      rule_name: :duplicate_routes,
      severity: :error,
      message: "Duplicate route",
      route: nil
    )
    report.issues << issue1 # -10 points

    rule.analyze([], report)
    expect(report.complexity_score).to eq(71) # 100 - 10 - 5 - 4 - 10 = 71
  end

  it "clamps score to 0" do
    report.stats = {
      maximum_nesting_depth: 10,
      average_nesting_depth: 5.0,
      wildcards: 10
    }
    10.times do
      report.issues << RouteGuard::Models::Issue.new(
        rule_name: :duplicate_routes,
        severity: :error,
        message: "Duplicate route",
        route: nil
      )
    end

    rule.analyze([], report)
    expect(report.complexity_score).to eq(0)
  end
end
