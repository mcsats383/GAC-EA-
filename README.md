# GAC-EA-

GAC-EA is a **research and validation** MT5 Expert Advisor foundation for gold and other volatile instruments. It is designed for disciplined experimentation; it does not promise profit, market outperformance, or suitability for live trading.

## Current implementation

- Closed-candle EMA trend and RSI confirmation
- ATR-based stop loss and take profit
- New-bar, session, spread, body-size, volume, and breakout filters
- Risk-based position sizing using `OrderCalcProfit`
- Daily loss and account-equity drawdown entry guards
- Consecutive-loss lockout, position cap, exposure cap, and margin-level checks
- Broker-aware stop validation and volume-step normalization
- Break-even and ATR trailing-stop management that never intentionally moves a stop backward
- Structured signal and execution logs with trade retcodes

## Source and testing

- `Experts/GAC_EA/GAC_EA.mq5` — MT5 Expert Advisor source
- `docs/BacktestPlan.md` — realistic-cost backtest and walk-forward protocol
- `docs/TestingPlan.md` — compile, smoke, historical, and forward-test gates
- `docs/DemoInputSet.md` — conservative starting inputs
- `docs/DemoTestChecklist.md` — controlled demo checklist

Compile the exact commit in MetaEditor, then use MT5 Strategy Tester with real ticks where available. Record broker, symbol specification, timeframe, costs, inputs, and the commit SHA for every run. Keep development, out-of-sample, and final holdout periods separate.

## Conservative starting profile

Use the values in `docs/DemoInputSet.md` as a starting point only. Freeze the parameters for the test window. Run a demo account for at least 2–6 weeks or 100 representative trades, with no live-money deployment until compile, smoke, out-of-sample, stress, walk-forward, and demo gates pass.

## Safety

Leveraged trading can cause rapid loss of capital. Do not use this EA with money you cannot afford to lose. Never place credentials, broker passwords, API keys, or account exports in the repository. A backtest or demo result is not evidence of future live performance.
