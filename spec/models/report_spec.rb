# frozen_string_literal: true

require "spec_helper"

RSpec.describe RouteGuard::Models::Report do
  describe "#passed?" do
    it "returns true if there are no errors" do
      report = described_class.new
      expect(report.passed?).to be true
    end

    it "returns false if there are errors" do
      report = described_class.new
      issue = RouteGuard::Models::Issue.new(
        rule_name: :duplicate_routes,
        severity: :error,
        message: "Error message",
        route: nil
      )
      report.issues << issue

      expect(report.passed?).to be false
    end

    it "returns true if there are only warnings" do
      report = described_class.new
      issue = RouteGuard::Models::Issue.new(
        rule_name: :shadowed_routes,
        severity: :warning,
        message: "Warning message",
        route: nil
      )
      report.issues << issue

      expect(report.passed?).to be true
    end
  end
end
