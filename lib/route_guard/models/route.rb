# frozen_string_literal: true

module RouteGuard
  module Models
    class Route
      attr_reader :verb, :path, :original_path, :controller, :action, :name, :constraints, :file, :line, :defaults

      def initialize(verb:, path:, original_path:, controller:, action:, name: nil, constraints: {}, file: nil, line: nil, defaults: {})
        @verb = verb.to_s.upcase
        @original_path = original_path.to_s
        @path = path.to_s
        @controller = controller&.to_s
        @action = action&.to_s
        @name = name&.to_s
        @constraints = constraints || {}
        @file = file
        @line = line ? line.to_i : nil
        @defaults = defaults || {}
      end

      def internal?
        controller.to_s.start_with?("rails/") || path.start_with?("/rails/") || path == "/assets"
      end

      def location
        if file && line
          # Try to make path relative to pwd for better readability
          relative_file = file.sub(/\A#{Regexp.escape(Dir.pwd)}\//, "")
          "#{relative_file}:#{line}"
        elsif file
          file.sub(/\A#{Regexp.escape(Dir.pwd)}\//, "")
        else
          "unknown location"
        end
      end

      def to_s
        "#{verb} #{path}"
      end
    end
  end
end
