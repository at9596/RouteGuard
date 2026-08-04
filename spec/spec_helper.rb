# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
  minimum_coverage 95
end

require "bundler/setup"
require "route_guard"
require "action_dispatch"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Helper to dynamically draw routes and load them as RouteGuard models
  def draw_routes(&block)
    RouteGuard::RouteTracker.reset!
    RouteGuard::RouteTracker.enable_tracking!
    RouteGuard::RouteTracker.enabled = true

    route_set = ActionDispatch::Routing::RouteSet.new
    route_set.draw(&block)

    RouteGuard::RouteTracker.enabled = false
    RouteGuard::RouteLoader.load_from_route_set(route_set)
  ensure
    RouteGuard::RouteTracker.enabled = false
  end
end
