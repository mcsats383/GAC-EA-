# GAC EA Demo Readiness Assessment

## Status

This project is not yet ready for full Demo testing in its current state. It has a valid research foundation, but it still needs a final compile check, a stress-tested baseline, and a confirmed risk-safe source version before it can be considered a Demo-ready EA.

## Summary

The repository currently contains a viable MT5 EA foundation with:

- EMA trend logic
- RSI confirmation
- ATR-based SL/TP
- spread and session filters
- daily loss protection
- position cap
- risk logic and signal triage

However, the project still needs to satisfy all of the following before Demo launch is appropriate:

1. The latest risk-safe source version must be clearly marked and committed.
2. The EA must compile successfully in MetaEditor with zero errors.
3. A smoke test must confirm correct execution and entry gating.
4. Strategy Tester results must be checked with realistic costs and real-tick data.
5. Out-of-sample and stress testing must be passed.
6. The demo account must use a very low risk budget.

## Demo readiness checklist

### Must pass before demo launch

- [ ] Current EA source is the newest approved version
- [ ] MetaEditor compile passes with zero errors
- [ ] No unexplained warnings or runtime exceptions
- [ ] SL/TP distance respects broker stop level
- [ ] Lot size matches broker contract specification
- [ ] Spread filter blocks poor entries
- [ ] Session filter blocks off-hours entries
- [ ] Daily loss stop works as intended
- [ ] Position cap is enforced
- [ ] Trailing stop logic does not cause invalid stop modifications
- [ ] Trade log captures order reason, price, spread, slippage, and retcode
- [ ] Backtest uses realistic assumptions
- [ ] Out-of-sample validation is acceptable
- [ ] Stress testing is acceptable
- [ ] Demo risk is set conservatively

### Recommended demo settings

- Risk per trade: 0.25% to 0.50%
- Max positions: 1
- Max daily loss: 2%
- Max drawdown: 10%
- Demo duration: at least 2–6 weeks or 100 trades
- No parameter changes during the demo period unless explicitly approved

## Risk statement

This EA is still a research and validation project. It is not a live-proven system and should not be treated as a guaranteed profit engine. Demo testing is a gate, not a promise of future profitability.

## Decision

Currently: not ready for full Demo testing.

Required next actions:

1. Lock the approved source version.
2. Compile successfully in MetaEditor.
3. Run smoke test and strategy tester baseline.
4. Pass out-of-sample and stress tests.
5. Then run a limited low-risk demo.
