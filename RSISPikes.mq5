//+------------------------------------------------------------------+
//|                                                        EARSI.mq5 |
//|                                 Copyright 2023, Tinashe Mashaya. |
//|                                     tinashemashaya21@outlook.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Tinashe Mashaya."
#property link      "tinashemashaya21@outlook.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#resource "TrendCatcher.ex5"
#include <Trade\Trade.mqh>
CTrade trade;
//#include <Series\Timeseries.mqh>
// Define the RSI period and levels
#define RSI_PERIOD 30
#define RSI_OVERBOUGHT 70
#define RSI_OVERSOLD 30
double rsi_current = 0;
double rsi_previous = 0 ;
// Declare the RSI indicator handle
int rsi_handle;
int customIndicatorHandle;
// Define the object names for buy and sell arrows
string buyArrowObjectName = "BuyArrow";
string sellArrowObjectName = "SellArrow";
#define SYMBOL_ARROWUP 233
#define SYMBOL_ARROWDOWN 234
int ATR_Handle;
datetime Time[];
ulong chart_id = 0;
ulong deal_ticket = 0;
input double stop_loss_multiplier = 2.0;   // Stop loss multiplier
input double take_profit_multiplier = 3.0; // Take profit multiplier
// Initialize the RSI indicator in the OnInit() function
double lot_size = 0.2;
  
input double STOP_LOSS = 50.0; 
input double TAKE_PROFIT = 50.0;   
double spikePrice = 0;

#define CRASH_SYMBOL "Crash" 
#define BOOM_SYMBOL "Boom"   
  
int OnInit()
{
   Print("Initialisation");
   chart_id = ChartID(); 
  // Create the RSI indicator with the current symbol and timeframe
  rsi_handle = iRSI(_Symbol, PERIOD_M1, RSI_PERIOD,PRICE_CLOSE);
  //customIndicatorHandle = iCustom(_Symbol,PERIOD_H2,"::TrendCatcher.ex5");//---
  
  ATR_Handle = iATR(_Symbol, PERIOD_M10, RSI_PERIOD);
  lot_size = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
  if (rsi_handle == INVALID_HANDLE&& customIndicatorHandle == INVALID_HANDLE && ATR_Handle == INVALID_HANDLE)
  {
    Print("Failed to load indicators");
    return INIT_FAILED;
  }
  return INIT_SUCCEEDED;
}


// Check for RSI cross overs in the OnTick() function
void OnTick()

{
  
  // Get the current and previous RSI values
  //double rsi_current, rsi_previous;//---
  if (chart_id != ChartID())
        return;
  double iRSIBuffer[];
  CopyBuffer(iRSI(_Symbol,PERIOD_M30,7,PRICE_CLOSE),0,0,1,iRSIBuffer);
  
  double upTrend[];
  double downTrend[];
  CopyBuffer(customIndicatorHandle,0,0,1,upTrend);
  CopyBuffer(customIndicatorHandle,1,0,1,downTrend);
  
  double ATR_Value[];
  CopyBuffer(ATR_Handle, 0, 0, 1, ATR_Value);
  
  
 // double irsiv = iRSIBuffer[0];
  rsi_current = iRSIBuffer[0];
  if (rsi_previous <=0){
     rsi_previous = rsi_current ;
     
     return ;
  }
   bool open_trade = PositionSelect(_Symbol);
   for(int i=0; i<PositionsTotal(); i++)
    {  // get the symbol name of the position
       string symbol = PositionGetSymbol(i);
        ulong ticket = PositionGetTicket(i);
        bool selected = PositionSelectByTicket(ticket);
        double profit = PositionGetDouble(POSITION_PROFIT);
        Print("The symbol of position ", i, " is ", symbol , " and profit is " ,profit);
        if(profit> 0 || profit <-5.0){
           trade.PositionClose(ticket);
        }
     }   
        
   /*if (open_trade)
       return;*/
   
   
    
   //Print("On Tick");
  Comment ("Current: ", rsi_current+ "\n"+"Previous: " +rsi_previous);
  //Print("Current: " ,rsi_current);
  
 
  
  // Check for RSI cross over from the top and cross the 70 level
  double current_ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK); 
  if (rsi_previous > RSI_OVERBOUGHT &&  StringFind(_Symbol, CRASH_SYMBOL) != -1 && current_ask < spikePrice)
  {
    
    trade.Sell(lot_size, _Symbol, current_ask);
    deal_ticket = trade.ResultDeal();
    Print("Sold: ", _Symbol, " ", deal_ticket);
  
    
  }

  // Check for RSI cross over from the bottom and cross the 30 level
  double current_bid = SymbolInfoDouble(_Symbol, SYMBOL_BID); 
  if (rsi_previous < RSI_OVERSOLD && StringFind(_Symbol, BOOM_SYMBOL) != -1 && current_bid > spikePrice)
  {
    
     trade.Buy(lot_size, _Symbol, current_bid);
     deal_ticket = trade.ResultDeal();
     Print("Bought: ", _Symbol, " ", deal_ticket);
  }
  rsi_previous = rsi_current ;
  if(StringFind(_Symbol, BOOM_SYMBOL) != -1){
    spikePrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
  }
  else if(StringFind(_Symbol, CRASH_SYMBOL) != -1){
      spikePrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
  }
}

// Deinitialize the RSI indicator in the OnDeinit() function
void OnDeinit(const int reason)
{
  // Release the RSI indicator handle
  Print("De Init ",reason);
  IndicatorRelease(rsi_handle);
}


