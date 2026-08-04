# frozen_string_literal: true

require "spec_helper"

RSpec.describe RouteGuard::Rules::Statistics do
  let(:rule) { described_class.new }
  let(:report) { RouteGuard::Models::Report.new }

  it "calculates route metrics correctly" do
    routes = draw_routes do
      get "/users/:id", to: "users#show"
      get "/categories/:category_id/posts/:id", to: "posts#show"
      get "/search/*path", to: "search#index"
    end

    rule.analyze(routes, report)
    stats = report.stats

    expect(stats[:total_routes]).to eq(3)
    expect(stats[:wildcards]).to eq(1)
    expect(stats[:maximum_nesting_depth]).to eq(2) # categories/:category_id/posts/:id has 2 dynamic params
    expect(stats[:average_nesting_depth]).to eq(1.0) # (1 + 2 + 0) / 3 = 1.0
    expect(stats[:most_common_controller]).to eq("UsersController") # users is camelized correctly
  end
end
