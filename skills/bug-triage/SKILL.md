---
name: bug-triage
disable-model-invocation: true
description: A bug report, regression, wrong value, failing request or unexpected behaviour. Finds where behaviour first goes wrong, proves it with a failing test, then fixes the cause.
---

# Bug triage

Don't start by editing suspicious code. Find where correct becomes incorrect.

1. **Symptom.** Observed vs expected, with the exact input, state and environment. "Payroll broken" is not a symptom; "employee E1, June 2026: Review returns 400 'monthly summary not found' while the register shows the row Ready" is.
2. **Reproduce** with a request, test, query or log line. Can't? Say so and stop guessing.
3. **First divergence.** Walk back from the symptom (UI → API → service → data) to the earliest wrong value; that is where the cause lives. Check swallowed errors and defaults. Label it **CONFIRMED** (seen in code and reproduced), **SUPPORTED** (evidence, not reproduced) or **SPECULATIVE**. Never present speculative as the cause.
4. **Failing test** through behaviour, at the lowest layer that reproduces it (unit, integration, or E2E only for a real journey); see it fail for the expected reason.
5. **Fix the cause**, smallest change; no compensating adjustments downstream. Run the related tests.
6. **Report, five lines:** Symptom / Cause (label) / Fix / Proof (test name + result) / Not verified.

If step 3 never reaches CONFIRMED, report the strongest hypothesis, its evidence and what is unknown, then ask before fixing. A UI failure that may be cross-layer: use `e2e` first.
