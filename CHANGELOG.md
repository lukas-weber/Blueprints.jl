# Changelog

## [Unreleased]

### Fixed
- Optimized the topological sorting algorithm making scheduling of large blueprints much faster

## 0.2.0 - 2025-08-15

### Added

- The `MapPolicy` now takes an additional argument for the maximum concurrency. This feature is helpful in memory-bound situations or long-running calculations that should write to caches intermittently.
- `Blueprints.is_cached` allows to check if the caches inside of a blueprint are completely filled.

### Fixed
- The construction logic will now free memory for objects that it no longer needs.

### Changed
- When printing a `Blueprint`, its stages are now sorted.
- We now use a Coffman-Graham topological sorting algorithm for the directed acyclic graph, changing the scheduling order, hopefully in a good way.
