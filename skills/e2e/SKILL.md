---
name: e2e
disable-model-invocation: true
description: Write, update or debug a Playwright user journey. Use to add E2E proof for a feature or to find whether a failing journey is a UI, API, data, environment or test-setup problem.
---

# E2E

## Writing
Use E2E only to prove an end-user journey across the real UI and required
services; keep most coverage at unit and integration level. Tests create their
own state, never rely on run order, and use visible user actions and
assertions, not implementation selectors. Read
`references/playwright-policy.md` before configuring a project.

## Debugging a failure
Start from the failing user-visible step and keep the evidence: trace,
screenshot, request/response, console output, test data. Decide whether it is
app behavior, test isolation, environment, fixture state or a flaky
interaction, and reproduce with the narrowest Playwright project. Never patch
the test to hide an app failure or retry until green; app defects go to
`bug-triage`. Change the test only when its assumption is disproven.
