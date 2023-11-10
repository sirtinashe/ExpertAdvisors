//+------------------------------------------------------------------+
//|                                                     harmonic.mq5 |
//|                                  Copyright 2023, Tinashe Mashaya |
//|                                     tinashemashaya21@outlook.com |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#resource "TrendCatcher.ex5"
CTrade trade;


#property copyright "Copyright 2023, Tinashe Mashaya"
#property link      "tinashemashaya21@outlook.com"
#property version   "1.00"
int harmonicIndicatorHandle;
double min_allowed_lot = 0;
ulong chart_id = 0;
double previous_entry = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() 
{
   
//---
   harmonicIndicatorHandle = iCustom(_Symbol, PERIOD_H1, "Market\\BasicHarmonicPatternMT5.ex5");
   chart_id = ChartID();
   min_allowed_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   if (harmonicIndicatorHandle == INVALID_HANDLE)
    {
        Print("Failed to load custom indicator!");
        return INIT_FAILED;
    }

    
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) 
{
   
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() 
{
   for(int i=0; i<PositionsTotal(); i++)
    {  // get the symbol name of the position
       string symbol = PositionGetSymbol(i);
        ulong ticket = PositionGetTicket(i);
        bool selected = PositionSelectByTicket(ticket);
        double profit = PositionGetDouble(POSITION_PROFIT);
        Print("The symbol of position ", i, " is ", symbol , " and profit is " ,profit);
        if(profit> 0 ){
           trade.PositionClose(ticket);
        }
     }   
   if (chart_id != ChartID())
        return;
   bool open_trade = PositionSelect(_Symbol);
   if (open_trade)
       return;
   double buySig[];
   double sellSig[];
   double sl[];
   double tp1[];
   CopyBuffer(harmonicIndicatorHandle, 0, 1, 1, buySig);
   CopyBuffer(harmonicIndicatorHandle, 1, 1, 1, sellSig);
   CopyBuffer(harmonicIndicatorHandle, 2, 1, 1, sl);
   CopyBuffer(harmonicIndicatorHandle, 3, 1, 1, tp1);
   
   
  
   if (buySig[0] != 1.7976931348623157e+308)
    {
        double current_tick = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        Comment("Buy Sygnal: "+ buySig[0]  + " SL: "+ sl[0] +"\nTP1: "+ tp1[0]);
        if(buySig[0] != previous_entry){
            double new_sl = current_tick - (buySig[0]- sl[0]);
            double new_tp = current_tick + (tp1[0]- buySig[0] );
            trade.Buy(min_allowed_lot, _Symbol, current_tick, sl[0]+20, tp1[0] );
            previous_entry = buySig[0];
        }
       
    }
    else if (sellSig[0] != 1.7976931348623157e+308)
    {
        double current_tick = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        Comment("Sell Signal: "+ sellSig[0] + " SL: "+ sl[0]+"\nTP1: " +tp1[0]);
        
        if(sellSig[0] != previous_entry){
           double new_sl = current_tick + (sl[0] -sellSig[0]);
           double new_tp = current_tick - (sellSig[0] -tp1[0]);
           trade.Sell(min_allowed_lot, _Symbol, current_tick, sl[0]+20, tp1[0]);
           previous_entry = sellSig[0];
        }
    }
    else
    {
        Comment("No Buy/Sell Signal Available ",buySig[0]);
    }
    
}

//+------------------------------------------------------------------+