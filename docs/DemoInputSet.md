# GAC EA Prototype Demo Input Set

## Purpose

This is a conservative starting profile for the current source. It is not optimized and is not a recommendation for live trading.

```text
RiskPercent        = 0.25
MaxDailyLoss       = 2.0
MaxPositions       = 1
MagicNumber        = unique per chart
SlippagePoints     = 30

UseTrendFilter     = true
UseVolumeFilter    = true
UseSpreadFilter    = true
UseSessionFilter   = true
UseNewBarOnly      = true
RequireBreakout    = true

FastEMA            = 20
SlowEMA            = 50
ATRPeriod          = 14
RSIPeriod           = 14
RSIUpper           = 55.0
RSILower           = 45.0
SL_ATR_Multiplier  = 1.5
TP_ATR_Multiplier  = 2.5

MaxSpreadPrice     = broker-verified
MinATRPrice        = 0.0
MaxATRPrice        = 0.0
MinVolumeRatio     = 1.05
MinBodyATR         = 0.20
StartHour          = 7
EndHour            = 22
BreakoutLookback   = 20
BreakoutATRMinimum = 0.25
MinimumSignalScore = 6
```

## How to set `MaxSpreadPrice`

Do not use a universal value for every broker. Read the symbol's live spread and contract specification, then select a limit that is documented before the test starts. Record whether the value is in price units, not points.

## Why this profile is conservative

- Risk is reduced to 0.25% per trade.
- Only one GAC position is allowed.
- Daily loss is capped at 2% for entry blocking.
- Trend, volume, session, breakout, and new-bar filters remain enabled.
- No parameter is tuned to produce a desired demo result.

## Important limitation

The current source exposes `MaxDailyLoss` but does not yet expose a portfolio-wide maximum equity drawdown, maximum consecutive-loss lockout, total notional exposure cap, or trailing-stop input. Those controls must not be claimed as active until implemented and verified in the EA source.

## Change-control rule

Use one frozen input set for the entire demo window. If a broker-specific change is necessary, stop the run, record the reason, create a new test ID, and restart the measurement period.
