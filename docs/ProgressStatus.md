# GAC EA Progress Status

## Current state

GAC EA is currently at the **controlled demo preparation** stage. The project is not approved for live trading and makes no claim of guaranteed profitability.

## Completed

- MT5 EA foundation for XAUUSD
- EMA trend filter
- RSI confirmation
- ATR-based SL/TP
- Breakout and tick-volume filters
- Spread and broker-server session filters
- Closed-candle and new-bar execution logic
- Daily realized plus floating loss entry protection
- Position count limit
- Lot sizing through `OrderCalcProfit`
- Broker stop-level validation
- Backtest and walk-forward plan
- Demo readiness assessment
- Demo test checklist
- Conservative demo input set
- Four-week daily demo plan
- Logic readiness review

## Waiting for external testing

The repository does not have an MT5 runtime or MetaEditor compiler available through GitHub. The following must be performed in MetaTrader 5 before the result can be marked as passed:

1. Compile `Experts/GAC_EA/GAC_EA.mq5` in MetaEditor.
2. Record errors and warnings, if any.
3. Run a visual smoke test.
4. Verify broker symbol properties and set `MaxSpreadPrice`.
5. Run Strategy Tester with realistic spread, commission, swap, and slippage.
6. Run out-of-sample and stress tests.
7. Start controlled demo observation only after the earlier gates pass.

## Frozen prototype demo profile

```text
RiskPercent        = 0.25
MaxDailyLoss       = 2.0
MaxPositions       = 1
SlippagePoints     = 30
UseTrendFilter     = true
UseVolumeFilter    = true
UseSpreadFilter    = true
UseSessionFilter   = true
UseNewBarOnly      = true
FastEMA            = 20
SlowEMA            = 50
ATRPeriod          = 14
RSIPeriod          = 14
RSIUpper           = 55.0
RSILower           = 45.0
SL_ATR_Multiplier  = 1.5
TP_ATR_Multiplier  = 2.5
StartHour          = 7
EndHour            = 22
BreakoutLookback   = 20
BreakoutATRMinimum = 0.25
```

`MaxSpreadPrice` is intentionally broker-specific and must be set after checking the target broker's symbol specification and observed spread.

## Important limitations

The current source version still requires verification for the following planned controls:

- max equity drawdown lock
- consecutive-loss lockout
- portfolio exposure cap
- trailing stop
- margin pre-check
- structured signal logging

These controls must not be represented as active until implemented in the EA source and verified by compilation and testing.

## Test handoff

When test results are available, attach:

- MetaEditor compile output
- MT5 build and broker/server
- symbol specification
- complete `.set` inputs
- Strategy Tester report
- Experts and Journal logs
- demo trade history
- observed spread and slippage

Decision remains: **ready to wait for external compile and test results; not approved for live trading**.
