require "spec_helper"
require "stringio"
require "route_guard/formatter/terminal"
require "route_guard/formatter/json"
require "route_guard/formatter/html"
require "route_guard/formatter/ci"

RSpec.describe "Formatters" do
  let(:report) { RouteGuard::Models::Report.new }
  let(:route) do
    RouteGuard::Models::Route.new(
      verb: "GET",
      path: "/welcome",
      original_path: "/welcome",
      controller: "welcome",
      action: "index",
      file: "config/routes.rb",
      line: 5,
      constraints: { id: /\d+/ }
    )
  end

  before do
    report.routes = [route]
    report.stats = {
      total_routes: 1,
      rest_resources: 0,
      namespaces: 0,
      scopes: 0,
      wildcards: 0,
      duplicate_paths: 0,
      shadowed_routes: 0,
      average_nesting_depth: 0.0,
      maximum_nesting_depth: 0,
      most_common_controller: "WelcomeController",
      most_common_count: 1
    }
  end

  describe "Terminal" do
    let(:formatter) { RouteGuard::Formatter::Terminal.new }

    it "formats a report with warnings and errors" do
      issue = RouteGuard::Models::Issue.new(
        rule_name: :shadowed_routes,
        severity: :warning,
        message: "Shadowed",
        route: route,
        related_routes: [route]
      )
      report.issues << issue

      io = StringIO.new
      formatter.format(report, io)
      output = io.string

      expect(output).to include("Issues Found")
      expect(output).to include("⚠ Warning [Shadowed Routes]")
      expect(output).to include("Related Route(s)")
    end
  end

  describe "Json" do
    let(:formatter) { RouteGuard::Formatter::Json.new }

    it "formats a report with custom issue attributes" do
      # Issue without a route, but with file/line
      issue = RouteGuard::Models::Issue.new(
        rule_name: :duplicate_resources,
        severity: :warning,
        message: "Duplicate resource",
        route: nil,
        file: "config/routes.rb",
        line: 12
      )
      report.issues << issue

      io = StringIO.new
      formatter.format(report, io)
      data = JSON.parse(io.string)

      expect(data["issues"].first["location"]["file"]).to eq("config/routes.rb")
      expect(data["issues"].first["location"]["line"]).to eq(12)
      expect(data["issues"].first["route"]).to be_nil
    end
  end

  describe "Html" do
    let(:formatter) { RouteGuard::Formatter::Html.new }

    it "generates an HTML string" do
      io = StringIO.new
      formatter.format(report, io)
      output = io.string

      expect(output).to include("<!DOCTYPE html>")
      expect(output).to include("WelcomeController")
    end
  end

  describe "Ci" do
    let(:formatter) { RouteGuard::Formatter::Ci.new }

    it "outputs annotation without file/line" do
      issue = RouteGuard::Models::Issue.new(
        rule_name: :complexity,
        severity: :warning,
        message: "High complexity",
        route: nil
      )
      report.issues << issue

      io = StringIO.new
      formatter.format(report, io)
      expect(io.string).to eq("::warning::[RouteGuard] High complexity\n")
    end
  end
end
