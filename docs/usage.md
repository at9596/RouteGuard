# RouteGuard: Usage Guide

This guide explains how to install, integrate, and run **RouteGuard** in your Rails application.

---

## 1. Installation

Add `route_guard` to your application's `Gemfile`. Since RouteGuard has zero runtime overhead in production, it is highly recommended to group it under `:development` and `:test`:

```ruby
group :development, :test do
  gem "route_guard", path: "path/to/route_guard" # During local development
  # Or once published:
  # gem "route_guard"
end
```

Then execute:

```bash
bundle install
```

---

## 2. Command Line Interface (CLI)

You can run RouteGuard directly from your terminal. Since it automatically boot-loads your Rails environment, make sure to execute it from your Rails application root directory:

```bash
bundle exec route_guard
```

### Commands

*   `check` (default): Run full inspection rules on routes.
*   `stats`: Generate key route complexity metrics and statistics.
*   `doctor`: Run in strict mode (fails on warnings/errors). Perfect for CI pipelines.
*   `json`: Generate a machine-readable JSON report.
*   `html`: Generate a premium interactive HTML report dashboard.

### CLI Options

| Option | Type | Description |
| :--- | :--- | :--- |
| `--strict` | Boolean | Treat all warnings as errors. |
| `--format` | String | Output format (`terminal`, `json`, `html`, `ci`). |
| `--only` | Array | Only run specific inspections (e.g. `duplicate_routes`). |
| `--except` | Array | Exclude specific inspections from running. |
| `--fail-on-warning`| Boolean | Exit with status code `1` if warnings are found. |
| `--output` | String | Path to write the JSON/HTML output. |
| `--verbose` | Boolean | Display detailed debug information. |

#### Examples

**Generate a self-contained HTML dashboard report:**
```bash
bundle exec route_guard html --output=coverage/route_guard_report.html
```

**Run only duplicate route checking:**
```bash
bundle exec route_guard check --only duplicate_routes
```

**Strict checking in CI, failing on warnings:**
```bash
bundle exec route_guard check --fail-on-warning
```

---

## 3. Rails / Rake Integration

RouteGuard automatically registers Rake tasks when loaded in your Rails application.

### Available Tasks

*   **`bundle exec rails route_guard`** (or `bundle exec rails routes:lint`): Analyzes your routes and prints findings to your terminal.
*   **`bundle exec rails routes:doctor`**: Runs strict verification. Exits with non-zero code if any issue (warning or error) is detected. Ideal for Git pre-commit hooks or CI steps.
