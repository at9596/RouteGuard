# frozen_string_literal: true

module RouteGuard
  module Formatter
    class Ci
      def format(report, io = $stdout)
        report.issues.each do |issue|
          severity = issue.severity == :error ? "error" : "warning"

          if issue.file && issue.line
            rel_file = issue.file.sub(/\A#{Regexp.escape(Dir.pwd)}\//, "")
            io.puts "::#{severity} file=#{rel_file},line=#{issue.line}::[RouteGuard] #{issue.message}"
          else
            io.puts "::#{severity}::[RouteGuard] #{issue.message}"
          end
        end
      end
    end
  end
end
