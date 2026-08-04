# frozen_string_literal: true

require_relative "base"
require_relative "../models/issue"

module RouteGuard
  module Rules
    class ShadowedRoutes < Base
      def analyze(routes, report)
        issues = []
        return issues if routes.empty?

        # Cache segment info and path expansions for all routes
        route_info = routes.map do |r|
          segs = split_segments(r.path)
          {
            route: r,
            segs: segs,
            first: segs[1],
            is_catch_all: catch_all_wildcard?(r),
            expansions: (expand_path(r.original_path).map { |p| split_segments(p) } rescue [[r.path]])
          }
        end

        route_info.each_with_index do |info_b, idx|
          next if info_b[:is_catch_all]
          route_b = info_b[:route]
          first_b = info_b[:first]

          route_info[0...idx].each do |info_a|
            next if info_a[:is_catch_all]
            first_a = info_a[:first]

            # Optimization: Skip comparisons if first literal segment doesn't match
            if first_a && first_b && !first_a.start_with?(":") && !first_a.start_with?("*")
              next if first_a != first_b
            end

            route_a = info_a[:route]
            next unless verb_matches?(route_a.verb, route_b.verb)

            if shadows_cached?(info_a, info_b)
              issues << Models::Issue.new(
                rule_name: :shadowed_routes,
                severity: :warning,
                message: "Shadowed Route: #{route_b} is shadowed by #{route_a} defined earlier.",
                route: route_b,
                related_routes: [route_a]
              )
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

      def shadows_cached?(info_a, info_b)
        route_a = info_a[:route]
        route_b = info_b[:route]
        return false if route_a.path == route_b.path

        info_b[:expansions].all? do |seg_b|
          info_a[:expansions].any? do |seg_a|
            path_shadows?(seg_a, seg_b, route_a.constraints, route_b.constraints)
          end
        end
      end
    end
  end
end
