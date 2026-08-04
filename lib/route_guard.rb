# frozen_string_literal: true

require_relative "route_guard/version"
require_relative "route_guard/configuration"
require_relative "route_guard/models/route"
require_relative "route_guard/models/issue"
require_relative "route_guard/models/report"
require_relative "route_guard/route_tracker"
require_relative "route_guard/route_loader"
require_relative "route_guard/analyzer"
require_relative "route_guard/inspector"
require_relative "route_guard/cli"

require_relative "route_guard/railtie" if defined?(Rails::Railtie)
