# frozen_string_literal: true

require_relative "configuration"
require_relative "route_loader"
require_relative "analyzer"

module RouteGuard
  class Inspector
    attr_reader :config

    def initialize(config = Configuration.new)
      @config = config
    end

    def run
      $stderr.puts "RouteGuard: Loading Rails environment and reloading routes..."

      routes = RouteLoader.load

      $stderr.puts "RouteGuard: Loaded #{routes.size} routes. Running #{config.enabled_rules.size} inspections..."

      report = Analyzer.analyze(routes, config.enabled_rules, {
        strict: config.strict,
        verbose: config.verbose
      })

      $stderr.puts "RouteGuard: Inspections complete."

      report
    end

    def format(report, formatter_sym, io = $stdout)
      formatter = load_formatter(formatter_sym)
      formatter.format(report, io)
    end

    private

    def load_formatter(fmt)
      case fmt.to_sym
      when :terminal
        require_relative "formatter/terminal"
        Formatter::Terminal.new(verbose: config.verbose)
      when :json
        require_relative "formatter/json"
        Formatter::Json.new
      when :html
        require_relative "formatter/html"
        Formatter::Html.new
      when :ci
        require_relative "formatter/ci"
        Formatter::Ci.new
      else
        raise "Unknown formatter: #{fmt}"
      end
    end
  end
end
