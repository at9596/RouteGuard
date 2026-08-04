# frozen_string_literal: true

require "spec_helper"

RSpec.describe RouteGuard::Models::Issue do
  let(:route) do
    RouteGuard::Models::Route.new(
      verb: "GET",
      path: "/welcome",
      original_path: "/welcome",
      controller: "welcome",
      action: "index",
      file: "config/routes.rb",
      line: 5
    )
  end

  describe "#initialize" do
    it "sets properties and maps location from route" do
      issue = described_class.new(
        rule_name: :duplicate_routes,
        severity: :error,
        message: "Some message",
        route: route
      )

      expect(issue.rule_name).to eq(:duplicate_routes)
      expect(issue.severity).to eq(:error)
      expect(issue.message).to eq("Some message")
      expect(issue.route).to eq(route)
      expect(issue.location).to eq("config/routes.rb:5")
    end
  end
end
