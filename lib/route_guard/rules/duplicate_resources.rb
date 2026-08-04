# frozen_string_literal: true

require_relative "base"
require_relative "../models/issue"
require_relative "../route_tracker"

module RouteGuard
  module Rules
    class DuplicateResources < Base
      def analyze(routes, report)
        issues = []
        calls = RouteTracker.resource_calls
        return issues if calls.empty?

        groups = Hash.new { |h, k| h[k] = [] }

        calls.each do |call|
          resource_names = call[:args].take_while { |a| a.is_a?(Symbol) || a.is_a?(String) }
          scope_path = call[:scope][:path]
          scope_module = call[:scope][:module]

          resource_names.each do |name|
            key = [scope_path, scope_module, name.to_sym]
            groups[key] << call
          end
        end

        groups.each do |(scope_path, scope_module, name), grp_calls|
          next if grp_calls.length <= 1

          primary = grp_calls.first
          duplicates = grp_calls[1..-1]

          scope_desc = [
            scope_module ? "module #{scope_module}" : nil,
            scope_path ? "path '#{scope_path}'" : nil
          ].compact.join(", ")
          scope_text = scope_desc.empty? ? "root scope" : "scope [#{scope_desc}]"

          duplicates.each do |dup|
            issues << Models::Issue.new(
              rule_name: :duplicate_resources,
              severity: :warning,
              message: "Duplicate Resource: Resource ':#{name}' is declared multiple times in #{scope_text}.",
              route: nil,
              file: dup[:trace][:file],
              line: dup[:trace][:line]
            )
          end
        end

        issues
      end
    end
  end
end
