# frozen_string_literal: true

require "spec_helper"

RSpec.describe RouteGuard::Rules::Base do
  let(:base_rule) { described_class.new }

  describe "#analyze" do
    it "raises NotImplementedError" do
      expect { base_rule.analyze([], nil) }.to raise_error(NotImplementedError)
    end
  end

  describe "#expand_path" do
    it "expands nested optional segments" do
      expansions = base_rule.expand_path("/posts(/:year(/:month))")
      expect(expansions).to contain_exactly(
        "/posts",
        "/posts/:year",
        "/posts/:year/:month"
      )
    end
  end

  describe "#path_shadows?" do
    it "returns false if B has a wildcard and A does not" do
      seg_a = ["", "users"]
      seg_b = ["", "*path"]
      expect(base_rule.path_shadows?(seg_a, seg_b, {}, {})).to be false
    end

    it "handles matching constraints on dynamic segments" do
      seg_a = ["", "users", ":id"]
      seg_b = ["", "users", ":user_id"]

      # Both constrained to digits
      const_a = { id: /\d+/ }
      const_b = { user_id: /\d+/ }
      expect(base_rule.path_shadows?(seg_a, seg_b, const_a, const_b)).to be true

      # A is constrained, but B is not
      expect(base_rule.path_shadows?(seg_a, seg_b, const_a, {})).to be false
    end

    it "handles string constraints" do
      seg_a = ["", "users", ":id"]
      seg_b = ["", "users", "new"]

      expect(base_rule.path_shadows?(seg_a, seg_b, { id: "new" }, {})).to be true
      expect(base_rule.path_shadows?(seg_a, seg_b, { id: "edit" }, {})).to be false
    end

    it "handles string and regexp constraint combinations" do
      seg_a = ["", "users", ":id"]
      seg_b = ["", "users", ":user_id"]

      # constA is Regexp, constB is String
      expect(base_rule.path_shadows?(seg_a, seg_b, { id: /\d+/ }, { user_id: "123" })).to be true
      expect(base_rule.path_shadows?(seg_a, seg_b, { id: /\d+/ }, { user_id: "abc" })).to be false

      # constA is String, constB is Regexp
      expect(base_rule.path_shadows?(seg_a, seg_b, { id: "123" }, { user_id: /\d+/ })).to be true
      expect(base_rule.path_shadows?(seg_a, seg_b, { id: "abc" }, { user_id: /\d+/ })).to be false
    end

    it "returns false if sA is literal and sB is dynamic" do
      seg_a = ["", "users", "new"]
      seg_b = ["", "users", ":id"]

      expect(base_rule.path_shadows?(seg_a, seg_b, {}, {})).to be false
    end

    it "returns false if lengths differ and no wildcard exists" do
      seg_a = ["", "users"]
      seg_b = ["", "users", "new"]
      expect(base_rule.path_shadows?(seg_a, seg_b, {}, {})).to be false
    end
  end
end
