//+------------------------------------------------------------------+
//| GAC EA - Gold Adaptive Control                                   |
//| MT5 / XAUUSD - strict signal triage research build               |
//+------------------------------------------------------------------+
#property strict
#property version "1.40"

#include <Trade/Trade.mqh>
CTrade trade;

input double RiskPercent          = 1.0;
input double MaxDailyLoss         = 5.0;
input int    MaxPositions         = 2;
input ulong  MagicNumber          = 260824;
input int    SlippagePoints       = 30;

input bool   UseTrendFilter       = true;
input bool   UseVolumeFilter      = true;
input bool   UseSpreadFilter      = true;
input bool   UseSessionFilter     = true;
input bool   UseNewBarOnly        = true;
input bool   RequireBreakout      = true;

input int    FastEMA              = 20;
input int    SlowEMA              = 50;
input int    ATRPeriod            = 14;
input int    RSIPeriod            = 14;
input double RSIUpper             = 55.0;
input double RSILower             = 45.0;
input double SL_ATR_Multiplier    = 1.5;
input double TP_ATR_Multiplier    = 2.5;
input double MaxSpreadPrice       = 1.50;
input double MinATRPrice          = 0.0;
input double MaxATRPrice          = 0.0;
input double MinVolumeRatio       = 1.05;
input double MinBodyATR           = 0.20;
input int    StartHour             = 7;
input int    EndHour               = 22;
input int    BreakoutLookback      = 20;
input double BreakoutATRMinimum    = 0.25;
input int    MinimumSignalScore    = 6;

int hFastEMA = INVALID_HANDLE;
int hSlowEMA = INVALID_HANDLE;
int hATR     = INVALID_HANDLE;
int hRSI     = INVALID_HANDLE;
datetime lastBarTime = 0;
double fastEMA = 0.0, slowEMA = 0.0, atrValue = 0.0, rsiValue = 50.0;

int OnInit()
{
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(SlippagePoints);
   trade.SetTypeFillingBySymbol(_Symbol);

   hFastEMA = iMA(_Symbol, PERIOD_CURRENT, FastEMA, 0, MODE_EMA, PRICE_CLOSE);
   hSlowEMA = iMA(_Symbol, PERIOD_CURRENT, SlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   hATR = iATR(_Symbol, PERIOD_CURRENT, ATRPeriod);
   hRSI = iRSI(_Symbol, PERIOD_CURRENT, RSIPeriod, PRICE_CLOSE);

   if(hFastEMA == INVALID_HANDLE || hSlowEMA == INVALID_HANDLE ||
      hATR == INVALID_HANDLE || hRSI == INVALID_HANDLE)
      return INIT_FAILED;

   if(FastEMA < 2 || FastEMA >= SlowEMA || ATRPeriod < 2 || RSIPeriod < 2 ||
      RiskPercent <= 0.0 || MaxDailyLoss <= 0.0 || SL_ATR_Multiplier <= 0.0 ||
      TP_ATR_Multiplier <= 0.0 || MinimumSignalScore < 1 || MinimumSignalScore > 8 ||
      BreakoutLookback < 2 || MinVolumeRatio < 0.0 || MinBodyATR < 0.0)
      return INIT_PARAMETERS_INCORRECT;

   Print("GAC EA strict signal triage initialized on ", _Symbol);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   if(hFastEMA != INVALID_HANDLE) IndicatorRelease(hFastEMA);
   if(hSlowEMA != INVALID_HANDLE) IndicatorRelease(hSlowEMA);
   if(hATR != INVALID_HANDLE) IndicatorRelease(hATR);
   if(hRSI != INVALID_HANDLE) IndicatorRelease(hRSI);
}

void OnTick()
{
   if(UseNewBarOnly && !IsNewBar()) return;
   if(!IsTradingAllowed() || DailyLossLimitReached()) return;
   if(!UpdateIndicators() || CountGACPositions() >= MaxPositions) return;

   int signal = GetSignal();
   if(signal > 0) OpenBuy();
   else if(signal < 0) OpenSell();
}

bool IsNewBar()
{
   datetime current = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(current == 0 || current == lastBarTime) return false;
   lastBarTime = current;
   return true;
}

bool UpdateIndicators()
{
   double fast[1], slow[1], atr[1], rsi[1];
   if(CopyBuffer(hFastEMA, 0, 1, 1, fast) != 1) return false;
   if(CopyBuffer(hSlowEMA, 0, 1, 1, slow) != 1) return false;
   if(CopyBuffer(hATR, 0, 1, 1, atr) != 1) return false;
   if(CopyBuffer(hRSI, 0, 1, 1, rsi) != 1) return false;
   fastEMA = fast[0]; slowEMA = slow[0]; atrValue = atr[0]; rsiValue = rsi[0];
   return fastEMA > 0.0 && slowEMA > 0.0 && atrValue > 0.0;
}

// Triage: reject poor regime first, then require a minimum number of
// independent confirmations. All values use closed candles.
int GetSignal()
{
   if(UseSessionFilter && !IsSessionAllowed()) return 0;
   if(UseSpreadFilter && GetSpreadPrice() > MaxSpreadPrice) return 0;
   if(atrValue <= 0.0 || (MinATRPrice > 0.0 && atrValue < MinATRPrice) ||
      (MaxATRPrice > 0.0 && atrValue > MaxATRPrice)) return 0;

   double close = iClose(_Symbol, PERIOD_CURRENT, 1);
   double open = iOpen(_Symbol, PERIOD_CURRENT, 1);
   if(close <= 0.0 || open <= 0.0 || MathAbs(close - open) < atrValue * MinBodyATR) return 0;

   bool bullish = fastEMA > slowEMA && close > fastEMA && rsiValue >= RSIUpper;
   bool bearish = fastEMA < slowEMA && close < fastEMA && rsiValue <= RSILower;
   if(!UseTrendFilter)
   {
      bullish = close > fastEMA && rsiValue >= RSIUpper;
      bearish = close < fastEMA && rsiValue <= RSILower;
   }

   int buyScore = 0, sellScore = 0;
   if(fastEMA > slowEMA) buyScore += 2;
   if(fastEMA < slowEMA) sellScore += 2;
   if(close > fastEMA) buyScore++;
   if(close < fastEMA) sellScore++;
   if(rsiValue >= RSIUpper) buyScore++;
   if(rsiValue <= RSILower) sellScore++;
   if(EMAHasSlope(1)) buyScore++;
   if(EMAHasSlope(-1)) sellScore++;
   if(close > open) buyScore++;
   if(close < open) sellScore++;
   if(!UseVolumeFilter || VolumeConfirmed())
   {
      buyScore++;
      sellScore++;
   }
   if(!RequireBreakout || BreakoutConfirmed(1)) buyScore++;
   if(!RequireBreakout || BreakoutConfirmed(-1)) sellScore++;

   if(bullish && buyScore >= MinimumSignalScore && (!RequireBreakout || BreakoutConfirmed(1))) return 1;
   if(bearish && sellScore >= MinimumSignalScore && (!RequireBreakout || BreakoutConfirmed(-1))) return -1;
   return 0;
}

bool EMAHasSlope(const int direction)
{
   double fastPrevious[1], slowPrevious[1];
   if(CopyBuffer(hFastEMA, 0, 2, 1, fastPrevious) != 1) return false;
   if(CopyBuffer(hSlowEMA, 0, 2, 1, slowPrevious) != 1) return false;
   if(direction > 0) return fastEMA > fastPrevious[0] && slowEMA >= slowPrevious[0];
   return fastEMA < fastPrevious[0] && slowEMA <= slowPrevious[0];
}

bool VolumeConfirmed()
{
   long current = iVolume(_Symbol, PERIOD_CURRENT, 1);
   double average = 0.0;
   const int samples = 10;
   for(int i = 2; i < 2 + samples; i++) average += (double)iVolume(_Symbol, PERIOD_CURRENT, i);
   average /= samples;
   return average > 0.0 && (double)current >= average * MinVolumeRatio;
}

bool BreakoutConfirmed(const int direction)
{
   if(!RequireBreakout || BreakoutLookback < 2) return true;
   // Start at shift 2 so the signal candle is not included in its own range.
   int highestShift = iHighest(_Symbol, PERIOD_CURRENT, MODE_HIGH, BreakoutLookback, 2);
   int lowestShift = iLowest(_Symbol, PERIOD_CURRENT, MODE_LOW, BreakoutLookback, 2);
   if(highestShift < 0 || lowestShift < 0) return false;
   double highest = iHigh(_Symbol, PERIOD_CURRENT, highestShift);
   double lowest = iLow(_Symbol, PERIOD_CURRENT, lowestShift);
   double close = iClose(_Symbol, PERIOD_CURRENT, 1);
   if(direction > 0) return close > highest && close - highest >= atrValue * BreakoutATRMinimum;
   return close < lowest && lowest - close >= atrValue * BreakoutATRMinimum;
}

bool IsSessionAllowed()
{
   MqlDateTime now; TimeToStruct(TimeCurrent(), now);
   if(StartHour == EndHour) return true;
   if(StartHour < EndHour) return now.hour >= StartHour && now.hour < EndHour;
   return now.hour >= StartHour || now.hour < EndHour;
}

void OpenBuy()
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double sl = NormalizePrice(ask - atrValue * SL_ATR_Multiplier);
   double tp = NormalizePrice(ask + atrValue * TP_ATR_Multiplier);
   if(!ValidStops(ORDER_TYPE_BUY, ask, sl, tp)) return;
   double lot = CalculateLotSize(ORDER_TYPE_BUY, ask, sl);
   if(lot <= 0.0) return;
   if(!trade.Buy(lot, _Symbol, ask, sl, tp, "GAC BUY"))
      Print("Buy failed: ", trade.ResultRetcode(), " ", trade.ResultRetcodeDescription());
}

void OpenSell()
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double sl = NormalizePrice(bid + atrValue * SL_ATR_Multiplier);
   double tp = NormalizePrice(bid - atrValue * TP_ATR_Multiplier);
   if(!ValidStops(ORDER_TYPE_SELL, bid, sl, tp)) return;
   double lot = CalculateLotSize(ORDER_TYPE_SELL, bid, sl);
   if(lot <= 0.0) return;
   if(!trade.Sell(lot, _Symbol, bid, sl, tp, "GAC SELL"))
      Print("Sell failed: ", trade.ResultRetcode(), " ", trade.ResultRetcodeDescription());
}

bool ValidStops(const ENUM_ORDER_TYPE type, const double entry, const double sl, const double tp)
{
   int level = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double minDistance = level * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(type == ORDER_TYPE_BUY) return entry - sl >= minDistance && tp - entry >= minDistance;
   return sl - entry >= minDistance && entry - tp >= minDistance;
}

double CalculateLotSize(const ENUM_ORDER_TYPE type, const double entry, const double stop)
{
   double riskMoney = AccountInfoDouble(ACCOUNT_BALANCE) * RiskPercent / 100.0;
   double profit = 0.0;
   if(riskMoney <= 0.0 || !OrderCalcProfit(type, _Symbol, 1.0, entry, stop, profit)) return 0.0;
   double lossPerLot = MathAbs(profit);
   if(lossPerLot <= 0.0) return 0.0;
   return NormalizeLot(riskMoney / lossPerLot);
}

int CountGACPositions()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket != 0 && PositionGetString(POSITION_SYMBOL) == _Symbol &&
         (ulong)PositionGetInteger(POSITION_MAGIC) == MagicNumber) count++;
   }
   return count;
}

bool DailyLossLimitReached()
{
   MqlDateTime date; TimeToStruct(TimeCurrent(), date);
   date.hour = 0; date.min = 0; date.sec = 0;
   if(!HistorySelect(StructToTime(date), TimeCurrent())) return false;
   double pnl = 0.0;
   for(int i = 0; i < HistoryDealsTotal(); i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0 || HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol ||
         (ulong)HistoryDealGetInteger(ticket, DEAL_MAGIC) != MagicNumber) continue;
      pnl += HistoryDealGetDouble(ticket, DEAL_PROFIT) + HistoryDealGetDouble(ticket, DEAL_SWAP) + HistoryDealGetDouble(ticket, DEAL_COMMISSION);
   }
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket != 0 && PositionGetString(POSITION_SYMBOL) == _Symbol &&
         (ulong)PositionGetInteger(POSITION_MAGIC) == MagicNumber)
         pnl += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
   }
   return pnl <= -(AccountInfoDouble(ACCOUNT_BALANCE) * MaxDailyLoss / 100.0);
}

bool IsTradingAllowed()
{
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED)) return false;
   if(!SymbolInfoInteger(_Symbol, SYMBOL_SELECT)) return false;
   return !UseSpreadFilter || GetSpreadPrice() <= MaxSpreadPrice;
}

double GetSpreadPrice() { return SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID); }
double NormalizePrice(const double price) { return NormalizeDouble(price, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)); }

double NormalizeLot(double lot)
{
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(step <= 0.0) return 0.0;
   lot = MathMax(minLot, MathMin(maxLot, lot));
   return NormalizeDouble(MathFloor(lot / step) * step, 2);
}
//+------------------------------------------------------------------+
