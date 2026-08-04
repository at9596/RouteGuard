# RouteGuard: Gem Publishing Guide

This guide details how to build, package, and publish the **RouteGuard** gem to the RubyGems community.

---

## 1. Preparing for Release

Before building and publishing, ensure that:

1.  All tests pass:
    ```bash
    bundle exec rspec
    ```
2.  Your version in `lib/route_guard/version.rb` is bumped according to Semantic Versioning (SemVer) rules:
    ```ruby
    module RouteGuard
      VERSION = "0.1.0" # Major.Minor.Patch
    end
    ```
3.  The metadata in `route_guard.gemspec` (homepage, authors, email, etc.) is correct.

---

## 2. Building the Gem

To package the gem code into a distributable `.gem` file, run the `gem build` command from the root of the project:

```bash
gem build route_guard.gemspec
```

This generates a file named `route_guard-0.1.0.gem` (matching your current version) in the root folder.

---

## 3. Authentication with RubyGems

To publish a gem, you need an account on [RubyGems.org](https://rubygems.org/).

Once registered, sign in via your terminal using:

```bash
gem signin
```

Enter your RubyGems email and password when prompted. This securely stores your API key locally in `~/.gem/credentials`.

---

## 4. Publishing to RubyGems

Publish the built gem package using the `gem push` command:

```bash
gem push route_guard-0.1.0.gem
```

Once pushed, your gem will be immediately indexable, and developers around the world can install it via:

```bash
gem install route_guard
```

---

## 5. Version Control Best Practices

After publishing a release:

1.  **Tag the release** in git:
    ```bash
    git tag -a v0.1.0 -m "Release version 0.1.0"
    git push origin v0.1.0
    ```
2.  **Document changes** in a `CHANGELOG.md` file so developers know what changed.
