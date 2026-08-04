# frozen_string_literal: true

require_relative "base"
require_relative "../models/issue"

module RouteGuard
  module Rules
    class UnreachableRoutes < Base
      def analyze(routes, report)
        issues = []
        catch_alls = []

        routes.each do |route|
          matching_catch_all = catch_alls.find do |ca|
            verb_matches?(ca.verb, route.verb)
          end

          if matching_catch_all
            issues << Models::Issue.new(
              rule_name: :unreachable_routes,
              severity: :error,
              message: "Unreachable Route: #{route} is unreachable because it comes after catch-all wildcard #{matching_catch_all}.",
              route: route,
              related_routes: [matching_catch_all]
            )
          elsif catch_all_wildcard?(route)
            catch_alls << route
          end
        end

        issues
      end

      private

      def catch_all_wildcard?(route)
        path = route.path
        path == "/*path" || path == "*path" || path.match?(/\A\/?\*[a-zA-Z_]+\z/)
      end
    end
  end
end
