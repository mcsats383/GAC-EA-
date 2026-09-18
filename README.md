# GAC-EA-

GAC-EA is an MT5 Expert Advisor research foundation for gold and other volatile instruments. It is designed to be validated systematically; it does **not** promise profit.

## Current implementation

- EMA trend filter and RSI momentum confirmation
- ATR-based stop-loss and take-profit
- Position sizing based on `OrderCalcProfit` and broker constraints
- Maximum open positions by symbol and magic number
- Maximum spread and broker session filters
- Optional tick-volume confirmation
- Daily realized plus floating loss protection
- New-bar execution and closed-candle indicator readings
- Breakout confirmation using a configurable lookback range
- Stop-level validation and trade-result logging

## Installation

1. Open MetaEditor in MT5.
2. Copy `Experts/GAC_EA/GAC_EA.mq5` to `MQL5/Experts/GAC_EA/`.
3. Compile the file.
4. Attach it to a demo XAUUSD chart first.
5. Check the Experts log, spread, stop-level rules, and execution results.

## Validation before live use

Backtest profitability is not proof of future performance. Use real-tick testing where available, realistic commission/spread/slippage, an untouched out-of-sample period, walk-forward testing, and 2–6 weeks of demo forward testing. Start with 0.25%–1.0% risk per trade while validating.

## Known limitations

- No economic-news calendar filter yet.
- Daily loss protection is scoped to the current symbol and magic number.
- Tick volume is only a proxy for activity.
- This repository does not claim independently verified profitability.

## Risk warning

Leveraged gold, crypto, CFDs, and derivatives can cause rapid loss of capital. Use a demo account and independently verify every result before considering real-money use.
