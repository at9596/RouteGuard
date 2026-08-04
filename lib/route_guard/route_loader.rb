# frozen_string_literal: true

require_relative "models/route"
require_relative "route_tracker"

module RouteGuard
  class RouteLoader
    def self.load
      load_environment!

      RouteTracker.reset!
      RouteTracker.enable_tracking!
      RouteTracker.enabled = true

      begin
        $stderr.puts "RouteGuard Debug: defined?(Rails) = #{defined?(Rails)}"
        if defined?(Rails)
          $stderr.puts "RouteGuard Debug: Rails.respond_to?(:application) = #{Rails.respond_to?(:application)}"
          $stderr.puts "RouteGuard Debug: Rails.application = #{Rails.application.nil? ? 'nil' : Rails.application.class.name}"
          if Rails.respond_to?(:application) && Rails.application
            $stderr.puts "RouteGuard Debug: Routes size before reload = #{Rails.application.routes.routes.size}"
            Rails.application.reload_routes!
            $stderr.puts "RouteGuard Debug: Routes size after reload = #{Rails.application.routes.routes.size}"
          end
        end

        if defined?(Rails) && Rails.respond_to?(:application) && Rails.application
          load_from_route_set(Rails.application.routes)
        else
          []
        end
      ensure
        RouteTracker.enabled = false
      end
    end

    def self.load_environment!
      return if defined?(Rails)

      env_file = File.expand_path("config/environment.rb", Dir.pwd)
      if File.exist?(env_file)
        original_stdout = $stdout.clone
        original_stderr = $stderr.clone
        begin
          $stdout.reopen(File::NULL, "w")
          $stderr.reopen(File::NULL, "w")
          require env_file
        ensure
          $stdout.reopen(original_stdout)
          $stderr.reopen(original_stderr)
        end
      end
    end

    def self.load_from_route_set(route_set)
      routes = []
      route_set.routes.each do |r|
        # Skip internal rails routes if the route itself responds to internal?
        next if r.respond_to?(:internal?) && r.internal?

        # Extract verb
        verb = if r.verb.is_a?(Regexp)
                 r.verb.source.gsub(/[^A-Z|]/, "")
               else
                 r.verb.to_s.upcase
               end
        verb = "ANY" if verb.empty?

        # Extract path
        original_path = if r.respond_to?(:path) && r.path.respond_to?(:spec)
                          r.path.spec.to_s
                        else
                          r.path.to_s
                        end

        path = original_path.gsub(/\(\.\:format\)\z/, "").gsub(/\(\/:format\)\z/, "")

        defaults = r.defaults || {}
        controller = defaults[:controller]
        action = defaults[:action]
        name = r.name
        constraints = r.requirements || {}

        trace_info = RouteTracker.route_traces[r.object_id] || r.instance_variable_get(:@route_guard_trace)
        file = trace_info&.[](:file)
        line = trace_info&.[](:line)

        route = Models::Route.new(
          verb: verb,
          path: path,
          original_path: original_path,
          controller: controller,
          action: action,
          name: name,
          constraints: constraints,
          file: file,
          line: line,
          defaults: defaults
        )

        next if route.internal?

        routes << route
      end
      routes
    end
  end
end
