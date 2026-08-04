# frozen_string_literal: true

require_relative "base"
require_relative "../models/issue"

module RouteGuard
  module Rules
    class DuplicateRoutes < Base
      def analyze(routes, report)
        issues = []

        groups = Hash.new { |h, k| h[k] = [] }
        routes.each do |route|
          route.verb.split("|").each do |v|
            groups[[v, route.path]] << route
          end
        end

        groups.each do |(verb, path), grp_routes|
          next if grp_routes.length <= 1

          primary = grp_routes.first
          duplicates = grp_routes[1..-1]

          duplicates.each do |dup|
            issues << Models::Issue.new(
              rule_name: :duplicate_routes,
              severity: :error,
              message: "Duplicate Route: #{verb} #{path} matches a route defined earlier.",
              route: dup,
              related_routes: [primary]
            )
          end
        end

        issues
      end
    end
  end
end
