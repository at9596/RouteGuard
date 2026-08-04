# frozen_string_literal: true

require "spec_helper"

RSpec.describe RouteGuard::RouteLoader do
  describe ".load" do
    context "when Rails is defined" do
      it "reloads routes and returns loaded routes" do
        mock_routes = double("routes", routes: [])
        mock_app = double("application", routes: mock_routes)
        allow(mock_app).to receive(:reload_routes!)
        
        # Stub Rails module
        stub_const("Rails", double("Rails", application: mock_app))

        routes = described_class.load
        expect(routes).to eq([])
      end
    end

    context "when Rails is not defined" do
      it "returns an empty array" do
        if defined?(Rails)
          # temporarily hide Rails
          orig_rails = Rails
          Object.send(:remove_const, :Rails)
        end

        begin
          routes = described_class.load
          expect(routes).to eq([])
        ensure
          # restore
          Object.send(:const_set, :Rails, orig_rails) if orig_rails
        end
      end
    end
  end

  describe ".load_environment!" do
    it "requires environment file if it exists" do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(/config\/environment\.rb/).and_return(true)

      expect(described_class).to receive(:require).with(/config\/environment\.rb/).and_return(true)
      described_class.load_environment!
    end
  end

  describe ".load_from_route_set" do
    it "handles regex verbs and string paths" do
      mock_route = double("route")
      allow(mock_route).to receive(:internal?).and_return(false)
      allow(mock_route).to receive(:verb).and_return(/^GET$/)
      allow(mock_route).to receive(:path).and_return("/welcome") # path is just a string, not responding to spec
      allow(mock_route).to receive(:defaults).and_return({ controller: "welcome", action: "index" })
      allow(mock_route).to receive(:name).and_return("welcome")
      allow(mock_route).to receive(:requirements).and_return({})
      allow(mock_route).to receive(:instance_variable_get).with(:@route_guard_trace).and_return({ file: "routes.rb", line: 5 })

      mock_route_set = double("route_set", routes: [mock_route])
      routes = described_class.load_from_route_set(mock_route_set)

      expect(routes.size).to eq(1)
      expect(routes.first.verb).to eq("GET")
      expect(routes.first.path).to eq("/welcome")
    end
  end
end
