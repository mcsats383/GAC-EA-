# GAC EA Backtest and Validation Plan

## Purpose

This plan defines how to test GAC EA without confusing curve-fitted historical results with evidence of robust performance. A passing test is not a profit guarantee.

## 0. Test environment record

Record these values for every run:

- MT5 build and EA commit SHA
- Broker, server, account currency, leverage, and account type
- Exact symbol name and contract specification
- Timeframe and timezone (EA uses broker server time)
- Tester model and tick source
- Commission, swap, spread, slippage, and execution mode
- Starting balance and date range
- All input parameters and optimization ranges

Do not compare runs when any of these material assumptions change without noting it.

## 1. Compile and smoke test

1. Compile `Experts/GAC_EA/GAC_EA.mq5` with zero errors.
2. Run a short visual test on XAUUSD demo data.
3. Confirm indicator handles initialize and are released on removal.
4. Confirm no entry occurs when terminal trading is disabled, spread is too high, the session is blocked, or daily loss is reached.
5. Confirm only closed-candle data is used for signals.
6. Confirm SL/TP direction, broker stop level, volume step, magic number, and symbol filtering.
7. Force failed-order conditions and verify Journal error logging.
8. Verify trailing-stop modification is valid and cannot move a stop backwards.

## 2. Baseline historical test

Use MT5 Strategy Tester with **Every tick based on real ticks** where available. Use at least three years of data covering trend, range, high-volatility, and low-volatility periods.

Suggested split:

- Development / in-sample: 60%
- Validation / out-of-sample: 20%
- Final holdout: 20%, never used for parameter selection

Do not optimize on the validation or holdout periods.

Record:

- Net profit and return on initial balance
- Profit factor and expectancy per trade
- Trade count and average trade
- Win rate and payoff ratio
- Maximum equity drawdown (absolute and percentage)
- Recovery factor and Sharpe-like return/volatility measure
- Maximum consecutive losses
- Monthly and yearly returns
- Long/short and session breakdown
- Spread, commission, swap, and slippage impact
- Rejected signals and blocked trades where logging is available

## 3. Parameter robustness

Use a coarse grid, not a highly precise search. Test nearby parameter neighborhoods:

- Fast EMA: 15, 20, 25
- Slow EMA: 40, 50, 60
- RSI upper/lower: 53/47, 55/45, 57/43
- SL ATR multiplier: 1.25, 1.5, 1.75
- TP ATR multiplier: 2.0, 2.5, 3.0
- Minimum signal score: 5, 6, 7
- Risk per trade: 0.25%, 0.50%, 1.00%

A robust region should contain several nearby profitable or acceptable configurations. Reject a result that works only at one precise parameter combination.

## 4. Stress tests

Repeat the selected configuration with:

- Spread increased by 25%, 50%, and 100%
- Slippage shock
- Commission and swap increased
- Delayed execution assumptions
- Missing ticks or sparse data where applicable
- Different broker symbol suffixes and contract specifications
- High-volatility news periods and gap/reopen periods
- Starting dates shifted by one month

Reject configurations that fail under small, plausible cost increases or depend on a single exceptional trade.

## 5. Walk-forward test

Use rolling windows, for example:

1. Optimize only on months 1–12; test months 13–15.
2. Move forward three months and repeat.
3. Aggregate only the unseen test windows.

Store each window's parameters before looking at its test result. Report aggregate and per-window results, including drawdown and trade count.

## 6. Demo forward gate

Run the frozen EA and frozen parameters on a demo account for 2–6 weeks or at least 100 representative trades, whichever takes longer. Do not change parameters based on individual trades.

Log:

- Signal time and reason/score
- Requested versus filled price
- Spread and slippage
- Retcode and execution latency
- SL/TP modifications
- Equity, drawdown, and daily loss state
- Differences between tester and live-demo behavior

## 7. Decision gates

Do not move to live testing unless all gates pass:

- Zero compile errors and no unexplained runtime errors
- No look-ahead or data leakage found
- Out-of-sample expectancy remains positive or meets a pre-declared conservative threshold
- Drawdown remains within the pre-declared risk budget
- Results survive plausible cost and spread shocks
- No single day, month, or trade dominates the result
- Demo execution matches the tester assumptions

Use a very small pilot risk only after written approval and an emergency disable procedure. Never increase risk simply because a backtest is profitable.

## 8. Result template

```text
EA commit:
Broker/server:
Symbol/specification:
Timeframe:
Date range:
Tester model:
Initial balance:
Inputs:
Commission/swap/spread/slippage:
Trades:
Net profit / return:
Profit factor:
Expectancy:
Max equity drawdown:
Max consecutive losses:
OOS result:
Stress-test result:
Walk-forward result:
Demo result:
Decision: reject / iterate / demo / limited pilot
Notes:
```
