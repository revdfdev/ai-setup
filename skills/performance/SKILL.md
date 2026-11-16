---
name: performance
disable-model-invocation: true
description: Slow endpoints, timeouts, bulk operations, high CPU/memory, or scaling to production tenant sizes. Measure, fix the access pattern, prove the gain.
---

# Performance

Production tenants have 10,000s of employees; a local tenant of ~70 hides N+1.

1. **Measure first.** Find where time goes (app, DB, network, serialization, external calls): latency, query count and duration, external call count, memory, batch and payload size. No optimization before a likely bottleneck is shown.
2. **Find N+1, including service calls.** A DB, repository or service call inside a loop over employees/rows must be justified. Replace with: collect IDs → one bounded batch fetch per dependency (`$in`, multi-ID API) → lookup maps → process in memory. Never make N+1 faster with goroutines.
3. **Bound everything.** Batches have a measured size, never one unbounded query. Concurrency only after the access pattern is fixed, CPU-bound work only, with a bounded worker pool, context and error propagation; count DB pressure as workers × ops × instances. Writes use bulk APIs (`BulkWrite`), keeping per-record errors where the business needs them.
4. **Query shape.** Filter, sort and paginate in the database on indexed fields; project only needed fields. Hoist invariant work (parsing formulas, building maps) out of loops; replace nested search with maps.
5. **Not fixes:** raising a timeout for `context deadline exceeded`, caching instead of fixing a query, `useMemo` everywhere. Cache only with a stated staleness, invalidation and tenant isolation.
6. **Correctness unchanged:** ordering, filtering, tenant isolation, missing-record and error behavior, results.

**Report.** Before: problem, bottleneck, access pattern (e.g. `1 + 3N` calls), proposed change, risks. After: query count, latency, memory before vs after, the test that pins the count so it can't grow with N, remaining bottlenecks. No claimed gain without a measurement.
