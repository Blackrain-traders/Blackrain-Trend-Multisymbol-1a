//+------------------------------------------------------------------+
//|                                                    my_oop_ea.mq5 |
//|                        Copyright 2010, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+

//ESTAMOS PROBANDO GIT

#property copyright "Copyright 2010, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
// Include  our class
#include <my_expert_class.mqh>
//--- input parameters
input int      StopLoss=30;      // Stop Loss
input int      TakeProfit=100;   // Take Profit
input int      ADX_Period=14;    // ADX Period
input int      MA_Period=10;     // Moving Average Period
input int      EA_Magic=12345;   // EA Magic Number
input double   Adx_Min=22.0;     // Minimum ADX Value
input double   Lot=0.2;          // Lots to Trade
input int      Margin_Chk=0;     // Check Margin before placing trade(0=No, 1=Yes)
input double   Trd_percent=15.0; // Percentage of Free Margin To use for Trading
//--- other parameters
int STP,TKP;   // To be used for Stop Loss & Take Profit values
//--- create an object of our class
MyExpert Cexpert;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- run Initialize function
   Cexpert.doInit(ADX_Period,MA_Period);
//--- set all other necessary variables for our class object
   Cexpert.setPeriod(_Period);    // sets the chart period/timeframe
   Cexpert.setSymbol(_Symbol);    // sets the chart symbol/currency-pair
   Cexpert.setMagic(EA_Magic);    // sets the Magic Number
   Cexpert.setadxmin(Adx_Min);    // sets the ADX miniumm value
   Cexpert.setLOTS(Lot);          // set the Lots value
   Cexpert.setchkMAG(Margin_Chk); // set the margin check variable
   Cexpert.setTRpct(Trd_percent); // set the percentage of Free Margin for trade
//--- let us handle brokers that offers 5 digit prices instead of 4
   STP = StopLoss;
   TKP = TakeProfit;
   if(_Digits==5)
     {
      STP = STP*10;
      TKP = TKP*10;
     }
//---
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- Run UnIntilialize function
   Cexpert.doUninit();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- do we have enough bars to work with
   int Mybars=Bars(_Symbol,_Period);
   if(Mybars<60) // if total bars is less than 60 bars
     {
      Alert("We have less than 60 bars, EA will now exit!!");
      return;
     }

//--- define some MQL5 Structures we will use for our trade
   MqlTick latest_price;      // To be used for getting recent/latest price quotes
   MqlRates mrate[];          // To be used to store the prices, volumes and spread of each bar
/*
     Let's make sure our arrays values for the Rates
     is store serially similar to the timeseries array
*/
//--- the rates arrays
   ArraySetAsSeries(mrate,true);

//--- Get the last price quote using the MQL5 MqlTick Structure
   if(!SymbolInfoTick(_Symbol,latest_price))
     {
      Alert("Error getting the latest price quote - error:",GetLastError(),"!!");
      return;
     }

//--- get the details of the latest 3 bars
   if(CopyRates(_Symbol,_Period,0,3,mrate)<0)
     {
      Alert("Error copying rates/history data - error:",GetLastError(),"!!");
      return;
     }

//--- EA should only check for new trade if we have a new bar
//--- lets declare a static datetime variable
   static datetime Prev_time;
//--- lets declare a datetmie variable to hold the start time for the current bar (Bar 0)
   datetime Bar_time[1];

//--- copy the start time of the new bar to the variable
   Bar_time[0]=mrate[0].time;
//--- we don't have a new bar when both times are the same
   if(Prev_time==Bar_time[0])
     {
      return;
     }
//--- copy time to static value, save
   Prev_time=Bar_time[0];

//--- we have no errors, so continue
//--- do we have positions opened already?
   bool Buy_opened=false,Sell_opened=false; // variables to hold the result of the opened position

   if(PositionSelect(_Symbol)==true) // we have an opened position
     {
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
        {
         Buy_opened=true;  //It is a Buy
        }
      else if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
        {
         Sell_opened=true; // It is a Sell
        }
     }
//--- copy the bar close price for the previous bar prior to the current bar, that is Bar 1
   Cexpert.setCloseprice(mrate[1].close);  // bar 1 close price
//--- check for Buy position
   if(Cexpert.checkBuy()==true)
     {
      //--- do we already have an opened buy position
      if(Buy_opened)
        {
         Alert("We already have a Buy Position!!!");
         return;    // Don't open a new Buy Position
        }
      double aprice = NormalizeDouble(latest_price.ask,_Digits);              // current Ask price
      double stl    = NormalizeDouble(latest_price.ask - STP*_Point,_Digits); // Stop Loss
      double tkp    = NormalizeDouble(latest_price.ask + TKP*_Point,_Digits); // Take profit
      int    mdev   = 100;                                                    // Maximum deviation
                                                                              // place order
      Cexpert.openBuy(ORDER_TYPE_BUY,aprice,stl,tkp,mdev);
     }
//--- check for any Sell position
   if(Cexpert.checkSell()==true)
     {
      //--- do we already have an opened Sell position
      if(Sell_opened)
        {
         Alert("We already have a Sell position!!!");
         return;    // Don't open a new Sell Position
        }
      double bprice=NormalizeDouble(latest_price.bid,_Digits);                 // Current Bid price
      double bstl    = NormalizeDouble(latest_price.bid + STP*_Point,_Digits); // Stop Loss
      double btkp    = NormalizeDouble(latest_price.bid - TKP*_Point,_Digits); // Take Profit
      int    bdev=100;                                                         // Maximum deviation
                                                                               // place order
      Cexpert.openSell(ORDER_TYPE_SELL,bprice,bstl,btkp,bdev);
     }

   return;
  }
//+------------------------------------------------------------------+
