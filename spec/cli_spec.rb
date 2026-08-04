# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe RouteGuard::CLI do
  before do
    # Prevent Thor from exiting the test process directly
    allow(described_class).to receive(:exit_on_failure?).and_return(false)
  end

  describe "check command" do
    it "runs analysis and prints terminal report" do
      routes = draw_routes do
        get "/login", to: "sessions#new"
        get "/login", to: "accounts#login" # duplicate
      end
      allow(RouteGuard::RouteLoader).to receive(:load).and_return(routes)

      output = StringIO.new
      $stdout = output
      begin
        expect { described_class.start(["check"]) }.to raise_error(SystemExit) do |e|
          expect(e.status).to eq(1) # should exit with 1 because of errors
        end
      ensure
        $stdout = STDOUT
      end

      report_content = output.string
      expect(report_content).to include("RouteGuard")
      expect(report_content).to include("Duplicate Route")
      expect(report_content).to include("GET /login")
    end

    it "exits with 0 when there are no issues" do
      routes = draw_routes do
        get "/login", to: "sessions#new"
      end
      allow(RouteGuard::RouteLoader).to receive(:load).and_return(routes)

      output = StringIO.new
      $stdout = output
      begin
        expect { described_class.start(["check"]) }.to raise_error(SystemExit) do |e|
          expect(e.status).to eq(0)
        end
      ensure
        $stdout = STDOUT
      end
    end
  end

  describe "stats command" do
    it "prints statistics report" do
      routes = draw_routes do
        get "/login", to: "sessions#new"
      end
      allow(RouteGuard::RouteLoader).to receive(:load).and_return(routes)

      output = StringIO.new
      $stdout = output
      begin
        described_class.start(["stats"])
      ensure
        $stdout = STDOUT
      end

      expect(output.string).to include("Summary")
      expect(output.string).to include("Routes")
    end
  end

  describe "json command" do
    it "outputs JSON" do
      routes = draw_routes do
        get "/login", to: "sessions#new"
      end
      allow(RouteGuard::RouteLoader).to receive(:load).and_return(routes)

      output = StringIO.new
      $stdout = output
      begin
        expect { described_class.start(["json"]) }.to raise_error(SystemExit) do |e|
          expect(e.status).to eq(0)
        end
      ensure
        $stdout = STDOUT
      end

      json_data = JSON.parse(output.string)
      expect(json_data["summary"]["routes_count"]).to eq(1)
      expect(json_data["summary"]["health_score"]).to eq(100)
    end
  end

  describe "doctor command" do
    it "runs with strict checking and fails on warning" do
      routes = draw_routes do
        get "/users/:id", to: "users#show"
        get "/users/new", to: "users#new" # shadowed warning
      end
      allow(RouteGuard::RouteLoader).to receive(:load).and_return(routes)

      output = StringIO.new
      $stdout = output
      begin
        expect { described_class.start(["doctor"]) }.to raise_error(SystemExit) do |e|
          expect(e.status).to eq(1) # should fail due to warnings in strict doctor mode
        end
      ensure
        $stdout = STDOUT
      end
    end
  end

  describe "html command" do
    it "generates an html report to a file" do
      routes = draw_routes do
        get "/login", to: "sessions#new"
      end
      allow(RouteGuard::RouteLoader).to receive(:load).and_return(routes)

      temp_html = File.expand_path("../../tmp/test_report.html", __FILE__)
      FileUtils.mkdir_p(File.dirname(temp_html))
      File.delete(temp_html) if File.exist?(temp_html)

      begin
        expect { described_class.start(["html", "--output", temp_html]) }.to raise_error(SystemExit) do |e|
          expect(e.status).to eq(0)
        end
        expect(File.exist?(temp_html)).to be true
        expect(File.read(temp_html)).to include("RouteGuard Report")
      ensure
        File.delete(temp_html) if File.exist?(temp_html)
      end
    end
  end

  describe "check command options" do
    it "accepts output file path option" do
      routes = draw_routes do
        get "/login", to: "sessions#new"
      end
      allow(RouteGuard::RouteLoader).to receive(:load).and_return(routes)

      temp_json = File.expand_path("../../tmp/test_report.json", __FILE__)
      FileUtils.mkdir_p(File.dirname(temp_json))
      File.delete(temp_json) if File.exist?(temp_json)

      begin
        expect { described_class.start(["check", "--format", "json", "--output", temp_json]) }.to raise_error(SystemExit) do |e|
          expect(e.status).to eq(0)
        end
        expect(File.exist?(temp_json)).to be true
        data = JSON.parse(File.read(temp_json))
        expect(data["summary"]["routes_count"]).to eq(1)
      ensure
        File.delete(temp_json) if File.exist?(temp_json)
      end
    end

    it "exits with 1 on warning if fail-on-warning is set" do
      routes = draw_routes do
        get "/users/:id", to: "users#show"
        get "/users/new", to: "users#new" # shadowed warning
      end
      allow(RouteGuard::RouteLoader).to receive(:load).and_return(routes)

      output = StringIO.new
      $stdout = output
      begin
        expect { described_class.start(["check", "--fail-on-warning"]) }.to raise_error(SystemExit) do |e|
          expect(e.status).to eq(1)
        end
      ensure
        $stdout = STDOUT
      end
    end
  end
end

