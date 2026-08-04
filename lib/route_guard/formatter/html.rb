# frozen_string_literal: true

require "cgi"
require "json"
require_relative "../version"

module RouteGuard
  module Formatter
    class Html
      def format(report, io = $stdout)
        io.puts html_template(report)
      end

      private

      def html_template(report)
        issues_json = report.issues.map { |i| format_issue_for_js(i) }
        stats = report.stats || {}
        score = report.complexity_score

        # Color configurations based on score
        score_color = if score >= 90
                        "from-emerald-400 to-teal-600"
                      elsif score >= 70
                        "from-amber-400 to-orange-500"
                      else
                        "from-rose-500 to-red-700"
                      end

        <<-HTML
<!DOCTYPE html>
<html lang="en" class="h-full bg-slate-50 text-slate-900">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>RouteGuard Report</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
  <style>
    body {
      font-family: 'Plus Jakarta Sans', sans-serif;
    }
    code, pre {
      font-family: 'JetBrains Mono', monospace;
    }
  </style>
</head>
<body class="min-h-full flex flex-col antialiased bg-slate-50">
  <!-- Header -->
  <header class="border-b border-slate-200 bg-white/80 backdrop-blur-md sticky top-0 z-50 shadow-sm">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
      <div class="flex items-center space-x-3">
        <div class="bg-gradient-to-tr from-indigo-600 to-cyan-500 p-2 rounded-xl shadow-md shadow-indigo-600/10">
          <svg class="w-6 h-6 text-white font-bold" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/>
          </svg>
        </div>
        <div>
          <span class="text-xl font-bold tracking-tight bg-gradient-to-r from-slate-900 to-slate-700 bg-clip-text text-transparent">RouteGuard</span>
          <span class="text-xs ml-2 text-indigo-600 font-semibold px-2 py-0.5 rounded-full bg-indigo-50 border border-indigo-100">v#{RouteGuard::VERSION}</span>
        </div>
      </div>
      <div class="text-sm text-slate-500 flex items-center space-x-4">
        <span>Analyzed: <strong class="text-slate-800">#{Time.now.strftime('%Y-%m-%d %H:%M:%S UTC')}</strong></span>
        <span class="h-4 w-px bg-slate-200"></span>
        <span>Duration: <strong class="text-slate-800">#{(report.duration * 1000).round(2)}ms</strong></span>
      </div>
    </div>
  </header>

  <main class="flex-grow max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-8">
    <!-- Top Dashboard Section -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
      <!-- Health Score Card -->
      <div class="bg-white border border-slate-200 rounded-3xl p-6 flex flex-col items-center justify-center relative overflow-hidden shadow-sm">
        <div class="absolute inset-0 bg-gradient-to-br from-indigo-50/50 to-cyan-50/30"></div>
        <h2 class="text-sm font-semibold tracking-wide text-slate-500 uppercase mb-4 z-10">Route Health Score</h2>
        <div class="relative flex items-center justify-center">
          <!-- Circular Progress SVG -->
          <svg class="w-40 h-40 transform -rotate-90">
            <circle cx="80" cy="80" r="70" stroke="currentColor" stroke-width="8" class="text-slate-100" fill="transparent" />
            <circle cx="80" cy="80" r="70" stroke="url(#gradient)" stroke-width="10" stroke-dasharray="440" stroke-dashoffset="#{440 - (440 * score / 100)}" stroke-linecap="round" fill="transparent" class="transition-all duration-1000 ease-out" />
            <defs>
              <linearGradient id="gradient" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" class="text-cyan-500" stop-color="currentColor"/>
                <stop offset="100%" class="text-indigo-600" stop-color="currentColor"/>
              </linearGradient>
            </defs>
          </svg>
          <div class="absolute text-center">
            <span class="text-4xl font-extrabold tracking-tight text-slate-900">#{score}</span>
            <span class="text-slate-500 text-sm block">/ 100</span>
          </div>
        </div>
        <p class="mt-4 text-xs text-slate-500 text-center font-medium z-10">
          #{score >= 90 ? "Excellent. Your route file is well organized." : (score >= 70 ? "Good. Some optimization opportunities found." : "Critically low health. Refactoring recommended.")}
        </p>
      </div>

      <!-- Statistics Grid -->
      <div class="lg:col-span-2 bg-white border border-slate-200 rounded-3xl p-6 grid grid-cols-2 sm:grid-cols-3 gap-6 shadow-sm relative">
        <div class="absolute inset-0 bg-gradient-to-br from-white to-slate-50/30 pointer-events-none rounded-3xl"></div>
        <div class="relative z-10 flex flex-col justify-between p-4 bg-slate-50/50 border border-slate-100 rounded-2xl">
          <span class="text-xs font-semibold text-slate-500 uppercase tracking-wider">Total Routes</span>
          <span class="text-3xl font-extrabold text-slate-900 mt-2">#{stats[:total_routes] || 0}</span>
        </div>
        <div class="relative z-10 flex flex-col justify-between p-4 bg-slate-50/50 border border-slate-100 rounded-2xl">
          <span class="text-xs font-semibold text-slate-500 uppercase tracking-wider">REST Resources</span>
          <span class="text-3xl font-extrabold text-slate-900 mt-2">#{stats[:rest_resources] || 0}</span>
        </div>
        <div class="relative z-10 flex flex-col justify-between p-4 bg-slate-50/50 border border-slate-100 rounded-2xl">
          <span class="text-xs font-semibold text-slate-500 uppercase tracking-wider">Namespaces</span>
          <span class="text-3xl font-extrabold text-slate-900 mt-2">#{stats[:namespaces] || 0}</span>
        </div>
        <div class="relative z-10 flex flex-col justify-between p-4 bg-slate-50/50 border border-slate-100 rounded-2xl">
          <span class="text-xs font-semibold text-slate-500 uppercase tracking-wider">Scopes</span>
          <span class="text-3xl font-extrabold text-slate-900 mt-2">#{stats[:scopes] || 0}</span>
        </div>
        <div class="relative z-10 flex flex-col justify-between p-4 bg-slate-50/50 border border-slate-100 rounded-2xl">
          <span class="text-xs font-semibold text-slate-500 uppercase tracking-wider">Wildcard Paths</span>
          <span class="text-3xl font-extrabold text-amber-600 mt-2">#{stats[:wildcards] || 0}</span>
        </div>
        <div class="relative z-10 flex flex-col justify-between p-4 bg-slate-50/50 border border-slate-100 rounded-2xl">
          <span class="text-xs font-semibold text-slate-500 uppercase tracking-wider">Nesting Depth</span>
          <span class="text-3xl font-extrabold text-slate-900 mt-2">#{stats[:average_nesting_depth] || 0.0}<span class="text-xs text-slate-400 font-normal"> avg / #{stats[:maximum_nesting_depth] || 0} max</span></span>
        </div>
      </div>
    </div>

    <!-- Quick info alert if any low-health issues -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <div class="bg-rose-50 border border-rose-100 rounded-2xl p-4 flex items-center space-x-3 shadow-sm">
        <div class="p-2 bg-rose-100 text-rose-600 rounded-lg">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
        </div>
        <div>
          <span class="text-xs text-slate-500 block font-semibold">Errors</span>
          <span class="text-lg font-bold text-rose-700">#{report.errors.length}</span>
        </div>
      </div>
      <div class="bg-amber-50 border border-amber-100 rounded-2xl p-4 flex items-center space-x-3 shadow-sm">
        <div class="p-2 bg-amber-100 text-amber-600 rounded-lg">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
        </div>
        <div>
          <span class="text-xs text-slate-500 block font-semibold">Warnings</span>
          <span class="text-lg font-bold text-amber-700">#{report.warnings.length}</span>
        </div>
      </div>
      <div class="bg-slate-50 border border-slate-100 rounded-2xl p-4 flex items-center space-x-3 shadow-sm">
        <div class="p-2 bg-slate-200/60 text-slate-600 rounded-lg">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"/></svg>
        </div>
        <div>
          <span class="text-xs text-slate-500 block font-semibold">Most Common Controller</span>
          <span class="text-sm font-bold text-slate-800 truncate max-w-[200px]" title="#{stats[:most_common_controller]}">
            #{stats[:most_common_controller] || "N/A"} <span class="text-xs text-slate-500 font-normal">(#{stats[:most_common_count] || 0} routes)</span>
          </span>
        </div>
      </div>
    </div>

    <!-- Issues Explorer -->
    <div class="bg-white border border-slate-200 rounded-3xl overflow-hidden shadow-sm">
      <div class="px-6 py-5 border-b border-slate-150 bg-slate-50/50 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 class="text-lg font-bold text-slate-900">Inspections & Issues</h2>
          <p class="text-xs text-slate-500 mt-1">Review lint warnings and details for optimized routing behavior.</p>
        </div>
        <!-- Filters -->
        <div class="flex items-center space-x-2">
          <button onclick="filterIssues('all')" id="btn-all" class="px-3 py-1.5 rounded-lg text-xs font-semibold bg-indigo-600 text-white shadow-md shadow-indigo-600/10 transition-all">All</button>
          <button onclick="filterIssues('error')" id="btn-error" class="px-3 py-1.5 rounded-lg text-xs font-semibold bg-slate-100 text-slate-500 hover:bg-slate-200 transition-all">Errors</button>
          <button onclick="filterIssues('warning')" id="btn-warning" class="px-3 py-1.5 rounded-lg text-xs font-semibold bg-slate-100 text-slate-500 hover:bg-slate-200 transition-all">Warnings</button>
        </div>
      </div>

      <!-- Issues List -->
      <div class="divide-y divide-slate-100" id="issues-container">
        <!-- JS will populate these -->
      </div>
      <div id="no-issues-placeholder" class="hidden py-16 text-center">
        <svg class="w-12 h-12 text-slate-300 mx-auto mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
        <span class="text-slate-500 font-medium">Hurrah! No routing issues detected.</span>
      </div>
    </div>
  </main>

  <footer class="border-t border-slate-200 bg-white py-6 mt-12 text-center text-xs text-slate-400">
    <p>Generated by RouteGuard &bull; Keep your Rails routes performant and tidy.</p>
  </footer>

  <script>
    const issues = #{JSON.generate(issues_json)};

    function renderIssues(list) {
      const container = document.getElementById('issues-container');
      const placeholder = document.getElementById('no-issues-placeholder');
      
      container.innerHTML = '';
      
      if (list.length === 0) {
        placeholder.classList.remove('hidden');
        return;
      }
      placeholder.classList.add('hidden');

      list.forEach((issue, index) => {
        const severityBadge = issue.severity === 'error' 
          ? '<span class="px-2 py-0.5 text-[10px] font-bold uppercase rounded bg-rose-100 text-rose-700 border border-rose-200">Error</span>'
          : '<span class="px-2 py-0.5 text-[10px] font-bold uppercase rounded bg-amber-100 text-amber-700 border border-amber-200">Warning</span>';

        const relatedSection = issue.related_routes.length > 0 
          ? `<div class="mt-3 p-3 bg-slate-50/50 rounded-xl border border-slate-200/60">
               <span class="text-xs font-semibold text-slate-500 block mb-2">Related Route(s):</span>
               <div class="space-y-2">
                 ${issue.related_routes.map(r => `
                   <div class="text-xs flex items-center justify-between">
                     <code class="text-indigo-600 font-semibold">${r.verb} ${r.path}</code>
                     <code class="text-slate-500 text-[11px] underline">${r.location}</code>
                   </div>
                 `).join('')}
               </div>
             </div>`
          : '';

        const item = document.createElement('div');
        item.className = 'p-6 hover:bg-slate-50/40 transition-colors';
        item.innerHTML = `
          <div class="flex items-start justify-between gap-4">
            <div class="space-y-2">
              <div class="flex items-center space-x-2">
                ${severityBadge}
                <span class="text-xs font-bold text-indigo-600 tracking-wide uppercase">${issue.rule_name.replace(/_/g, ' ')}</span>
              </div>
              <h3 class="text-sm font-semibold text-slate-900 mt-1">${escapeHtml(issue.message)}</h3>
              ${issue.route ? `<div class="text-xs flex items-center space-x-2 text-slate-600">
                <span class="font-medium text-slate-500">Route:</span>
                <code class="px-1.5 py-0.5 rounded bg-slate-50 border border-slate-200 text-cyan-700 font-semibold">${issue.route.verb} ${issue.route.path}</code>
              </div>` : ''}
            </div>
            
            <div class="text-right">
              ${issue.location ? `<code class="text-xs text-slate-400 underline block">${issue.location}</code>` : ''}
            </div>
          </div>
          ${relatedSection}
        `;
        container.appendChild(item);
      });
    }

    function filterIssues(severity) {
      const buttons = ['all', 'error', 'warning'];
      buttons.forEach(b => {
        const btn = document.getElementById('btn-' + b);
        if (b === severity) {
          btn.className = 'px-3 py-1.5 rounded-lg text-xs font-semibold bg-indigo-600 text-white shadow-md shadow-indigo-600/10 transition-all';
        } else {
          btn.className = 'px-3 py-1.5 rounded-lg text-xs font-semibold bg-slate-100 text-slate-500 hover:bg-slate-200 transition-all';
        }
      });

      if (severity === 'all') {
        renderIssues(issues);
      } else {
        const filtered = issues.filter(i => i.severity === severity);
        renderIssues(filtered);
      }
    }

    function escapeHtml(str) {
      if (!str) return '';
      return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#039;");
    }

    // Initial load
    renderIssues(issues);
  </script>
</body>
</html>
        HTML
      end

      def format_issue_for_js(issue)
        {
          rule_name: issue.rule_name.to_s,
          severity: issue.severity.to_s,
          message: issue.message,
          location: issue.location,
          route: issue.route ? { verb: issue.route.verb, path: issue.route.path } : nil,
          related_routes: issue.related_routes.map { |r| { verb: r.verb, path: r.path, location: r.location } }
        }
      end
    end
  end
end
