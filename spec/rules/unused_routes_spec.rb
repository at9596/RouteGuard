# frozen_string_literal: true

require "spec_helper"

# Define mock controllers for testing
class DummyWelcomeController
  def self.action_methods
    ["index"]
  end
end

RSpec.describe RouteGuard::Rules::UnusedRoutes do
  let(:rule) { described_class.new }
  let(:report) { RouteGuard::Models::Report.new }

  before do
    # Define Rails to enable the rule inside tests
    stub_const("Rails", double("Rails"))
  end

  it "reports missing controller" do
    route = RouteGuard::Models::Route.new(
      verb: "GET",
      path: "/non_existent",
      original_path: "/non_existent",
      controller: "non_existent",
      action: "index"
    )

    issues = rule.analyze([route], report)
    expect(issues.size).to eq(1)
    expect(issues.first.rule_name).to eq(:unused_routes)
    expect(issues.first.message).to include("Controller NonExistentController does not exist")
  end

  it "reports missing action" do
    # Register dummy controller class globally for test lookup
    stub_const("WelcomeController", DummyWelcomeController)

    route = RouteGuard::Models::Route.new(
      verb: "GET",
      path: "/welcome",
      original_path: "/welcome",
      controller: "welcome",
      action: "show" # show is missing in DummyWelcomeController
    )

    issues = rule.analyze([route], report)
    expect(issues.size).to eq(1)
    expect(issues.first.message).to include("Action 'show' is missing in WelcomeController")
  end

  it "does not report when controller and action exist" do
    stub_const("WelcomeController", DummyWelcomeController)

    route = RouteGuard::Models::Route.new(
      verb: "GET",
      path: "/welcome",
      original_path: "/welcome",
      controller: "welcome",
      action: "index" # index is present in DummyWelcomeController
    )

    issues = rule.analyze([route], report)
    expect(issues).to be_empty
  end
end
