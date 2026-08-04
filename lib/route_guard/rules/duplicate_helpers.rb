# frozen_string_literal: true

require_relative "base"
require_relative "../models/issue"

module RouteGuard
  module Rules
    class DuplicateHelpers < Base
      def analyze(routes, report)
        issues = []

        groups = Hash.new { |h, k| h[k] = [] }
        routes.each do |route|
          next if route.name.nil? || route.name.empty?

          groups[route.name] << route
        end

        groups.each do |name, grp_routes|
          paths = grp_routes.map(&:path).uniq
          next if paths.length <= 1

          primary = grp_routes.first
          conflicts = grp_routes[1..-1]

          conflicts.each do |conflict|
            next if conflict.path == primary.path

            issues << Models::Issue.new(
              rule_name: :duplicate_helpers,
              severity: :error,
              message: "Duplicate Named Helper: Helper '#{name}_path' is defined for both '#{primary.path}' and '#{conflict.path}'.",
              route: conflict,
              related_routes: [primary]
            )
          end
        end

        issues
      end
    end
  end
end
