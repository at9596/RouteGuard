# frozen_string_literal: true

require "spec_helper"

RSpec.describe RouteGuard::RouteTracker do
  describe "NamedRouteCollectionExtension" do
    it "delegates to super when tracking is disabled" do
      routes = ActionDispatch::Routing::RouteSet.new
      collection = routes.named_routes

      # Ensure tracker is disabled
      described_class.enabled = false

      # key? should delegate and work normally
      expect(collection.key?("non_existent")).to be false
      expect(collection["non_existent"]).to be_nil
    end
  end

  describe "RouteSetExtension array routes" do
    it "associates trace info with all routes in an array" do
      mock_routeset = Class.new do
        prepend RouteGuard::RouteSetExtension

        def add_route(*args)
          r1 = Object.new
          r1.define_singleton_method(:object_id) { 101 }
          r1.define_singleton_method(:instance_variable_set) { |*k| }

          r2 = Object.new
          r2.define_singleton_method(:object_id) { 102 }
          r2.define_singleton_method(:instance_variable_set) { |*k| }

          [r1, r2]
        end
      end.new

      allow(mock_routeset.class).to receive(:method_defined?).and_return(true)
      
      described_class.reset!
      described_class.enabled = true

      allow(described_class).to receive(:find_routes_caller).and_return({ file: "config/routes.rb", line: 15 })

      routes = mock_routeset.add_route
      expect(routes.size).to eq(2)
      expect(described_class.route_traces[101]).to eq({ file: "config/routes.rb", line: 15 })
      expect(described_class.route_traces[102]).to eq({ file: "config/routes.rb", line: 15 })

      described_class.enabled = false
    end
  end
end
