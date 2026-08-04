# frozen_string_literal: true

require_relative "base"
require_relative "../models/issue"

module RouteGuard
  module Rules
    class UnusedRoutes < Base
      def analyze(routes, report)
        issues = []
        return issues unless defined?(Rails)

        routes.each do |route|
          next if route.controller.nil? || route.action.nil?
          next if route.internal?

          controller_class_name = camelize_controller(route.controller)

          begin
            klass = if controller_class_name.respond_to?(:safe_constantize)
                      controller_class_name.safe_constantize
                    else
                      Object.const_get(controller_class_name) rescue nil
                    end

            if klass
              if klass.respond_to?(:action_methods)
                unless klass.action_methods.include?(route.action.to_s)
                  issues << Models::Issue.new(
                    rule_name: :unused_routes,
                    severity: :warning,
                    message: "Unused Route: Action '#{route.action}' is missing in #{controller_class_name}.",
                    route: route
                  )
                end
              end
            else
              issues << Models::Issue.new(
                rule_name: :unused_routes,
                severity: :warning,
                message: "Unused Route: Controller #{controller_class_name} does not exist.",
                route: route
              )
            end
          rescue NameError, LoadError
            issues << Models::Issue.new(
              rule_name: :unused_routes,
              severity: :warning,
              message: "Unused Route: Controller #{controller_class_name} could not be loaded.",
              route: route
            )
          end
        end

        issues
      end

      private

      def camelize_controller(name)
        return nil unless name
        name.to_s.split("/").map { |part| part.split("_").map(&:capitalize).join }.join("::") + "Controller"
      end
    end
  end
end
