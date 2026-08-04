# frozen_string_literal: true

namespace :routes do
  desc "Lint Rails routes and detect shadowing, duplicates, etc."
  task lint: :environment do
    require "route_guard"
    config = RouteGuard::Configuration.new
    inspector = RouteGuard::Inspector.new(config)
    report = inspector.run
    inspector.format(report, :terminal)

    exit(1) if report.errors.any?
  end

  desc "Run RouteGuard doctor mode on Rails routes"
  task doctor: :environment do
    require "route_guard"
    config = RouteGuard::Configuration.new
    config.strict = true
    config.fail_on_warning = true
    inspector = RouteGuard::Inspector.new(config)
    report = inspector.run
    inspector.format(report, :terminal)

    exit(1) if report.errors.any? || report.warnings.any?
  end
end

desc "Lint Rails routes using RouteGuard"
task route_guard: ["routes:lint"]
