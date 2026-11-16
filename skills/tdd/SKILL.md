---
name: tdd
disable-model-invocation: true
description: A backend change or bug fix that alters behaviour, including small ones. Test first, seen failing, then the smallest change that passes.
---

# TDD

1. **Scenarios first.** List them like a tester and show the list: happy path, boundaries, empty/missing data, each role, state changes, double submit, persisted record read back; include negative cases.
2. **Red.** Write the test for the first scenario and run it. It must fail for the expected reason, not a compile error or broken fixture. Paste the failing line.
3. **Green.** Smallest production change that passes; no extra features or cleanup.
4. **Refactor** only with tests green.
5. **Regression.** Run the package's tests and anything that consumes what you changed.

- A test proves behaviour: input → observable result. "Mock A called mock B" is weak unless the call is the contract.
- Control time, randomness, network and filesystem.
- **Never change an expected value to make a test pass** unless the requirement changed and the user said so; a disagreeing test is a finding to report.
- Before changing a shared contract (API response, event payload, DTO, DB field), find its real consumers.
- Exclude a pre-existing failure only after checking it fails without your change.

Proof line: test name and result, e.g. `go test ./internal/processing/service -run TestRegisterMissingSummary → PASS`.
