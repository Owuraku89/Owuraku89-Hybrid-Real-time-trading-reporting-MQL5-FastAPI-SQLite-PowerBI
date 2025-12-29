//+------------------------------------------------------------------+
//|                                                     MA_cross.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Trade\Trade.mqh>
#include <Trade\Dealinfo.mqh>
#include <MQLPostRequest.mqh>

//---input variables
string name = "MA cross EA";
// indicator Parameters
input uint fastPeriod = 14; 
input uint slowPeriod = 21;
input ENUM_APPLIED_PRICE appliedPrice = PRICE_CLOSE;
input ENUM_MA_METHOD indicatorMode = MODE_SMA;

// Glorabal Variables "Trader class" 
input double openVolume = 0.1;
input int openDeviation = 40;
input int stop = 25;
input int take = 50;

// Global variables "indicator"
int fastHandle;
int slowHandle;

double fastMABuffer[], slowMABuffer[];


CTrade trade;
CDealInfo deal;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---display omment
   Comment(name);
   
//---set properties for indicators
   fastHandle = iMA(_Symbol, PERIOD_CURRENT, fastPeriod, 0, indicatorMode, appliedPrice);
   slowHandle = iMA(_Symbol, PERIOD_CURRENT, slowPeriod, 0, indicatorMode, appliedPrice);
   
   ArraySetAsSeries(fastMABuffer, true);
   ArraySetAsSeries(slowMABuffer, true);
   
   
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---REMOVE comment
   Comment("");
   
   if(fastHandle != INVALID_HANDLE && slowHandle != INVALID_HANDLE)
     {
         IndicatorRelease(fastHandle);
         IndicatorRelease(slowHandle);
     }
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---get values into buffer array
   CopyBuffer(fastHandle, 0, 0, 2, fastMABuffer);
   CopyBuffer(slowHandle, 0, 0, 2, slowMABuffer);
   
//---set trade parameter
   bool hasPosition = PositionSelect(_Symbol);
   double posVolume = 0;
   ulong posType = POSITION_TYPE;
   ulong ticket = 0; ;
   if(hasPosition)
     {
         posType = PositionGetInteger(POSITION_TYPE);
         posVolume = PositionGetDouble(POSITION_VOLUME);
         ticket = PositionGetInteger(POSITION_TICKET);
     }
   
//---set trade logic
   double buy = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double sell = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double sl, tp;
   if(fastMABuffer[1] <= slowMABuffer[1] && fastMABuffer[0] > slowMABuffer[0] )
     {
         //---close any sell position 
         if(hasPosition && posType == POSITION_TYPE_SELL)
           {
               trade.PositionClose(ticket, openDeviation);
               hasPosition = false;
           //---place buy order
           }
         if(!hasPosition)
           {
               sl = buy - (stop * SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 10);
               tp = buy + (take * SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 10);
               trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, openVolume, buy, sl ,tp, "buy");
           }
     }
     
     //---conditions  for sell
     if(fastMABuffer[1] >= slowMABuffer[1] && fastMABuffer[0] < slowMABuffer[0] )
       {
         //---close any buy postion
         if(hasPosition && posType == POSITION_TYPE_BUY)
           {
               trade.PositionClose(ticket, openDeviation);
               hasPosition = false;
           }
          
          //---sell order
          if(!hasPosition)
            {
               sl = sell + (stop * SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 10);
               tp = sell - (take * SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 10);
               trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, openVolume, sell, sl, tp, "sell");
            }
       }
   
   
  }
//  Send trade report
  void OnTrade(void)
    {
      Print("Trade Triggered");
      
      //---define variables
      string symbol;
      string dealType;
      double entryPrice = 0.0;
      double volume;
      datetime entryTime = 0;
      
      //for updating deals 
      ulong ticketOld = 0; 
      double exitPrice;
      double profit;
      datetime exitTime = WRONG_VALUE;
      
      //---realitime trade upload
      HistorySelect(0, TimeCurrent());     
      //---extract details from deal
      if(HistoryDealsTotal() > 0)
        {
            int latestDealIndex = (HistoryDealsTotal() - 1);
            ulong ticket = HistoryDealGetTicket(latestDealIndex);
      
            //---select active deal by ticket
            deal.Ticket(ticket);
            ulong postionID = deal.PositionId();
            if(deal.Entry() == DEAL_ENTRY_IN)
              {
                  //---BUY OR SELL dealtype
                  symbol = deal.Symbol();
                  entryPrice = deal.Price();
                  volume = deal.Volume();
                  dealType = deal.TypeDescription(); //Buy or Sell
                  entryTime = deal.Time(); 
                  
                  bool sent = SendTradeReport(postionID, ticket, symbol, dealType, volume, entryPrice, entryTime, "OPEN");
                  Print("SendTradeReport OPEN returned: ", sent);
                  return;
              }
            
               //---UPDATE closing deal
               else if(deal.Entry() == DEAL_ENTRY_OUT)
                  {
                     ulong searchTicket;
                     //---search history for postionID match by 'backwards means for faster reccent trades'
                     for(int i=HistoryDealsTotal() - 1; i >= 0; i--)
                       {
                           searchTicket = HistoryDealGetTicket(i);
                           if(HistoryDealGetInteger(searchTicket, DEAL_POSITION_ID) == postionID)
                             {
                                 entryPrice = HistoryDealGetDouble(searchTicket, DEAL_PRICE);
                                 ticketOld = searchTicket;
                                 dealType = deal.TypeDescription();
                                 entryTime = datetime(HistoryDealGetInteger(searchTicket, DEAL_TIME));
                             }
                       }
                     symbol = deal.Symbol();
                     volume = deal.Volume();
                     exitTime = deal.Time();
                     exitPrice = deal.Price();
                     profit = deal.Profit();
                     
                     bool sent = SendTradeReport(postionID, ticketOld, symbol, dealType, volume, entryPrice, entryTime, "CLOSED", exitPrice, exitTime, profit);
                     Print("SendTradeReport CLOSED returned: ", sent);
                     return;
              }
          
        }
        else
          {
            Print("No deals Found");
            return;
          }      
    }
//+------------------------------------------------------------------+
