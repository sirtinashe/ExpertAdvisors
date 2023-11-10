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
  
int OnInit()
{
   Print("Initialisation");
   chart_id = ChartID(); 
  // Create the RSI indicator with the current symbol and timeframe
  rsi_handle = iRSI(_Symbol, PERIOD_M30, RSI_PERIOD,PRICE_CLOSE);
  customIndicatorHandle = iCustom(_Symbol,PERIOD_H2,"::TrendCatcher.ex5");
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
  CopyBuffer(iRSI(_Symbol,PERIOD_M30,14,PRICE_CLOSE),0,0,1,iRSIBuffer);
  
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
        
   if (open_trade)
       return;
   // Clear previous arrows
    ObjectDelete(0, buyArrowObjectName);
    ObjectDelete(0, sellArrowObjectName);
    
   //Print("On Tick");
  Comment ("Current: ", rsi_current+ "\n"+"Previous: " +rsi_previous);
  //Print("Current: " ,rsi_current);
  
 
  
  // Check for RSI cross over from the top and cross the 70 level
  
  if (rsi_previous > RSI_OVERBOUGHT && rsi_current < RSI_OVERBOUGHT && downTrend[0] != 1.7976931348623157e+308)
  {
    // RSI crossed below the overbought level, indicating a possible sell signal
    double current_tick = SymbolInfoDouble(_Symbol, SYMBOL_BID); 
    Print("RSI crossed below the overbought level of ", RSI_OVERBOUGHT + " and it's a sell signal");
    double stop_loss = current_tick + (ATR_Value[0] * stop_loss_multiplier);
    double take_profit = current_tick - (ATR_Value[0] * take_profit_multiplier);
    trade.Sell(lot_size, _Symbol, current_tick, stop_loss, take_profit);
    deal_ticket = trade.ResultDeal();
    
          /*
           // Convert pips to points depending on the broker's digits
            int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS); // Get the number of digits for the symbol
            double pip2point = MathPow(10, digits - 4);                  // Calculate the conversion factor from pips to points

            double stop_loss = current_tick + STOP_LOSS * pip2point;     // Calculate stop loss in points
            double take_profit = current_tick - TAKE_PROFIT * pip2point; // Calculate take profit in points

            trade.Sell(lot_size, _Symbol, current_tick, stop_loss, take_profit);*/
     
    Print("Sold: ", _Symbol, " ", deal_ticket);
  
    
  }

  // Check for RSI cross over from the bottom and cross the 30 level
  if (rsi_previous < RSI_OVERSOLD && rsi_current > RSI_OVERSOLD && upTrend[0] != 1.7976931348623157e+308)
  {
    // RSI crossed above the oversold level, indicating a possible buy signal
    double current_tick = SymbolInfoDouble(_Symbol, SYMBOL_ASK); 
    Print("RSI crossed above the oversold level of", RSI_OVERSOLD + " and it's a buy signal");
     double stop_loss = current_tick - (ATR_Value[0] * stop_loss_multiplier);
     double take_profit = current_tick + (ATR_Value[0] * take_profit_multiplier);
     trade.Buy(lot_size, _Symbol, current_tick, stop_loss, take_profit);
     deal_ticket = trade.ResultDeal();
     Print("Bought: ", _Symbol, " ", deal_ticket);
     
           /*// Convert pips to points depending on the broker's digits
            int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS); // Get the number of digits for the symbol
            double pip2point = MathPow(10, digits - 4);                  // Calculate the conversion factor from pips to points
            double stop_loss = current_tick - STOP_LOSS * pip2point;     // Calculate stop loss in points
            double take_profit = current_tick + TAKE_PROFIT * pip2point; // Calculate take profit in points
            trade.Buy(lot_size, _Symbol, current_tick, stop_loss, take_profit);*/
    
    
  }
  rsi_previous = rsi_current ;
}

// Deinitialize the RSI indicator in the OnDeinit() function
void OnDeinit(const int reason)
{
  // Release the RSI indicator handle
  Print("De Init ",reason);
  IndicatorRelease(rsi_handle);
}

void DrawBuyArrow(double price)
{
    ObjectCreate(0, buyArrowObjectName, OBJ_ARROW, 0, TimeCurrent(), price);
    
    ObjectSetInteger(0, buyArrowObjectName, OBJPROP_ARROWCODE, SYMBOL_ARROWUP);
    ObjectSetInteger(0, buyArrowObjectName, OBJPROP_COLOR, clrGreen);
}

// Function to draw a sell arrow on the chart
void DrawSellArrow(double price)
{
    ObjectCreate(0, sellArrowObjectName, OBJ_ARROW, 0, TimeCurrent(), price);
    ObjectSetInteger(0, sellArrowObjectName, OBJPROP_ARROWCODE, SYMBOL_ARROWDOWN);
    ObjectSetInteger(0, sellArrowObjectName, OBJPROP_COLOR, clrRed);
}

