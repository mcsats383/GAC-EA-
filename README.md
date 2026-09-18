# GAC-EA-

GAC-EA is a research MT5 Expert Advisor for gold and other volatile instruments. It is a foundation build intended for systematic validation, not a guarantee of profit.

## Current status

This project is in a research and validation state. It includes:

- EMA trend logic and RSI momentum filtering
- ATR-based SL/TP logic
- Basic risk gating for daily loss, drawdown, exposure, and consecutive losses
- Position count, spread, and session filtering
- Trailing stop logic for open profitable trades
- A strict signal-triage model that requires multiple confirmations before entry

## Important warning

This EA does not claim verified profitability. It is not a money-making system by default. Real-world performance depends on broker conditions, symbol specs, trading session, slippage, execution quality, and market regime.

## Files in this repository

- `Experts/GAC_EA/GAC_EA.mq5` — MT5 EA source
- `docs/BacktestPlan.md` — backtest, walk-forward, stress, and validation plan
- `docs/TestingPlan.md` — earlier validation notes
- `README.md` — project overview and risk notes

## Recommended workflow

1. Compile the EA in MetaEditor.
2. Run the Strategy Tester with realistic costs and real-tick data where possible.
3. Validate on out-of-sample data.
4. Run a demo forward test for at least 2–6 weeks.
5. Only then consider a very small pilot with strict loss controls.

## Risk warning

Trading gold, crypto, CFDs, and other leveraged instruments can cause rapid loss of capital. Use a demo account, verify results independently, and never assume a backtest is predictive of live performance.

## Validation requirement before live use

The EA should be considered only after the following have passed:

- compile without errors
- backtest with realistic assumptions
- out-of-sample validation
- stress testing
- walk-forward examination
- demo forward testing with stable execution

If those gates are not passed, this project remains a research prototype and not a live trading system.
