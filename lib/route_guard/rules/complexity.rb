# frozen_string_literal: true

require_relative "base"

module RouteGuard
  module Rules
    class Complexity < Base
      def analyze(routes, report)
        score = 100

        # 1. Penalties based on issues present in the report
        issues = report.issues || []
        
        duplicate_count = issues.count { |i| i.rule_name == :duplicate_routes }
        shadowed_count = issues.count { |i| i.rule_name == :shadowed_routes }
        unreachable_count = issues.count { |i| i.rule_name == :unreachable_routes }
        helper_count = issues.count { |i| i.rule_name == :duplicate_helpers }
        resource_count = issues.count { |i| i.rule_name == :duplicate_resources }

        score -= duplicate_count * 10
        score -= shadowed_count * 15
        score -= unreachable_count * 20
        score -= helper_count * 5
        score -= resource_count * 5

        # 2. Nesting depth penalties
        stats = report.stats || {}
        max_depth = stats[:maximum_nesting_depth] || 0
        avg_depth = stats[:average_nesting_depth] || 0.0

        if max_depth > 3
          score -= (max_depth - 3) * 5
        end

        if avg_depth > 2.0
          score -= ((avg_depth - 2.0) * 10).round
        end

        # 3. Wildcard usage penalty
        wildcards = stats[:wildcards] || 0
        score -= wildcards * 2

        # Clamp score between 0 and 100
        score = [0, [score, 100].min].max
        report.complexity_score = score

        # Return a warning if the score is critically low (< 70) and verbose is enabled
        issues_to_return = []
        if score < 70
          issues_to_return << Models::Issue.new(
            rule_name: :complexity,
            severity: :warning,
            message: "Route Complexity: Overall route health is low (#{score}/100). Consider refactoring nested resources or namespaces.",
            route: nil
          )
        end

        issues_to_return
      end
    end
  end
end
