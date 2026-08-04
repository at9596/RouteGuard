# frozen_string_literal: true

require_relative "base"

module RouteGuard
  module Rules
    class Statistics < Base
      def analyze(routes, report)
        return [] if routes.empty?

        # Calculate metrics
        total_routes = routes.length

        # REST Resources: count unique controller resource names or use RouteTracker if available
        resource_calls = RouteTracker.resource_calls
        rest_resources = if resource_calls.any?
                           resource_calls.map { |c| c[:args].first }.uniq.size
                         else
                           # Fallback: estimate from controller count
                           routes.map(&:controller).compact.uniq.size
                         end

        # Namespaces: count of unique directories in controller names
        namespaces = routes.map(&:controller).compact
                           .select { |c| c.include?("/") }
                           .map { |c| c.split("/")[0...-1].join("/") }
                           .uniq.size

        # Scopes: count of unique non-parameter, non-wildcard first-level path prefixes
        prefixes = routes.map { |r| r.path.split("/")[1] }
                         .compact
                         .reject { |p| p.start_with?(":") || p.start_with?("*") }
                         .uniq
        scopes = prefixes.size

        # Wildcards: routes containing '*'
        wildcards = routes.select { |r| r.path.include?("*") }.size

        # Nesting depth: count of dynamic parameters (:id, etc.) in route path
        depths = routes.map { |r| r.path.scan(/:\w+/).size }
        max_depth = depths.max || 0
        avg_depth = (depths.sum.to_f / total_routes).round(2)

        # Most common controller
        controller_counts = Hash.new(0)
        routes.each { |r| controller_counts[r.controller] += 1 if r.controller }
        most_common_controller = nil
        most_common_count = 0
        if controller_counts.any?
          raw_controller, most_common_count = controller_counts.max_by { |_, count| count }
          most_common_controller = camelize_controller(raw_controller)
        end

        # Store in report stats (will be updated with issues later)
        report.stats = {
          total_routes: total_routes,
          rest_resources: rest_resources,
          namespaces: namespaces,
          scopes: scopes,
          wildcards: wildcards,
          duplicate_paths: 0, # Will be set by analyzer after running all rules
          shadowed_routes: 0, # Will be set by analyzer
          average_nesting_depth: avg_depth,
          maximum_nesting_depth: max_depth,
          most_common_controller: most_common_controller,
          most_common_count: most_common_count
        }

        [] # Statistics rule does not generate issues itself
      end

      private

      def camelize_controller(name)
        return nil unless name
        name.to_s.split("/").map { |part| part.split("_").map(&:capitalize).join }.join("::") + "Controller"
      end
    end
  end
end

