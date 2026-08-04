# frozen_string_literal: true

module RouteGuard
  module RouteTracker
    class << self
      attr_accessor :enabled

      def route_traces
        @route_traces ||= {}
      end

      def resource_calls
        @resource_calls ||= []
      end

      def reset!
        @route_traces = {}
        @resource_calls = []
      end

      def track_route(route_object_id, trace_info)
        return unless @enabled
        route_traces[route_object_id] = trace_info
      end

      def track_resource(type, args, scope, trace_info)
        return unless @enabled
        resource_calls << {
          type: type,
          args: args,
          scope: scope,
          trace: trace_info
        }
      end

      def enable_tracking!
        return if @prepended

        if defined?(ActionDispatch::Routing::RouteSet)
          ActionDispatch::Routing::RouteSet.prepend(RouteGuard::RouteSetExtension)
        end

        if defined?(ActionDispatch::Routing::Mapper)
          ActionDispatch::Routing::Mapper.prepend(RouteGuard::MapperExtension)
        end

        if defined?(ActionDispatch::Routing::RouteSet::NamedRouteCollection)
          ActionDispatch::Routing::RouteSet::NamedRouteCollection.prepend(RouteGuard::NamedRouteCollectionExtension)
        end

        @prepended = true
      end

      def find_routes_caller(locations)
        return nil unless locations
        loc = locations.find do |l|
          path = l.path
          path.include?("config/routes") ||
            path.include?("/routes.rb") ||
            (defined?(RSpec) && path.include?("_spec.rb"))
        end

        if loc
          { file: loc.path, line: loc.lineno }
        end
      end
    end
  end

  module RouteSetExtension
    def add_route(*args)
      route = super
      if RouteGuard::RouteTracker.enabled
        trace_info = RouteGuard::RouteTracker.find_routes_caller(caller_locations(1, 25))
        if trace_info
          if route.is_a?(Array)
            route.each do |r|
              RouteGuard::RouteTracker.track_route(r.object_id, trace_info)
              r.instance_variable_set(:@route_guard_trace, trace_info)
            end
          elsif route
            RouteGuard::RouteTracker.track_route(route.object_id, trace_info)
            route.instance_variable_set(:@route_guard_trace, trace_info)
          end
        end
      end
      route
    end
  end

  module MapperExtension
    def resources(*args, &block)
      if RouteGuard::RouteTracker.enabled
        trace_info = RouteGuard::RouteTracker.find_routes_caller(caller_locations(1, 25))
        if trace_info
          RouteGuard::RouteTracker.track_resource(:resources, args, scope_info, trace_info)
        end
      end
      super
    end

    def resource(*args, &block)
      if RouteGuard::RouteTracker.enabled
        trace_info = RouteGuard::RouteTracker.find_routes_caller(caller_locations(1, 25))
        if trace_info
          RouteGuard::RouteTracker.track_resource(:resource, args, scope_info, trace_info)
        end
      end
      super
    end

    private

    def scope_info
      return {} unless defined?(@scope) && @scope
      {
        path: @scope[:path],
        module: @scope[:module],
        as: @scope[:as]
      }
    end
  end

  module NamedRouteCollectionExtension
    def [](name)
      if RouteGuard::RouteTracker.enabled
        nil
      else
        super
      end
    end

    def key?(name)
      if RouteGuard::RouteTracker.enabled
        false
      else
        super
      end
    end
  end
end
