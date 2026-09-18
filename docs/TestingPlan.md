# Testing Plan

## Compile and smoke test

- Compile `Experts/GAC_EA/GAC_EA.mq5` with no errors.
- Test symbols with different digits, volume steps, minimum stops, and suffixes.
- Confirm spread, session, daily-loss, trading-mode, and permission checks block entries correctly.
- Confirm SL/TP direction, lot normalization, magic number, and failed-order logging.

## Historical testing

Use MT5 Strategy Tester with real ticks where available. Include commission, swap, spread, and slippage assumptions. Record net return, profit factor, maximum equity drawdown, recovery factor, trade count, expectancy, consecutive losses, exposure by session, and yearly/regime results.

Do not optimize and evaluate on the same period. Keep a locked out-of-sample period and reject configurations that depend on one short period or highly precise parameters.

## Forward-test gates

1. Stable backtest across multiple years and nearby parameter values.
2. Positive out-of-sample expectancy without materially higher drawdown.
3. Demo forward test for 2–6 weeks with execution and spread logs.
4. Small-risk live pilot only after the earlier gates pass, with an emergency stop.

A test pass is not a profit guarantee.
