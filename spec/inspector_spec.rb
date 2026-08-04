# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe RouteGuard::Inspector do
  let(:config) { RouteGuard::Configuration.new }
  let(:inspector) { described_class.new(config) }

  describe "#run" do
    it "runs the analyzer and returns a report" do
      allow(RouteGuard::RouteLoader).to receive(:load).and_return([])
      report = inspector.run
      expect(report).to be_a(RouteGuard::Models::Report)
    end
  end

  describe "#format" do
    let(:report) { RouteGuard::Models::Report.new }

    it "loads and executes terminal formatter" do
      io = StringIO.new
      inspector.format(report, :terminal, io)
      expect(io.string).to include("RouteGuard")
    end

    it "loads and executes json formatter" do
      io = StringIO.new
      inspector.format(report, :json, io)
      expect(io.string).to include("summary")
    end

    it "loads and executes html formatter" do
      io = StringIO.new
      inspector.format(report, :html, io)
      expect(io.string).to include("<!DOCTYPE html>")
    end

    it "loads and executes ci formatter" do
      io = StringIO.new
      issue = RouteGuard::Models::Issue.new(
        rule_name: :duplicate_routes,
        severity: :error,
        message: "Duplicate route",
        route: nil,
        file: "config/routes.rb",
        line: 10
      )
      report.issues << issue
      inspector.format(report, :ci, io)
      expect(io.string).to include("::error file=config/routes.rb,line=10")
    end

    it "raises error for unknown formatter" do
      expect { inspector.format(report, :unknown) }.to raise_error(RuntimeError, /Unknown formatter/)
    end
  end
end
