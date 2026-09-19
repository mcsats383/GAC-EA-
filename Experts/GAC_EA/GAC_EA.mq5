//+------------------------------------------------------------------+
//| GAC EA - Gold Adaptive Control                                   |
//| MT5 research build with explicit risk and execution controls      |
//+------------------------------------------------------------------+
#property strict
#property version "1.50"

#include <Trade/Trade.mqh>
CTrade trade;

input double RiskPercent             = 0.25;
input double MaxDailyLoss            = 2.0;
input double MaxEquityDrawdown       = 10.0;
input int    MaxConsecutiveLosses    = 3;
input double MaxExposurePercent      = 100.0;
input double MinMarginLevel          = 300.0;
input int    MaxPositions            = 1;
input ulong  MagicNumber             = 260824;
input int    SlippagePoints          = 30;

input bool   UseTrendFilter          = true;
input bool   UseVolumeFilter         = true;
input bool   UseSpreadFilter         = true;
input bool   UseSessionFilter        = true;
input bool   UseNewBarOnly           = true;
input bool   RequireBreakout          = true;
input bool   UseTrailingStop         = true;
input double BreakEvenATR            = 1.0;
input double TrailingATR             = 1.2;

input int    FastEMA                 = 20;
input int    SlowEMA                 = 50;
input int    ATRPeriod               = 14;
input int    RSIPeriod               = 14;
input double RSIUpper                = 55.0;
input double RSILower                = 45.0;
input double SL_ATR_Multiplier       = 1.5;
input double TP_ATR_Multiplier       = 2.5;
input double MaxSpreadPrice          = 1.50;
input double MinATRPrice             = 0.0;
input double MaxATRPrice             = 0.0;
input double MinVolumeRatio          = 1.05;
input double MinBodyATR              = 0.20;
input int    StartHour               = 7;
input int    EndHour                 = 22;
input int    BreakoutLookback        = 20;
input double BreakoutATRMinimum      = 0.25;
input int    MinimumSignalScore      = 6;

int hFastEMA=INVALID_HANDLE, hSlowEMA=INVALID_HANDLE, hATR=INVALID_HANDLE, hRSI=INVALID_HANDLE;
datetime lastBarTime=0;
double fastEMA=0.0, slowEMA=0.0, atrValue=0.0, rsiValue=50.0;

int OnInit()
{
   if(FastEMA<2 || FastEMA>=SlowEMA || ATRPeriod<2 || RSIPeriod<2 || RiskPercent<=0.0 ||
      MaxDailyLoss<=0.0 || MaxEquityDrawdown<=0.0 || MaxConsecutiveLosses<1 ||
      MaxExposurePercent<=0.0 || MinMarginLevel<0.0 || MaxPositions<1 ||
      SL_ATR_Multiplier<=0.0 || TP_ATR_Multiplier<=0.0 || MinimumSignalScore<1 ||
      MinimumSignalScore>10 || BreakoutLookback<2 || MinVolumeRatio<0.0 || MinBodyATR<0.0 ||
      BreakEvenATR<0.0 || TrailingATR<=0.0) return INIT_PARAMETERS_INCORRECT;
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(SlippagePoints);
   trade.SetTypeFillingBySymbol(_Symbol);
   hFastEMA=iMA(_Symbol,PERIOD_CURRENT,FastEMA,0,MODE_EMA,PRICE_CLOSE);
   hSlowEMA=iMA(_Symbol,PERIOD_CURRENT,SlowEMA,0,MODE_EMA,PRICE_CLOSE);
   hATR=iATR(_Symbol,PERIOD_CURRENT,ATRPeriod);
   hRSI=iRSI(_Symbol,PERIOD_CURRENT,RSIPeriod,PRICE_CLOSE);
   if(hFastEMA==INVALID_HANDLE || hSlowEMA==INVALID_HANDLE || hATR==INVALID_HANDLE || hRSI==INVALID_HANDLE)
      return INIT_FAILED;
   PrintFormat("GAC EA v1.50 initialized: %s / %s / magic=%I64u",_Symbol,EnumToString(PERIOD_CURRENT),MagicNumber);
   return INIT_SUCCEEDED;
}
void OnDeinit(const int reason)
{
   if(hFastEMA!=INVALID_HANDLE) IndicatorRelease(hFastEMA);
   if(hSlowEMA!=INVALID_HANDLE) IndicatorRelease(hSlowEMA);
   if(hATR!=INVALID_HANDLE) IndicatorRelease(hATR);
   if(hRSI!=INVALID_HANDLE) IndicatorRelease(hRSI);
}
void OnTick()
{
   if(!UpdateIndicators()) return;
   ManagePositions();
   if(UseNewBarOnly && !IsNewBar()) return;
   if(!IsTradingAllowed() || RiskGuardTriggered() || CountGACPositions()>=MaxPositions) return;
   int signal=GetSignal();
   if(signal>0) OpenPosition(ORDER_TYPE_BUY);
   else if(signal<0) OpenPosition(ORDER_TYPE_SELL);
}
bool IsNewBar()
{
   datetime t=iTime(_Symbol,PERIOD_CURRENT,0);
   if(t==0 || t==lastBarTime) return false;
   lastBarTime=t; return true;
}
bool UpdateIndicators()
{
   double f[1],s[1],a[1],r[1];
   if(CopyBuffer(hFastEMA,0,1,1,f)!=1 || CopyBuffer(hSlowEMA,0,1,1,s)!=1 ||
      CopyBuffer(hATR,0,1,1,a)!=1 || CopyBuffer(hRSI,0,1,1,r)!=1) return false;
   fastEMA=f[0]; slowEMA=s[0]; atrValue=a[0]; rsiValue=r[0];
   return fastEMA>0.0 && slowEMA>0.0 && atrValue>0.0;
}
int GetSignal()
{
   if(UseSessionFilter && !IsSessionAllowed()) return 0;
   double spread=GetSpreadPrice();
   if(UseSpreadFilter && spread>MaxSpreadPrice) { PrintFormat("SIGNAL_BLOCK spread=%.5f limit=%.5f",spread,MaxSpreadPrice); return 0; }
   if((MinATRPrice>0.0 && atrValue<MinATRPrice) || (MaxATRPrice>0.0 && atrValue>MaxATRPrice)) return 0;
   double close=iClose(_Symbol,PERIOD_CURRENT,1), open=iOpen(_Symbol,PERIOD_CURRENT,1);
   if(close<=0.0 || open<=0.0 || MathAbs(close-open)<atrValue*MinBodyATR) return 0;
   bool buy=fastEMA>slowEMA && close>fastEMA && rsiValue>=RSIUpper;
   bool sell=fastEMA<slowEMA && close<fastEMA && rsiValue<=RSILower;
   if(!UseTrendFilter) { buy=close>fastEMA && rsiValue>=RSIUpper; sell=close<fastEMA && rsiValue<=RSILower; }
   int buyScore=0,sellScore=0;
   if(fastEMA>slowEMA) buyScore+=2; if(fastEMA<slowEMA) sellScore+=2;
   if(close>fastEMA) buyScore++; if(close<fastEMA) sellScore++;
   if(rsiValue>=RSIUpper) buyScore++; if(rsiValue<=RSILower) sellScore++;
   if(EMAHasSlope(1)) buyScore++; if(EMAHasSlope(-1)) sellScore++;
   if(close>open) buyScore++; if(close<open) sellScore++;
   if(!UseVolumeFilter || VolumeConfirmed()) { if(close>open) buyScore++; if(close<open) sellScore++; }
   bool upBreak=!RequireBreakout || BreakoutConfirmed(1), downBreak=!RequireBreakout || BreakoutConfirmed(-1);
   if(upBreak) buyScore++; if(downBreak) sellScore++;
   PrintFormat("SIGNAL score_buy=%d score_sell=%d atr=%.5f spread=%.5f",buyScore,sellScore,atrValue,spread);
   if(buy && buyScore>=MinimumSignalScore && upBreak) return 1;
   if(sell && sellScore>=MinimumSignalScore && downBreak) return -1;
   return 0;
}
bool EMAHasSlope(const int d)
{
   double f[1],s[1]; if(CopyBuffer(hFastEMA,0,2,1,f)!=1 || CopyBuffer(hSlowEMA,0,2,1,s)!=1) return false;
   return d>0 ? fastEMA>f[0] && slowEMA>=s[0] : fastEMA<f[0] && slowEMA<=s[0];
}
bool VolumeConfirmed()
{
   long current=iVolume(_Symbol,PERIOD_CURRENT,1); double avg=0.0;
   for(int i=2;i<12;i++) avg+=(double)iVolume(_Symbol,PERIOD_CURRENT,i);
   return avg>0.0 && (double)current>=avg/10.0*MinVolumeRatio;
}
bool BreakoutConfirmed(const int d)
{
   int hi=iHighest(_Symbol,PERIOD_CURRENT,MODE_HIGH,BreakoutLookback,2), lo=iLowest(_Symbol,PERIOD_CURRENT,MODE_LOW,BreakoutLookback,2);
   if(hi<0 || lo<0) return false;
   double close=iClose(_Symbol,PERIOD_CURRENT,1), high=iHigh(_Symbol,PERIOD_CURRENT,hi), low=iLow(_Symbol,PERIOD_CURRENT,lo);
   return d>0 ? close>high && close-high>=atrValue*BreakoutATRMinimum : close<low && low-close>=atrValue*BreakoutATRMinimum;
}
bool IsSessionAllowed()
{
   MqlDateTime t; TimeToStruct(TimeCurrent(),t); if(StartHour==EndHour) return true;
   return StartHour<EndHour ? t.hour>=StartHour && t.hour<EndHour : t.hour>=StartHour || t.hour<EndHour;
}
void OpenPosition(const ENUM_ORDER_TYPE type)
{
   double price=type==ORDER_TYPE_BUY ? SymbolInfoDouble(_Symbol,SYMBOL_ASK) : SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double sl=type==ORDER_TYPE_BUY ? NormalizePrice(price-atrValue*SL_ATR_Multiplier) : NormalizePrice(price+atrValue*SL_ATR_Multiplier);
   double tp=type==ORDER_TYPE_BUY ? NormalizePrice(price+atrValue*TP_ATR_Multiplier) : NormalizePrice(price-atrValue*TP_ATR_Multiplier);
   if(!ValidStops(type,price,sl,tp)) { Print("ENTRY_BLOCK invalid stops"); return; }
   double lot=CalculateLotSize(type,price,sl); if(lot<=0.0 || !ExposureAllowed(type,lot,price) || !MarginAllowed(type,lot,price)) return;
   bool ok=type==ORDER_TYPE_BUY ? trade.Buy(lot,_Symbol,price,sl,tp,"GAC BUY") : trade.Sell(lot,_Symbol,price,sl,tp,"GAC SELL");
   PrintFormat("ENTRY type=%s lot=%.8f price=%.5f sl=%.5f tp=%.5f ok=%s retcode=%u %s",type==ORDER_TYPE_BUY?"BUY":"SELL",lot,price,sl,tp,ok?"true":"false",trade.ResultRetcode(),trade.ResultRetcodeDescription());
}
void ManagePositions()
{
   if(!UseTrailingStop || atrValue<=0.0) return;
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID), ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK), point=SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i); if(ticket==0 || PositionGetString(POSITION_SYMBOL)!=_Symbol || (ulong)PositionGetInteger(POSITION_MAGIC)!=MagicNumber) continue;
      long type=PositionGetInteger(POSITION_TYPE); double open=PositionGetDouble(POSITION_PRICE_OPEN), oldSL=PositionGetDouble(POSITION_SL), tp=PositionGetDouble(POSITION_TP), candidate=oldSL;
      if(type==POSITION_TYPE_BUY && bid-open>=atrValue*BreakEvenATR) { double be=NormalizePrice(open+2*point); candidate=oldSL==0.0?be:MathMax(oldSL,be); candidate=MathMax(candidate,NormalizePrice(bid-atrValue*TrailingATR)); if(candidate>oldSL && ValidStops(ORDER_TYPE_BUY,bid,candidate,tp)) trade.PositionModify(ticket,candidate,tp); }
      if(type==POSITION_TYPE_SELL && open-ask>=atrValue*BreakEvenATR) { double be=NormalizePrice(open-2*point); candidate=oldSL==0.0?be:MathMin(oldSL,be); candidate=MathMin(candidate,NormalizePrice(ask+atrValue*TrailingATR)); if((oldSL==0.0 || candidate<oldSL) && ValidStops(ORDER_TYPE_SELL,ask,candidate,tp)) trade.PositionModify(ticket,candidate,tp); }
   }
}
bool ValidStops(const ENUM_ORDER_TYPE type,const double entry,const double sl,const double tp)
{
   double minDistance=(double)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   return type==ORDER_TYPE_BUY ? entry-sl>=minDistance && tp-entry>=minDistance : sl-entry>=minDistance && entry-tp>=minDistance;
}
double CalculateLotSize(const ENUM_ORDER_TYPE type,const double entry,const double stop)
{
   double risk=AccountInfoDouble(ACCOUNT_EQUITY)*RiskPercent/100.0, p=0.0;
   if(risk<=0.0 || !OrderCalcProfit(type,_Symbol,1.0,entry,stop,p) || MathAbs(p)<=0.0) return 0.0;
   return NormalizeLot(risk/MathAbs(p));
}
bool ExposureAllowed(const ENUM_ORDER_TYPE type,const double lot,const double price)
{
   double equity=AccountInfoDouble(ACCOUNT_EQUITY), contract=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_CONTRACT_SIZE), exposure=0.0;
   for(int i=PositionsTotal()-1;i>=0;i--) { ulong t=PositionGetTicket(i); if(t!=0 && PositionGetString(POSITION_SYMBOL)==_Symbol && (ulong)PositionGetInteger(POSITION_MAGIC)==MagicNumber) exposure+=PositionGetDouble(POSITION_VOLUME)*contract*price; }
   double proposed=exposure+lot*contract*price;
   if(equity<=0.0 || proposed>equity*MaxExposurePercent/100.0) { PrintFormat("ENTRY_BLOCK exposure=%.2f limit=%.2f",proposed,equity*MaxExposurePercent/100.0); return false; }
   return true;
}
bool MarginAllowed(const ENUM_ORDER_TYPE type,const double lot,const double price)
{
   double margin=0.0, equity=AccountInfoDouble(ACCOUNT_EQUITY), free=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   if(!OrderCalcMargin(type,_Symbol,lot,price,margin) || margin>free) { Print("ENTRY_BLOCK insufficient margin"); return false; }
   double used=AccountInfoDouble(ACCOUNT_MARGIN)+margin; if(used>0.0 && equity/used*100.0<MinMarginLevel) { Print("ENTRY_BLOCK margin level"); return false; }
   return true;
}
int CountGACPositions()
{
   int n=0; for(int i=PositionsTotal()-1;i>=0;i--) { ulong t=PositionGetTicket(i); if(t!=0 && PositionGetString(POSITION_SYMBOL)==_Symbol && (ulong)PositionGetInteger(POSITION_MAGIC)==MagicNumber) n++; } return n;
}
bool RiskGuardTriggered()
{
   double balance=AccountInfoDouble(ACCOUNT_BALANCE), equity=AccountInfoDouble(ACCOUNT_EQUITY);
   if(balance<=0.0 || equity<=balance*(1.0-MaxEquityDrawdown/100.0)) { Print("RISK_BLOCK equity drawdown"); return true; }
   if(DailyLossLimitReached()) { Print("RISK_BLOCK daily loss"); return true; }
   if(CountConsecutiveLosses()>=MaxConsecutiveLosses) { Print("RISK_BLOCK consecutive losses"); return true; }
   return false;
}
bool DailyLossLimitReached()
{
   MqlDateTime d; TimeToStruct(TimeCurrent(),d); d.hour=0; d.min=0; d.sec=0; if(!HistorySelect(StructToTime(d),TimeCurrent())) return false;
   double pnl=0.0; for(int i=0;i<HistoryDealsTotal();i++) { ulong t=HistoryDealGetTicket(i); if(t!=0 && HistoryDealGetString(t,DEAL_SYMBOL)==_Symbol && (ulong)HistoryDealGetInteger(t,DEAL_MAGIC)==MagicNumber) pnl+=HistoryDealGetDouble(t,DEAL_PROFIT)+HistoryDealGetDouble(t,DEAL_SWAP)+HistoryDealGetDouble(t,DEAL_COMMISSION); }
   for(int i=PositionsTotal()-1;i>=0;i--) { ulong t=PositionGetTicket(i); if(t!=0 && PositionGetString(POSITION_SYMBOL)==_Symbol && (ulong)PositionGetInteger(POSITION_MAGIC)==MagicNumber) pnl+=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP); }
   return pnl<=-(AccountInfoDouble(ACCOUNT_BALANCE)*MaxDailyLoss/100.0);
}
int CountConsecutiveLosses()
{
   if(!HistorySelect(0,TimeCurrent())) return 0; int losses=0;
   for(int i=HistoryDealsTotal()-1;i>=0;i--) { ulong t=HistoryDealGetTicket(i); if(t==0 || HistoryDealGetString(t,DEAL_SYMBOL)!=_Symbol || (ulong)HistoryDealGetInteger(t,DEAL_MAGIC)!=MagicNumber || HistoryDealGetInteger(t,DEAL_ENTRY)!=DEAL_ENTRY_OUT) continue; double p=HistoryDealGetDouble(t,DEAL_PROFIT)+HistoryDealGetDouble(t,DEAL_SWAP)+HistoryDealGetDouble(t,DEAL_COMMISSION); if(p<0.0) losses++; else if(p>0.0) break; }
   return losses;
}
bool IsTradingAllowed() { return TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) && MQLInfoInteger(MQL_TRADE_ALLOWED) && SymbolInfoInteger(_Symbol,SYMBOL_SELECT) && (!UseSpreadFilter || GetSpreadPrice()<=MaxSpreadPrice); }
double GetSpreadPrice() { return SymbolInfoDouble(_Symbol,SYMBOL_ASK)-SymbolInfoDouble(_Symbol,SYMBOL_BID); }
double NormalizePrice(const double p) { return NormalizeDouble(p,(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS)); }
double NormalizeLot(double lot)
{
   double min=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN), max=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX), step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP); if(step<=0.0) return 0.0;
   lot=MathMax(min,MathMin(max,lot)); lot=MathFloor(lot/step+1e-9)*step; int digits=0; double s=step; while(digits<8 && MathAbs(s-MathRound(s))>1e-9) { s*=10.0; digits++; } return NormalizeDouble(lot,digits);
}
//+------------------------------------------------------------------+
