# frozen_string_literal: true

require "thor"
require_relative "../route_guard"

module RouteGuard
  class CLI < Thor
    class_option :strict, type: :boolean, default: false, desc: "Treat warnings as errors"
    class_option :format, type: :string, default: "terminal", desc: "Output format: terminal, json, html, ci"
    class_option :only, type: :array, default: [], desc: "Run only specified rules"
    class_option :except, type: :array, default: [], desc: "Exclude specified rules"
    class_option :fail_on_warning, type: :boolean, default: false, desc: "Fail if warnings are found"
    class_option :verbose, type: :boolean, default: false, desc: "Print verbose output"
    class_option :output, type: :string, desc: "Output file path"

    desc "check", "Analyze Rails routes for issues"
    def check
      config = build_config
      inspector = Inspector.new(config)
      report = inspector.run

      fmt = (options[:format] || "terminal").to_sym
      io = if options[:output]
             File.open(options[:output], "w")
           else
             $stdout
           end

      inspector.format(report, fmt, io)
      io.close if options[:output]

      exit_status(report, config)
    end

    default_task :check

    desc "stats", "Calculate routing statistics and metrics"
    def stats
      config = build_config
      config.rules = [:statistics]
      inspector = Inspector.new(config)
      report = inspector.run

      fmt = (options[:format] || "terminal").to_sym
      if fmt == :json
        inspector.format(report, :json)
      else
        inspector.format(report, :terminal)
      end
    end

    desc "doctor", "Thoroughly inspect and report on route health"
    def doctor
      config = build_config
      config.strict = true
      config.fail_on_warning = true
      inspector = Inspector.new(config)
      report = inspector.run
      inspector.format(report, :terminal)
      exit_status(report, config)
    end

    desc "json", "Output results in JSON format"
    def json
      config = build_config
      config.formatters = [:json]
      inspector = Inspector.new(config)
      report = inspector.run
      inspector.format(report, :json)
      exit_status(report, config)
    end

    desc "html", "Generate a beautiful HTML report"
    def html
      config = build_config
      config.formatters = [:html]
      inspector = Inspector.new(config)
      report = inspector.run

      output_file = options[:output] || "route_guard_report.html"
      File.open(output_file, "w") do |f|
        inspector.format(report, :html, f)
      end
      puts "HTML report generated at #{output_file}"
      exit_status(report, config)
    end

    # Disable Thor's exit-on-failure behavior by default to control exit statuses
    def self.exit_on_failure?
      true
    end

    private

    def build_config
      config = Configuration.new
      config.strict = options[:strict]
      config.fail_on_warning = options[:fail_on_warning]
      config.only = options[:only] || []
      config.except = options[:except] || []
      config.verbose = options[:verbose]

      fmt = (options[:format] || "terminal").to_sym
      config.formatters = [fmt]
      config
    end

    def exit_status(report, config = nil)
      strict = config ? config.strict : options[:strict]
      fail_on_warning = config ? config.fail_on_warning : options[:fail_on_warning]

      if report.errors.any?
        exit(1)
      elsif fail_on_warning && report.warnings.any?
        exit(1)
      elsif strict && report.warnings.any?
        exit(1)
      else
        exit(0)
      end
    end
  end
end
