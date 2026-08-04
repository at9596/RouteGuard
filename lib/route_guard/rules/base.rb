# frozen_string_literal: true

module RouteGuard
  module Rules
    class Base
      attr_reader :options

      def initialize(options = {})
        @options = options
      end

      def analyze(routes, report)
        raise NotImplementedError, "#{self.class} must implement #analyze(routes, report)"
      end

      # Expands optional path segments in route paths
      # e.g., "/users(.:format)" -> ["/users", "/users.:format"]
      # "/posts(/:year(/:month))" -> ["/posts", "/posts/:year", "/posts/:year/:month"]
      def expand_path(path)
        start_idx = path.index("(")
        return [path] unless start_idx

        # Find matching ')' at top level
        depth = 0
        end_idx = nil
        path.chars.each_with_index do |char, idx|
          if char == "("
            depth += 1
          elsif char == ")"
            depth -= 1
            if depth == 0
              end_idx = idx
              break
            end
          end
        end

        raise "Unmatched parenthesis in path: #{path}" unless end_idx

        before = path[0...start_idx]
        inside = path[(start_idx + 1)...end_idx]
        after = path[(end_idx + 1)..-1]

        inside_expansions = expand_path(inside)
        after_expansions = expand_path(after)

        results = []
        # Case 1: Omit the inside group
        after_expansions.each do |after_exp|
          results << (before + after_exp)
        end
        # Case 2: Include the inside group
        inside_expansions.each do |inside_exp|
          after_expansions.each do |after_exp|
            results << (before + inside_exp + after_exp)
          end
        end

        results.uniq
      end

      # Splits a path string into segment tokens, handling dots and slashes
      def split_segments(path)
        segments = []
        path.split("/").each do |seg|
          if seg.include?(".")
            parts = seg.split(".")
            segments << parts.first
            parts[1..-1].each { |p| segments << ".#{p}" }
          else
            segments << seg
          end
        end
        segments
      end

      # Checks if verbA matches verbB (handling ANY/wildcard)
      def verb_matches?(verbA, verbB)
        return true if verbA == "ANY" || verbB == "ANY"

        verbsA = verbA.split("|")
        verbsB = verbB.split("|")
        (verbsA & verbsB).any?
      end

      # Checks if Route A matches (shadows) Route B's path representation.
      def path_shadows?(segA, segB, constraintsA, constraintsB)
        idxA = 0
        idxB = 0

        while idxA < segA.length && idxB < segB.length
          sA = segA[idxA]
          sB = segB[idxB]

          if sA.start_with?("*")
            return true
          end

          if sB.start_with?("*")
            return false
          end

          if sA.start_with?(":")
            param_A = sA[1..-1]
            constA = constraintsA[param_A.to_sym]

            if sB.start_with?(":")
              param_B = sB[1..-1]
              constB = constraintsB[param_B.to_sym]

              if constA
                if constB
                  match = if constA.is_a?(Regexp)
                            if constB.is_a?(Regexp)
                              constB.source == constA.source || constA.match?(constB.source)
                            else
                              constA.match?(constB.to_s)
                            end
                          else
                            if constB.is_a?(Regexp)
                              constB.match?(constA.to_s)
                            else
                              constA.to_s == constB.to_s
                            end
                          end
                  return false unless match
                else
                  return false
                end
              end
            else
              # sB is literal
              if constA
                match = if constA.is_a?(Regexp)
                          constA.match?(sB)
                        else
                          constA.to_s == sB
                        end
                return false unless match
              end
            end
          else
            # sA is literal
            if sB.start_with?(":")
              return false
            else
              return false if sA != sB
            end
          end

          idxA += 1
          idxB += 1
        end

        if idxA == segA.length && idxB == segB.length
          true
        else
          false
        end
      end
    end
  end
end
