# feedback/

Output directory for standalone Ralph testing skills.

This directory is written to when running `/test-spec`, `/browser-test`, or
`/prove-requirements` **outside** of a full `/ralph-loop` run.

## Structure (populated at runtime)

```
feedback/
├── <spec-id>/
│   ├── test-results/       # /test-spec output per requirement
│   ├── browser-tests/      # /browser-test HTML reports
│   └── proof-report.md     # /prove-requirements validation report
└── visual-regression/      # /browser-test screenshot diffs
```

## Note

When running `/ralph-loop`, test results and artifacts go to
`ralph/.ralph/artifacts/` instead and are archived to `ralph/archive/`
on completion. This directory will remain empty during a loop run.
