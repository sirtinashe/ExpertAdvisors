// Include the Trade library
#include <Trade\Trade.mqh>

CTrade trade;



#define VOLATILITY_SYMBOL "Volatility"

double current_tick = 0;
ulong last_trade_id = 0;
ulong chart_id = 0;

ulong deal_ticket = 0;

double lot_size = 0.2;
double min_allowed_lot = 0;
input double STOP_LOSS = 10000.0;
input double TAKE_PROFIT = 10000.0;
input double USER_LOT_SIZE = 0.2;
input int ATR_Period = 14;              

input double stop_loss_multiplier = 2.0;   // Stop loss multiplier
input double take_profit_multiplier = 2.0; // Take profit multiplier
double base_lot = 0;
int customIndicatorHandle;
int ATR_Handle;
double symbolPoint ;
bool open_position = false;
datetime opened_at ;
datetime checking_time ;
ENUM_TIMEFRAMES period = PERIOD_H1;
int OnInit()

{  
    
   
    symbolPoint = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    opened_at = iTime(_Symbol,period , 0);
    
    checking_time = iTime(_Symbol, period, 0);
    Print("Symbol Points ",symbolPoint);
    ATR_Handle = iATR(_Symbol, period, ATR_Period);
    if (ATR_Handle == INVALID_HANDLE)
    {
        Print("Failed to initialize ATR indicator handle");
        return (INIT_FAILED);
    }
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    Print("Initialization ");

    min_allowed_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    if (lot_size < min_allowed_lot)
    {
        base_lot = min_allowed_lot;
    }
    else
    {
        base_lot = USER_LOT_SIZE;
    }
    base_lot = min_allowed_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    lot_size = base_lot;
    last_trade_id = 0;
    chart_id = ChartID(); // Get the current chart ID
    Comment("Stop Loss: ", STOP_LOSS, "%\n",
            "Take Profit: ", TAKE_PROFIT, "%\n",
            "Lot Size: ", lot_size);
    customIndicatorHandle = iCustom(_Symbol, period, "Market\\TrendCatcher.ex5");

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
        return;
        
    checking_time = iTime(_Symbol, period, 0);
    double upTrendArrow[];
    double downTrendArrow[];
    double ATR_Value[];
    CopyBuffer(customIndicatorHandle, 2, 0, 1, upTrendArrow);
    CopyBuffer(customIndicatorHandle, 3, 0, 1, downTrendArrow);
    CopyBuffer(ATR_Handle, 0, 0, 1, ATR_Value);

    if (upTrendArrow[0] != 1.7976931348623157e+308)
    {
        Comment("Buy Sygnal", upTrendArrow[0]);
    }
    else if (downTrendArrow[0] != 1.7976931348623157e+308)
    {
        Comment("Sell Signal", downTrendArrow[0]);
    }
    else
    {
        Comment("No Buy/Sell Signal Available ",downTrendArrow[0] ," ",upTrendArrow[0]);
    }

        if ( upTrendArrow[0] != 1.7976931348623157e+308){
       // StringFind(_Symbol, VOLATILITY_SYMBOL) != -1 &&
        if (checking_time!= opened_at)
        {   
            checking_time = iTime(_Symbol, period, 0);
            trade.PositionClose(_Symbol);
            current_tick = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
           
            
            //double stopLossPrice = current_tick - (STOP_LOSS * symbolPoint);
            //double takeProfitPrice = current_tick + (TAKE_PROFIT * symbolPoint);
            
            double stop_loss = current_tick - (ATR_Value[0] * stop_loss_multiplier);
            double take_profit = current_tick + (ATR_Value[0] * take_profit_multiplier);
            trade.Buy(lot_size, _Symbol, current_tick, stop_loss, take_profit);
            
            deal_ticket = trade.ResultDeal();
            Print("Bought: ", _Symbol, " ", deal_ticket);
           
            opened_at = iTime(_Symbol,period, 0);
        }
    }

    else if ( downTrendArrow[0] != 1.7976931348623157e+308)
    {
    //StringFind(_Symbol, VOLATILITY_SYMBOL) != -1 &&
       
        if (opened_at != checking_time){
             checking_time = iTime(_Symbol, period, 0);
             trade.PositionClose(_Symbol);
             current_tick = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            
            
            //double stopLossPrice = current_tick + (STOP_LOSS * symbolPoint);
            //double takeProfitPrice = current_tick - (TAKE_PROFIT * symbolPoint);
            double stop_loss = current_tick + (ATR_Value[0] * stop_loss_multiplier);
            double take_profit = current_tick - (ATR_Value[0] * take_profit_multiplier);
            trade.Sell(lot_size, _Symbol, current_tick, stop_loss, take_profit);
            deal_ticket = trade.ResultDeal();

            Print("Sold: ", _Symbol, " ", deal_ticket);
            opened_at = iTime(_Symbol, period, 0);
            
        }
    }
}

void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{

    if (trans.symbol == _Symbol && trans.deal != 0)
    {
       open_position = false;

        bool history = HistoryDealSelect(trans.deal);
        double profit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT); //---
        double closingPrice = HistoryDealGetDouble(trans.deal, DEAL_PRICE);

        if (profit > 0)
        {
            PrintFormat("The last deal for %s was profitable: %.2f", _Symbol, profit);
        }

        else if (profit < 0)
        {

            PrintFormat("The last deal for %s was unprofitable: %.2f", _Symbol, profit);
        }
    }
}

bool is_new_bar()
{
    
    datetime current_time = iTime(_Symbol,period, 0);

    static datetime prior_time = current_time;
    //Print("Previous Time ", prior_time);
    //Print("Current Time: ", current_time);
    bool result = (current_time != prior_time);
    //Print("New Bar ", result);//---
    
    prior_time = current_time;
    return (result);
}
