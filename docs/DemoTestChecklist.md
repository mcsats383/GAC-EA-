# GAC EA Demo Test Checklist

## Purpose

This checklist is used to validate whether GAC EA is ready to run on a demo account under controlled conditions. A demo test is a validation step, not proof of live profitability.

## Stage 0 — Source lock

Before demo execution begins, confirm:

- [ ] The source file is the exact approved version.
- [ ] Commit SHA is recorded.
- [ ] Specific inputs are frozen.
- [ ] No parameter changes are allowed during the demo period without written approval.
- [ ] The testing account type, symbol, and broker are recorded.

## Stage 1 — Compile and smoke test

- [ ] MetaEditor compile has zero errors.
- [ ] No unexplained warnings remain.
- [ ] Indicator handles initialize correctly.
- [ ] Indicator handles release correctly on deinitialization.
- [ ] EA loads on XAUUSD or the target symbol.
- [ ] Expert log shows initialization success.
- [ ] Terminal trading permission is checked.
- [ ] Spread filter blocks high-spread conditions.
- [ ] Session filter blocks off-hours entries.
- [ ] Daily loss guard blocks further entries.
- [ ] Position cap is enforced.
- [ ] Stop level validation rejects invalid SL/TP.
- [ ] Failed order attempts log retcodes and descriptions.

## Stage 2 — Symbol and broker checks

- [ ] Symbol is correctly selected.
- [ ] Trade mode is allowed.
- [ ] Point value and digits are verified.
- [ ] Lot step and volume limits are checked.
- [ ] Stop level is valid for the broker.
- [ ] Commission, swap, and spread are noted.
- [ ] Execution policy and slippage rules are stated.

## Stage 3 — Demo execution setup

Use conservative initial settings.

Recommended starting values:

- Risk per trade: 0.25% to 0.50%
- Max positions: 1
- Max daily loss: 2%
- Max equity drawdown: 10%
- Demo duration: at least 2 weeks, preferably 4–6 weeks

Also confirm:

- [ ] Magic number is unique to this EA.
- [ ] The chart is attached to the intended symbol.
- [ ] The EA is running on a demo account only.
- [ ] The account balance and equity are recorded.
- [ ] The user is aware that the demo is a validation stage, not a live strategy approval.

## Stage 4 — Daily monitoring

During the demo period, log the following daily:

- [ ] Daily P/L
- [ ] Equity curve
- [ ] Maximum drawdown
- [ ] Daily loss limit status
- [ ] Number of open positions
- [ ] Spread average
- [ ] Slippage average
- [ ] Execution latency if available
- [ ] Number of entries and exits
- [ ] Trade reason each time an order opens

## Stage 5 — Trade journal requirements

Every order must be logged with:

- [ ] timestamp
- [ ] symbol
- [ ] direction (buy/sell)
- [ ] entry price
- [ ] stop loss
- [ ] take profit
- [ ] lot size
- [ ] spread at entry
- [ ] slippage
- [ ] signal score or reason summary
- [ ] account balance and equity
- [ ] result (win/loss/partial)

## Stage 6 — Demo pass/fail gates

### Pass only if all are true

- [ ] No unexplained runtime errors or repeated order failures
- [ ] Trades respect spread, session, and risk filters
- [ ] Daily loss cap is not breached repeatedly
- [ ] Drawdown remains inside the defined limit
- [ ] No severe sequence of losses from a single input set
- [ ] Strategy behavior is stable across multiple sessions
- [ ] Execution quality matches tester assumptions
- [ ] No obvious overtrading or repeated invalid entries
- [ ] Results remain stable for the required test duration

### Fail conditions

- [ ] Frequent invalid stop placement
- [ ] A huge drawdown in a short period
- [ ] Repeated failed entries due to spread or internal logic
- [ ] Overly frequent signal generation without confirmation
- [ ] Large differences between expected and actual execution results
- [ ] Unstable results across normal market conditions

## Stage 7 — Decision rule

Do not move from demo to live without all of the following:

- [ ] Stable execution behavior over the demo period
- [ ] Acceptable risk and drawdown under realistic conditions
- [ ] No unexplained logic errors
- [ ] A documented and frozen parameter set
- [ ] A clear plan for live risk limits and emergency stop conditions

## Final note

A demo pass is not a profit guarantee. A demo account is a validation environment only. The EA still requires disciplined risk control and independent review before any real-money use.
