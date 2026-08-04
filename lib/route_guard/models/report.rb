# frozen_string_literal: true

module RouteGuard
  module Models
    class Report
      attr_accessor :routes, :issues, :stats, :complexity_score, :duration

      def initialize(routes = [])
        @routes = routes
        @issues = []
        @stats = {}
        @complexity_score = 100
        @duration = 0.0
      end

      def errors
        issues.select { |i| i.severity == :error }
      end

      def warnings
        issues.select { |i| i.severity == :warning }
      end

      def passed?
        errors.empty?
      end
    end
  end
end
