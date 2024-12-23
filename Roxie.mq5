//+------------------------------------------------------------------+
//|                                                        Roxie.mq5 |
//|                                 Copyright 2023, Tinashe Mashaya. |
//|                                     tinashemashaya21@outlook.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Tinashe Mashaya."
#property link      "tinashemashaya21@outlook.com"
#property version   "1.00"


// Include the Trade library
#include <Trade\Trade.mqh>

// Create a trade object
CTrade trade;

// Define constants
#define LOT_SIZE 1.0         // Lot size for trading
    
#define CRASH_SYMBOL "Crash" // Symbol for crash market
#define BOOM_SYMBOL "Boom"   // Symbol for boom market
#resource "TrendCatcher.ex5"

bool isBotRunning = false;

// Define a custom event ID for changing the bot status
#define BOT_STATUS_EVENT CHARTEVENT_CUSTOM+1

// Declare global variables
double previous_tick = 0; // Previous tick price
double current_tick = 0;  // Current tick price
ulong last_trade_id = 0;  // Last trade ID
ulong chart_id = 0;       // Chart ID
bool has_open_position = false;
int allowed_to_trade = 100 ;
ulong deal_ticket = 0;



double lot_size = 0.2;
double min_allowed_lot = 0;
// Boom 500 , Crash 500 , LOT 50
// Boom 300 Lot 40
// Crash 300 LOT 70 ;
input double STOP_LOSS = 50.0; 
input double TAKE_PROFIT = 50.0; 
input double USER_LOT_SIZE = 0.2; // The lot size for trading

double base_lot = 0;
int customIndicatorHandle;
int mainTrendIndicatorHandle;
int hourTrendIndicatorHandle;

// Initialization function
int OnInit()
{
    
    Print("Initialization");
    EventSetTimer(60);
    previous_tick = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    min_allowed_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    if (lot_size < min_allowed_lot){
      base_lot = min_allowed_lot ;
    }else{
      base_lot = USER_LOT_SIZE ;
    }
    base_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    lot_size = base_lot ;
    last_trade_id = 0;
    chart_id = ChartID(); // Get the current chart ID
    Comment("Stop Loss: ", STOP_LOSS, "%\n",
        "Take Profit: ", TAKE_PROFIT, "%\n",
        "Lot Size: ", lot_size);
    customIndicatorHandle = iCustom(_Symbol,PERIOD_M5,"::TrendCatcher.ex5");
    mainTrendIndicatorHandle = iCustom(_Symbol,PERIOD_M15,"::TrendCatcher.ex5");
    hourTrendIndicatorHandle = iCustom(_Symbol,PERIOD_M15,"::TrendCatcher.ex5");

    // Check if the indicator loaded successfully
    if (customIndicatorHandle == INVALID_HANDLE || mainTrendIndicatorHandle == INVALID_HANDLE || hourTrendIndicatorHandle== INVALID_HANDLE)
    {
        Print("Failed to load custom indicator!");
        return INIT_FAILED;
    }

    return (INIT_SUCCEEDED);
}

// Deinitialization function
void OnDeinit(const int reason)
{
    Print("Deinitialization: ", reason);
    EventKillTimer();
}
void OnTimer()
  {
     allowed_to_trade += 1 ;
  }
// Tick function
void OnTick()
{
  
    if (chart_id != ChartID())
        return; // Exit if the EA is running on a different chart
    
    double upTrend[];
    double downTrend[];
    CopyBuffer(customIndicatorHandle,0,0,1,upTrend);
    CopyBuffer(customIndicatorHandle,1,0,1,downTrend);
    
    double mainUpTrend[];
    double mainDownTrend[];
    CopyBuffer(customIndicatorHandle,0,0,1,mainUpTrend);
    CopyBuffer(customIndicatorHandle,1,0,1,mainDownTrend);
    
    double hourUpTrend[];
    double hourDownTrend[];
    CopyBuffer(hourTrendIndicatorHandle,0,0,1,hourUpTrend);
    CopyBuffer(hourTrendIndicatorHandle,1,0,1,hourDownTrend);
    
    if(upTrend[0] != 1.7976931348623157e+308){
       Comment("Uptrend Value: " ,mainUpTrend[0]);
    }else if(downTrend[0]!= 1.7976931348623157e+308){
       Comment("DownTrend Value: " ,mainDownTrend[0]);
    }else{
       Comment("Unknown Trend");
    }
    
    
    

    if (is_new_bar()) // Check if a new bar has formed
    {
        current_tick = SymbolInfoDouble(_Symbol, SYMBOL_BID); // Get the current bid price
        bool open_trade = PositionSelect(_Symbol);
        /*if(allowed_to_trade < 30)
          return ;*/

        if (open_trade)
            return;

        

        // Check if the current tick is lower than the previous tick and the symbol is crash
        if ( current_tick < previous_tick && StringFind(_Symbol, CRASH_SYMBOL) != -1  && upTrend[0] != 1.7976931348623157e+308 && mainUpTrend[0] != 1.7976931348623157e+308 && hourUpTrend[0] != 1.7976931348623157e+308)
        {
           
            

            // Convert pips to points depending on the broker's digits
            int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS); // Get the number of digits for the symbol
            double pip2point = MathPow(10, digits - 4);                  // Calculate the conversion factor from pips to points
            
            
            double stop_loss = current_tick - STOP_LOSS * pip2point;     // Calculate stop loss in points
            double take_profit = current_tick + TAKE_PROFIT * pip2point; // Calculate take profit in points

            trade.Buy(lot_size, _Symbol, current_tick, stop_loss, take_profit);
            deal_ticket = trade.ResultDeal();
            Print("Bought: ", _Symbol, " ", deal_ticket);
            has_open_position = true; // Set the flag to true
        }
        // Check if the current tick is higher than the previous tick and the symbol is boom
        else if ( current_tick > previous_tick && StringFind(_Symbol, BOOM_SYMBOL) != -1  && downTrend[0] != 1.7976931348623157e+308 && mainDownTrend[0] != 1.7976931348623157e+308 && hourDownTrend[0] != 1.7976931348623157e+308)
        {
          
           
           
            // Convert pips to points depending on the broker's digits
            int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS); // Get the number of digits for the symbol
            double pip2point = MathPow(10, digits - 4);                  // Calculate the conversion factor from pips to points

            double stop_loss = current_tick + STOP_LOSS * pip2point;     // Calculate stop loss in points
            double take_profit = current_tick - TAKE_PROFIT * pip2point; // Calculate take profit in points

            trade.Sell(lot_size, _Symbol, current_tick, stop_loss, take_profit);
            deal_ticket = trade.ResultDeal();

            Print("Sold: ", _Symbol, " ", deal_ticket);
            has_open_position = true; // Set the flag to true
        }

        previous_tick = current_tick; // Update the previous tick price
    }
}

// Function to check if a new bar has formed
bool is_new_bar()
{
    datetime current_time = iTime(_Symbol, PERIOD_M1, 0); // Get the current bar time
    static datetime prior_time = current_time;            // Initialize the prior bar time
    bool result = (current_time != prior_time);           // Compare the current and prior bar times
    prior_time = current_time;                            // Update the prior bar time
    return (result);                                      // Return the result
}

//+------------------------------------------------------------------+
//| OnTrade event handler                                            |
//+------------------------------------------------------------------+

void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   

    if (trans.symbol == _Symbol && trans.deal!= 0)
    {
        //bool open_trade = PositionSelect(_Symbol);
        bool history = HistoryDealSelect(trans.deal);
        double profit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT);//---
        double closingPrice=HistoryDealGetDouble(trans.deal,DEAL_PRICE);
        
        
        if(profit>0){
         PrintFormat("The last deal for %s was profitable: %.2f",_Symbol,profit);
         lot_size = base_lot;
      }
      /*else if(profit < -5 ){
        allowed_to_trade = 0 ;
        lot_size = base_lot;
      }*/
         
      else if(profit<0){
         
          PrintFormat("The last deal for %s was unprofitable: %.2f",_Symbol,profit);
         //---
          lot_size *= 2;
          
      }
        
      
    }
}

void ShowBotStatus()
{
  // Create a text label if it does not exist
  if (!ObjectFind(0, "BotStatusLabel"))
  {
    ObjectCreate(0, "BotStatusLabel", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "BotStatusLabel", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    ObjectSetInteger(0, "BotStatusLabel", OBJPROP_XDISTANCE, 10);
    ObjectSetInteger(0, "BotStatusLabel", OBJPROP_YDISTANCE, 10);
    ObjectSetInteger(0, "BotStatusLabel", OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, "BotStatusLabel", OBJPROP_FONTSIZE, 14);
  }

  // Update the text label with the bot status
  if (isBotRunning)
  {
    ObjectSetString(0, "BotStatusLabel", OBJPROP_TEXT, "Hello World");
  }
  else
  {
    ObjectSetString(0, "BotStatusLabel", OBJPROP_TEXT, "Hello World");
    
  }
}

// Define a function to handle chart events
void OnChartEvent(const int id,
                  const long& lparam,
                  const double& dparam,
                  const string& sparam)
{
  // If the custom event occurs
  if (id == BOT_STATUS_EVENT)
  {
    // Toggle the bot status
    isBotRunning = !isBotRunning;

    // Show the bot status on the chart
    ShowBotStatus();
  }
}

