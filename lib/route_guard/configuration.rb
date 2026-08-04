# frozen_string_literal: true

module RouteGuard
  class Configuration
    attr_accessor :rules, :formatters, :strict, :fail_on_warning, :only, :except, :verbose

    ALL_RULES = %i[
      duplicate_routes
      shadowed_routes
      unreachable_routes
      duplicate_helpers
      duplicate_resources
      unused_routes
      statistics
      complexity
    ].freeze

    def initialize
      @rules = ALL_RULES.dup
      @formatters = [:terminal]
      @strict = false
      @fail_on_warning = false
      @only = []
      @except = []
      @verbose = false
    end

    def enabled_rules
      active_rules = if only.any?
                       rules & only.map(&:to_sym)
                     else
                       rules
                     end

      active_rules - except.map(&:to_sym)
    end
  end
end
