# GAC EA Logic Readiness Review

## Overall assessment

**Status: conditional demo readiness.** The EA has enough structure for controlled demo observation after a real MetaEditor compile and smoke test, but it is not ready for live money and does not yet have all risk controls previously discussed.

## What the current source actually implements

- EMA trend direction
- RSI threshold confirmation
- ATR-based SL and TP
- Closed-candle indicator reads
- New-bar gating when enabled
- Optional volume confirmation
- Session and spread filters
- Breakout confirmation excluding the signal candle from the lookback range
- Daily realized plus floating P/L entry block scoped to current symbol and MagicNumber
- Position count scoped to current symbol and MagicNumber
- Lot sizing via `OrderCalcProfit`
- Stop-level validation

## Material gaps

1. The current source is version `1.40` and does not contain the later claimed exposure cap, equity drawdown cap, consecutive-loss lockout, or trailing-stop manager. Documentation must not describe those controls as active.
2. `MaxDailyLoss` blocks new entries but does not close existing positions. Define this behavior explicitly before demo.
3. Daily loss is based on current account balance and current symbol/MagicNumber, not a portfolio-wide starting-day equity baseline.
4. The source has no economic-news filter and cannot be treated as news-safe.
5. `MaxSpreadPrice` is broker-specific and must be verified in price units.
6. Volume is tick volume, not centralized exchange volume.
7. The signal score can be inflated because volume and breakout confirmations add points to both directions; the final directional conditions reduce some risk, but this should be reviewed before interpreting score quality.
8. `NormalizeLot` uses two decimal places, which may be insufficient for symbols whose volume step requires more precision.
9. There is no explicit margin pre-check or portfolio exposure calculation.
10. There is no structured signal reason log, making post-trade attribution difficult.

## Required before demo

- Compile the exact source in MetaEditor with zero errors.
- Verify broker symbol properties and set a documented spread limit.
- Run a visual smoke test with no unexplained runtime errors.
- Validate lot sizing and SL/TP on the target broker.
- Use the conservative input profile in `docs/DemoInputSet.md`.
- Follow `docs/DemoDailyPlan.md` and freeze parameters.

## Recommended next code changes

1. Add explicit risk controls: equity drawdown, consecutive losses, margin check, and portfolio exposure.
2. Add a trailing-stop or break-even module only after validating stop-modification rules.
3. Replace two-decimal lot normalization with volume-step precision derived from the broker.
4. Add structured `PrintFormat` logs for signal score, filter decisions, spread, ATR, lot, and retcode.
5. Add a configurable news/event blackout only if a reliable data source is available.
6. Rework score accounting so each confirmation contributes only to its matching direction.
7. Add a daily starting-equity snapshot or a documented account-wide daily loss model.

## Decision

The EA may proceed to **controlled demo observation** only after compile and smoke-test gates pass. It is not approved for live trading, and demo performance must not be presented as proof of future profitability.
