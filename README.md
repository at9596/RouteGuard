# RouteGuard

RouteGuard is a production-ready static analysis tool for Rails routing. It inspects your Rails routes to catch issues Rails itself doesn't report—like shadowing, duplicates, unreachable catch-alls, and duplicate resource blocks.

## Core Features

*   **Duplicate Route Detection**: Detects routes sharing the same HTTP verb and path pattern.
*   **Route Shadowing**: Flags routes that can never be matched because an earlier route matches first (e.g. `/users/:id` shadowing `/users/new`).
*   **Unreachable Routes**: Detects routes defined after catch-all wildcard routes (e.g. `match "*path"`).
*   **Duplicate Named Helpers**: Identifies duplicate helper names (e.g., duplicate `auth_path` helpers pointing to different paths).
*   **Duplicate Resources**: Warns when identical resources are declared multiple times in the same namespace scope.
*   **Route Statistics**: Computes REST resources count, nested scopes, and wildcards.
*   **Health Score**: Measures a 0-100 maintainability score based on issues and path nesting levels.

---

## Quick Start

### Installation

Add this gem to your group `:development, :test` block:

```ruby
group :development, :test do
  gem "route_guard", path: "path/to/route_guard"
end
```

Run `bundle install`.

### Run RouteGuard

Run check from the terminal:

```bash
bundle exec route_guard check
```

Or execute via Rake tasks:

```bash
bundle exec rails route_guard
bundle exec rails routes:doctor
```

---

## Documentation

For detailed configurations, options, and workflows, please see:

*   [Usage & Integration Guide](docs/usage.md)
*   [Publishing Guide](docs/publishing.md)

## License

MIT License.
