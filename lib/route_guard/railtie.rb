# frozen_string_literal: true

require "rails/railtie"

module RouteGuard
  class Railtie < Rails::Railtie
    rake_tasks do
      path = File.expand_path("../tasks/route_guard.rake", __dir__)
      load path if File.exist?(path)
    end
  end
end
