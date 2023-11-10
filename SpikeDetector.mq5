//+------------------------------------------------------------------+
//|                                                     harmonic.mq5 |
//|                                  Copyright 2023, Tinashe Mashaya |
//|                                     tinashemashaya21@outlook.com |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>

CTrade trade;


#property copyright "Copyright 2023, Tinashe Mashaya"
#property link      "tinashemashaya21@outlook.com"
#property version   "1.00"
#define CRASH_SYMBOL "Crash" // Symbol for crash market
#define BOOM_SYMBOL "Boom"   // Symbol for boom market
int spikeIndicatorHandle;
double min_allowed_lot = 0;
ulong chart_id = 0;
input double STOP_LOSS = 50.0; 
input double TAKE_PROFIT = 50.0; 
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() 
{
   
//---
   spikeIndicatorHandle = iCustom(_Symbol, PERIOD_M1, "Market\\KazaSpikeDetector.ex5");
   chart_id = ChartID();
   min_allowed_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   if (spikeIndicatorHandle == INVALID_HANDLE)
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
        if(profit> 0 || profit <-0.40){
           trade.PositionClose(ticket);
        }
     }   
   if (chart_id != ChartID())
        return;
   bool open_trade = PositionSelect(_Symbol);
   if (open_trade)
       return;
   double upTrend[];
   double downTrend[];
   
   
   CopyBuffer(spikeIndicatorHandle, 3, 0, 10, downTrend);
   CopyBuffer(spikeIndicatorHandle, 4, 0, 10, upTrend);
   ArraySetAsSeries(upTrend, true);
   ArraySetAsSeries(downTrend, true);
   
   for (int i = ArraySize(upTrend) - 1; i >= 0; i--)
{
    
    //---
    // Print("New Values: " + upTrend);
   // PrintArray(upTrend);
    //PrintArray(downTrend);
}
   Comment("Buy Signal: "+upTrend[0]+"\nSell Signal: "+ downTrend[0]);
  
   if (upTrend[0] > 0 && upTrend[0]< 1  && StringFind(_Symbol, BOOM_SYMBOL) != -1)
    {
    
        // Convert pips to points depending on the broker's digits
        int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS); // Get the number of digits for the symbol
        double pip2point = MathPow(10, digits - 4);                  // Calculate the conversion factor from pips to points
        double current_tick = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double stop_loss = current_tick - STOP_LOSS * pip2point;     // Calculate stop loss in points
        double take_profit = current_tick + TAKE_PROFIT * pip2point; // Calculate take profit in points
        Comment("Buy Signal: " + upTrend[0]);
        trade.Buy(min_allowed_lot, _Symbol, current_tick );
       
    }
    else if (downTrend[0] > 0 && downTrend[0]< 1 && StringFind(_Symbol, CRASH_SYMBOL) != -1)
    {   
         // Convert pips to points depending on the broker's digits
        int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS); // Get the number of digits for the symbol
        double pip2point = MathPow(10, digits - 4);                  // Calculate the conversion factor from pips to points
        double current_tick = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        double stop_loss = current_tick + STOP_LOSS * pip2point;     // Calculate stop loss in points
        double take_profit = current_tick - TAKE_PROFIT * pip2point; // Calculate take profit in points

        Comment("Sell Signal: " , downTrend[0]);
        trade.Sell(min_allowed_lot, _Symbol, current_tick);
        
    }
    else
    {
        Comment("No Buy/Sell Signal Available ");
    }
    
}
void PrintArray(const double& array[])
{
   // Initialize an empty string
   string output = "";
   
   // Loop over the array elements and append them to the output string
   for (int i = 0; i < ArraySize(array); i++)
   {
      // Add a comma separator for all elements except the first one
      if (i > 0)
         output += ",";
      
      // Add the element value to the output string
      output += DoubleToString(array[i], 8); // You can change the number of decimal places here
   }
   
   // Print the output string surrounded by square brackets
   Print("[" + output + "]");
}

//+------------------------------------------------------------------+