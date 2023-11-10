// Include the Trade library
#include <Trade\Trade.mqh>

// Create a trade object
CTrade trade;

// Define constants
#define LOT_SIZE 1.0         // Lot size for trading
    
#define CRASH_SYMBOL "Crash" // Symbol for crash market
#define BOOM_SYMBOL "Boom"   // Symbol for boom market

// Declare global variables
double previous_tick = 0; // Previous tick price
double current_tick = 0;  // Current tick price
ulong last_trade_id = 0;  // Last trade ID
ulong chart_id = 0;       // Chart ID
bool has_open_position = false;

ulong deal_ticket = 0;



double lot_size = 0.2;
double min_allowed_lot = 0;
input double STOP_LOSS = 20.0; // The percentage of the current price to set as stop loss
input double TAKE_PROFIT = 20.0; // The percentage of the current price to set as take profit
input double USER_LOT_SIZE = 0.2; // The lot size for trading

double base_lot = 0;
int customIndicatorHandle;

// Initialization function
int OnInit()
{
    Print("Initialization");
    previous_tick = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    min_allowed_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    if (lot_size < min_allowed_lot){
      base_lot = min_allowed_lot ;
    }else{
      base_lot = USER_LOT_SIZE ;
    }
    base_lot = min_allowed_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    lot_size = base_lot ;
    last_trade_id = 0;
    chart_id = ChartID(); // Get the current chart ID
    Comment("Stop Loss: ", STOP_LOSS, "%\n",
        "Take Profit: ", TAKE_PROFIT, "%\n",
        "Lot Size: ", lot_size);
    customIndicatorHandle = iCustom(_Symbol,PERIOD_M5,"Market\\TrendCatcher.ex5");
    

    // Check if the indicator loaded successfully
    if (customIndicatorHandle == INVALID_HANDLE)
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
    
    if(upTrend[0] != 1.7976931348623157e+308){
       Comment("Uptrend Value: " ,upTrend[0]);
    }else if(downTrend[0]!= 1.7976931348623157e+308){
       Comment("DownTrend Value: " ,downTrend[0]);
    }else{
       Comment("Unknown Trend");
    }
    
    
    

    if (is_new_bar()) // Check if a new bar has formed
    {
        current_tick = SymbolInfoDouble(_Symbol, SYMBOL_BID); // Get the current bid price
        bool open_trade = PositionSelect(_Symbol);

        // Check if an open position exists
        if (open_trade)
            return;

        // Check if the current tick is lower than the previous tick and the symbol is crash
        if (current_tick < previous_tick && StringFind(_Symbol, CRASH_SYMBOL) != -1 && open_trade == false && upTrend[0] != 1.7976931348623157e+308)
        {
            // Buy with lot size, stop loss, and take profit
            

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
        else if (current_tick > previous_tick && StringFind(_Symbol, BOOM_SYMBOL) != -1 && open_trade == false && downTrend[0] != 1.7976931348623157e+308)
        {
            // Sell with lot size, stop loss, and take profit

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
         
      else if(profit<0){
         
          PrintFormat("The last deal for %s was unprofitable: %.2f",_Symbol,profit);
          lot_size *= 2;
          
      }
        
      
    }
}
