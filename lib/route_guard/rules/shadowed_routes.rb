# frozen_string_literal: true

require_relative "base"
require_relative "../models/issue"

module RouteGuard
  module Rules
    class ShadowedRoutes < Base
      def analyze(routes, report)
        issues = []

        routes.each_with_index do |route_b, idx|
          # Skip if route_b is a catch-all wildcard itself, as it's not shadowed in the typical sense
          next if catch_all_wildcard?(route_b)

          # Find if any earlier route shadows route_b
          routes[0...idx].each do |route_a|
            # Skip if route_a is a catch-all wildcard, as that is handled by UnreachableRoutes
            next if catch_all_wildcard?(route_a)

            if shadows?(route_a, route_b)
              issues << Models::Issue.new(
                rule_name: :shadowed_routes,
                severity: :warning,
                message: "Shadowed Route: #{route_b} is shadowed by #{route_a} defined earlier.",
                route: route_b,
                related_routes: [route_a]
              )
              # Stop after finding the first shadowing route to avoid duplicate warnings for the same route
              break
            end
          end
        end

        issues
      end

      private

      def catch_all_wildcard?(route)
        path = route.path
        path == "/*path" || path == "*path" || path.match?(/\A\/?\*[a-zA-Z_]+\z/)
      end

      def shadows?(route_a, route_b)
        return false unless verb_matches?(route_a.verb, route_b.verb)
        return false if route_a.path == route_b.path

        begin
          expansions_a = expand_path(route_a.original_path).map { |p| split_segments(p) }
          expansions_b = expand_path(route_b.original_path).map { |p| split_segments(p) }

          expansions_b.all? do |seg_b|
            expansions_a.any? do |seg_a|
              path_shadows?(seg_a, seg_b, route_a.constraints, route_b.constraints)
            end
          end
        rescue => e
          # Fallback if path parsing fails
          false
        end
      end
    end
  end
end
