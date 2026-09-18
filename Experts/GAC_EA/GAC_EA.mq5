//+------------------------------------------------------------------+
//| GAC EA - Gold Adaptive Control                                   |
//| MT5 / XAUUSD                                                     |
//| Research foundation: trend, volatility and risk controls         |
//+------------------------------------------------------------------+
#property strict
#property version "1.10"

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

input int    FastEMA              = 20;
input int    SlowEMA              = 50;
input int    ATRPeriod            = 14;
input int    RSIPeriod            = 14;
input double RSIUpper             = 55.0;
input double RSILower             = 45.0;
input double SL_ATR_Multiplier    = 1.5;
input double TP_ATR_Multiplier    = 2.5;
input double MaxSpreadPrice       = 1.50;
input int    StartHour             = 7;
input int    EndHour               = 22;
input int    BreakoutLookback      = 20;
input double BreakoutATRMinimum    = 0.25;

int hFastEMA = INVALID_HANDLE;
int hSlowEMA = INVALID_HANDLE;
int hATR     = INVALID_HANDLE;
int hRSI     = INVALID_HANDLE;
datetime lastBarTime = 0;

double fastEMA = 0.0;
double slowEMA = 0.0;
double atrValue = 0.0;
double rsiValue = 50.0;

int OnInit()
{
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(SlippagePoints);
   trade.SetTypeFillingBySymbol(_Symbol);

   hFastEMA = iMA(_Symbol, PERIOD_CURRENT, FastEMA, 0, MODE_EMA, PRICE_CLOSE);
   hSlowEMA = iMA(_Symbol, PERIOD_CURRENT, SlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   hATR     = iATR(_Symbol, PERIOD_CURRENT, ATRPeriod);
   hRSI     = iRSI(_Symbol, PERIOD_CURRENT, RSIPeriod, PRICE_CLOSE);

   if(hFastEMA == INVALID_HANDLE || hSlowEMA == INVALID_HANDLE ||
      hATR == INVALID_HANDLE || hRSI == INVALID_HANDLE)
   {
      Print("GAC initialization failed. Error: ", GetLastError());
      return INIT_FAILED;
   }

   if(FastEMA >= SlowEMA || ATRPeriod < 2 || RSIPeriod < 2 ||
      RiskPercent <= 0.0 || MaxDailyLoss <= 0.0 ||
      SL_ATR_Multiplier <= 0.0 || TP_ATR_Multiplier <= 0.0)
   {
      Print("Invalid indicator or risk parameters.");
      return INIT_PARAMETERS_INCORRECT;
   }

   Print("GAC EA initialized on ", _Symbol, " / ", EnumToString(PERIOD_CURRENT));
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   if(hFastEMA != INVALID_HANDLE) IndicatorRelease(hFastEMA);
   if(hSlowEMA != INVALID_HANDLE) IndicatorRelease(hSlowEMA);
   if(hATR != INVALID_HANDLE)     IndicatorRelease(hATR);
   if(hRSI != INVALID_HANDLE)     IndicatorRelease(hRSI);
}

void OnTick()
{
   if(UseNewBarOnly && !IsNewBar()) return;
   if(!IsTradingAllowed() || DailyLossLimitReached()) return;
   if(!UpdateIndicators()) return;
   if(CountGACPositions() >= MaxPositions) return;

   int signal = GetSignal();
   if(signal > 0) OpenBuy();
   if(signal < 0) OpenSell();
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

   fastEMA = fast[0];
   slowEMA = slow[0];
   atrValue = atr[0];
   rsiValue = rsi[0];
   return (atrValue > 0.0 && fastEMA > 0.0 && slowEMA > 0.0);
}

int GetSignal()
{
   if(UseSessionFilter && !IsSessionAllowed()) return 0;
   if(UseSpreadFilter && GetSpreadPrice() > MaxSpreadPrice) return 0;
   if(atrValue <= 0.0) return 0;

   double close = iClose(_Symbol, PERIOD_CURRENT, 1);
   bool bullish = fastEMA > slowEMA && close > fastEMA && rsiValue >= RSIUpper;
   bool bearish = fastEMA < slowEMA && close < fastEMA && rsiValue <= RSILower;

   if(!UseTrendFilter)
   {
      bullish = close > fastEMA && rsiValue >= RSIUpper;
      bearish = close < fastEMA && rsiValue <= RSILower;
   }

   if(UseVolumeFilter && !VolumeConfirmed()) return 0;
   if(bullish && BreakoutConfirmed(1)) return 1;
   if(bearish && BreakoutConfirmed(-1)) return -1;
   return 0;
}

bool BreakoutConfirmed(const int direction)
{
   if(BreakoutLookback < 2) return true;
   int highestShift = iHighest(_Symbol, PERIOD_CURRENT, MODE_HIGH, BreakoutLookback, 2);
   int lowestShift = iLowest(_Symbol, PERIOD_CURRENT, MODE_LOW, BreakoutLookback, 2);
   if(highestShift < 0 || lowestShift < 0) return false;

   double highest = iHigh(_Symbol, PERIOD_CURRENT, highestShift);
   double lowest = iLow(_Symbol, PERIOD_CURRENT, lowestShift);
   double close = iClose(_Symbol, PERIOD_CURRENT, 1);
   if(direction > 0) return close > highest && (close - highest) >= atrValue * BreakoutATRMinimum;
   return close < lowest && (lowest - close) >= atrValue * BreakoutATRMinimum;
}

bool VolumeConfirmed()
{
   long current = iVolume(_Symbol, PERIOD_CURRENT, 1);
   double average = 0.0;
   const int samples = 10;
   for(int i = 2; i < 2 + samples; i++) average += (double)iVolume(_Symbol, PERIOD_CURRENT, i);
   average /= samples;
   return current >= average;
}

bool IsSessionAllowed()
{
   MqlDateTime now;
   TimeToStruct(TimeCurrent(), now);
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
   if(!trade.Buy(lot, _Symbol, 0.0, sl, tp, "GAC BUY"))
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
   if(!trade.Sell(lot, _Symbol, 0.0, sl, tp, "GAC SELL"))
      Print("Sell failed: ", trade.ResultRetcode(), " ", trade.ResultRetcodeDescription());
}

bool ValidStops(const ENUM_ORDER_TYPE type, const double entry, const double sl, const double tp)
{
   int stopsLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double minimum = stopsLevel * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(type == ORDER_TYPE_BUY)
      return sl < entry - minimum && tp > entry + minimum;
   return sl > entry + minimum && tp < entry - minimum;
}

double CalculateLotSize(const ENUM_ORDER_TYPE type, const double entry, const double stop)
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney = balance * RiskPercent / 100.0;
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
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         (ulong)PositionGetInteger(POSITION_MAGIC) == MagicNumber) count++;
   }
   return count;
}

bool DailyLossLimitReached()
{
   MqlDateTime date;
   TimeToStruct(TimeCurrent(), date);
   date.hour = 0; date.min = 0; date.sec = 0;
   datetime dayStart = StructToTime(date);
   if(!HistorySelect(dayStart, TimeCurrent())) return false;

   double realized = 0.0;
   for(int i = 0; i < HistoryDealsTotal(); i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;
      if(HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol) continue;
      if((ulong)HistoryDealGetInteger(ticket, DEAL_MAGIC) != MagicNumber) continue;
      realized += HistoryDealGetDouble(ticket, DEAL_PROFIT) +
                  HistoryDealGetDouble(ticket, DEAL_SWAP) +
                  HistoryDealGetDouble(ticket, DEAL_COMMISSION);
   }

   double floating = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         (ulong)PositionGetInteger(POSITION_MAGIC) == MagicNumber)
         floating += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
   }

   double limit = AccountInfoDouble(ACCOUNT_BALANCE) * MaxDailyLoss / 100.0;
   return realized + floating <= -limit;
}

bool IsTradingAllowed()
{
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED)) return false;
   ENUM_SYMBOL_TRADE_MODE mode = (ENUM_SYMBOL_TRADE_MODE)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE);
   if(mode == SYMBOL_TRADE_MODE_DISABLED || mode == SYMBOL_TRADE_MODE_CLOSEONLY) return false;
   return !UseSpreadFilter || GetSpreadPrice() <= MaxSpreadPrice;
}

double GetSpreadPrice()
{
   return SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID);
}

double NormalizePrice(const double price)
{
   return NormalizeDouble(price, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));
}

double NormalizeLot(double lot)
{
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(step <= 0.0) return 0.0;
   lot = MathMax(minLot, MathMin(maxLot, lot));
   lot = MathFloor(lot / step) * step;
   return NormalizeDouble(lot, 2);
}
//+------------------------------------------------------------------+
