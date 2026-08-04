# frozen_string_literal: true

require "spec_helper"

RSpec.describe RouteGuard::Models::Route do
  describe "#initialize" do
    it "sets attributes and normalizes the verb" do
      route = described_class.new(
        verb: "get",
        path: "/users/:id",
        original_path: "/users/:id(.:format)",
        controller: "users",
        action: "show",
        name: "user",
        constraints: { id: /\d+/ },
        file: "config/routes.rb",
        line: 10
      )

      expect(route.verb).to eq("GET")
      expect(route.path).to eq("/users/:id")
      expect(route.original_path).to eq("/users/:id(.:format)")
      expect(route.controller).to eq("users")
      expect(route.action).to eq("show")
      expect(route.name).to eq("user")
      expect(route.constraints).to eq({ id: /\d+/ })
      expect(route.file).to eq("config/routes.rb")
      expect(route.line).to eq(10)
    end
  end

  describe "#internal?" do
    it "returns true for rails internal routes" do
      route = described_class.new(
        verb: "GET",
        path: "/rails/info/properties",
        original_path: "/rails/info/properties",
        controller: "rails/info",
        action: "properties"
      )
      expect(route.internal?).to be true
    end

    it "returns false for standard application routes" do
      route = described_class.new(
        verb: "GET",
        path: "/welcome",
        original_path: "/welcome",
        controller: "welcome",
        action: "index"
      )
      expect(route.internal?).to be false
    end
  end

  describe "#location" do
    it "returns relative path and line if available" do
      allow(Dir).to receive(:pwd).and_return("/workspace")
      route = described_class.new(
        verb: "GET",
        path: "/welcome",
        original_path: "/welcome",
        controller: "welcome",
        action: "index",
        file: "/workspace/config/routes.rb",
        line: 12
      )
      expect(route.location).to eq("config/routes.rb:12")
    end
  end
end
