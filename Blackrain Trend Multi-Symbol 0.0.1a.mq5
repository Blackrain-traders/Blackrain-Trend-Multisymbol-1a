//+-------------------------------------------+
//|                      Blackrain Trend      |
//|                 Property of: Elio Pajares |
//|                   v0.0.3b  06 - 10 - 2020 |
//+-------------------------------------------+
#property description "Blackrain Trend 0.0.1a"
#property copyright   "Copyright © 2020, Elio Pajares"
//#property link        "http://www.blackrainalgo.com"
#property strict

//##############################################
//## Walk Forward Pro Import Start (for MQL5) ##
//##############################################

#property tester_file "Walk Forward Pro\\WFA Control Files\\InitiatedFromWFP.ctl"
#property tester_file "Walk Forward Pro\\WFA Control Files\\StageIterationDetails.txt"
#property tester_file "Walk Forward Pro\\WFA Control Files\\OptPassCounter.ctl"

#import "TSMWFP.ex5"
void WFA_Initialise();
void WFA_UpdateValues();
void WFA_PerformCalculations(double &dCustomPerformanceCriterion);
void WFA_OnTesterInit();
void WFA_OnTesterDeinit();
#import

//############################################
//## Walk Forward Pro Import End (for MQL5) ##
//############################################

//#include <Trade\Trade.mqh>

//#define BID SymbolInfoDouble(_Symbol,SYMBOL_BID) 
//#define ASK SymbolInfoDouble(_Symbol,SYMBOL_ASK)

#include <StdLibErr.mqh>

//INPUTS
input string   TradeSymbols         = "AUDUSD|EURUSD";   //Symbol(s) or ALL or CURRENT
input int      BBandsPeriods        = 20;       //Bollinger Bands Periods
input double   BBandsDeviations     = 1.0;      //Bollinger Bands Deviations
input int    magic_number  = 12345 ; //change magic number when same EA used in the same account to avoid overlap issues with open orders
//input string pair          = "EURUSD"; //currency pair

extern string data_1 = "==== SL, TP, TS ====";
input bool   AllowOrders   = false;
input int    orders        = 1;
input double StopLoss      = 20; // SL is used Lotsize calculation via % balance at risk
input double TakeProfit    = 40; // TP is unlimited
input bool   trailing      = true; //
input double TrailingStop  = 20; //
input int    spread        = 2; // value in points
//input int    time_between_trades = 900; //value in seconds of the time between a loss trade and a new one,  -1 for not using this

extern string data_2 = "==== Invalidation of trade setup ====";
input bool   invalidation_trade = true; //
input int rsi_inv_upper    = 10;
input int rsi_inv_lower    = 90;
input int stoch_inv_upper  = 80;
input int stoch_inv_lower  = 20;
input int pips_invalidation= 5;
input bool CloseOnDuration = true;
input int MaxDurationHours = 8; //in hours
input int MaxDurationMin   = 0; //in minutes
input bool CloseFridays    = true;
input bool retrace         = false;
input double PipsStick     = 40;
input double PipsRetrace   = 20;

extern string data_3 = "==== Money management ====";
input double  Lots         = 0.1;
extern bool   MM           = true;
input double  Risk         = 2;
input double  maxlots      = 50;

extern string data_4 = "==== EMA parameters ====";
input int    EMA           = 200;
input int    EMA_Fast      = 100;
input int    EMA_Slow      = 200;
input int    macd_signal   = 50;
input ENUM_TIMEFRAMES MA_TF = PERIOD_H1;
input int    MA_count      = 8;
input int    MA_Period_H1  = 7;
input double SAR_accel_D1  = 0.02;
input double SAR_accel_H4  = 0.04;
//input ENUM_TIMEFRAMES Period_SAR = PERIOD_H1;

extern string data_5 = "==== RSI parameters ====";
input int    RSIperiod      = 7; //RSI period
input int    RSIUpper       = 70; // RSI Upper limit
input int    RSILower       = 30; // RSI Lower limit

extern string data_6 = "==== Stochastic parameters ====";
input int    KPeriod        = 14; // K Period
input int    DPeriod        = 7; // D Period
input int    Slowing        = 9;  // Slowing value
input int    StochUpper     = 70; // Stochastic Upper limit
input int    StochLower     = 30; // Stochastic Lower limit

extern string data_7 = "==== Days to Trade ====";
input bool   Sunday         = true;
input bool   Monday         = true;
input bool   Tuesday        = true;
input bool   Wednesday      = true;
input bool   Thursday       = true;
input bool   Friday         = true;

extern string data_8 = "==== Hours to Trade ====";
input int    StartHourTrade = 8; // 0 for beginning of the day
input int    EndHourTrade   = 22; // 23 for end of the day

extern string data_9 = "==== Days to Trade ====";
input bool   January        = true;
input bool   February       = true;
input bool   March          = true;
input bool   April          = true;
input bool   May            = true;
input bool   June           = true;
input bool   July           = true;
input bool   August         = true;
input bool   September      = true;
input bool   October        = true;
input bool   November       = true;
input bool   December       = true;

//GENERAL GLOBALS   
string   AllSymbolsString           = "AUDCAD|AUDJPY|AUDNZD|AUDUSD|CADJPY|EURAUD|EURCAD|EURGBP|EURJPY|EURNZD|EURUSD|GBPAUD|GBPCAD|GBPJPY|GBPNZD|GBPUSD|NZDCAD|NZDJPY|NZDUSD|USDCAD|USDCHF|USDJPY";
int      NumberOfTradeableSymbols;              
string   SymbolArray[];                        
int      TicksReceivedCount         = 0;

int Slippage = 3;
int vSlippage;
int orderticket;
int total_positions;
int count_1,count_2;
int current_spread;
int a,aa;
int LotDigits = 2;
   


double vPoint; 
//double ma,ma_ema;


//INDICATOR HANDLES
int handle_BollingerBands[];  
int ma_M5_handle;
int ma_H1_handle;
int rsi_M5_handle;
int rsi_H1_handle;
int stochastic_M5_handle;
int macd_H1_handle;
int SAR_Handle_H4[];
int SAR_Handle_D1[];
//Place additional indicator handles here as required 

//OPEN TRADE ARRAYS
ulong  OpenTradeOrderTicket[];    //To store 'order' ticket for trades
double ma_M5[], ma_H1[];
double rsi_M5[], rsi_H1[];
double stochastic_M5[];
double MACD_main[], MACD_signal[];
double SAR_H4[];
double SAR_D1[];
//Place additional trade arrays here as required to assist with open trade management

int OnInit()
{

   //## Walk Forward Pro OnInit() code start (MQL5) ##
   if(MQLInfoInteger(MQL_TESTER))
      WFA_Initialise();
   //## Walk Forward Pro OnInit() code end (MQL5) ##
   
   //CurrentTime= Time[0];

//+------------------------------------------------------------------+
//|  Detect 3/5 digit brokers for Point and Slippage                 |
//+------------------------------------------------------------------+
   
   //ARREGLAR ESTO PARA QUE SEA MULTISYMBOL, CAN BE DONE WITH A LOOP AND AN ARRAY, OTHERWISE CALCULATE IN OnTick())
//   if(_Point==0.00001)
//      { vPoint=0.0001; vSlippage=Slippage *10;}
//   else
//      {
//      if(_Point==0.001)
//        { vPoint=0.01; vSlippage=Slippage *10;}
//      else vPoint=_Point; vSlippage=Slippage;
//      }
//      
      
   if(TradeSymbols == "CURRENT")  //Override TradeSymbols input variable and use the current chart symbol only
   {
      NumberOfTradeableSymbols = 1;
      
      ArrayResize(SymbolArray, 1);
      SymbolArray[0] = Symbol(); 

      Print("EA will process ", SymbolArray[0], " only");
   }
   else
   {  
      string TradeSymbolsToUse = "";
      
      if(TradeSymbols == "ALL")
         TradeSymbolsToUse = AllSymbolsString;
      else
         TradeSymbolsToUse = TradeSymbols;
      
      //CONVERT TradeSymbolsToUse TO THE STRING ARRAY SymbolArray
      NumberOfTradeableSymbols = StringSplit(TradeSymbolsToUse, '|', SymbolArray);
      
      Print("EA will process: ", TradeSymbolsToUse);
   }
   
   //RESIZE OPEN TRADE ARRAYS (based on how many symbols are being traded)
   ResizeCoreArrays();
   
   //RESIZE INDICATOR HANDLE ARRAYS
   ResizeIndicatorHandleArrays();
   
   Print("All arrays sized to accomodate ", NumberOfTradeableSymbols, " symbols");
   
   //INITIALIZE ARAYS
   //for(int SymbolLoop=0; SymbolLoop < NumberOfTradeableSymbols; SymbolLoop++)
      //OpenTradeOrderTicket[SymbolLoop] = 0;
   
   //INSTANTIATE INDICATOR HANDLES
   if(!SetUpIndicatorHandles())
      return(INIT_FAILED); 
   
   return(INIT_SUCCEEDED);     
}

void OnDeinit(const int reason)
{
   Comment("\n\rMulti-Symbol EA Stopped");
}

void OnTick()
   {

   //## Walk Forward Pro OnTick() code start (MQL5) ##
   if(MQLInfoInteger(MQL_TESTER))
      WFA_UpdateValues();
   //## Walk Forward Pro OnTick() code end (MQL5) ##
   
   
   if(_Point==0.00001)
      { vPoint=0.0001; vSlippage=Slippage *10;}
   else
      {
      if(_Point==0.001)
        { vPoint=0.01; vSlippage=Slippage *10;}
      else vPoint=_Point; vSlippage=Slippage;
      }
   
   TicksReceivedCount++;
   string indicatorMetrics = "";
   
   //LOOP THROUGH EACH SYMBOL TO CHECK FOR ENTRIES AND EXITS, AND THEN OPEN/CLOSE TRADES AS APPROPRIATE
   for(int SymbolLoop = 0; SymbolLoop < NumberOfTradeableSymbols; SymbolLoop++)
      {
      //string CurrentIndicatorValues; //passed by ref below
      
      string CurrentSymbol = SymbolArray[SymbolLoop];
      
      current_spread = (int)SymbolInfoInteger(CurrentSymbol, SYMBOL_SPREAD);
      
      total_positions=CountOrder_symbol_magic(CurrentSymbol);
      
      double BID = SymbolInfoDouble(CurrentSymbol,SYMBOL_BID);
      double ASK = SymbolInfoDouble(CurrentSymbol,SYMBOL_ASK);
      
      //if(NewBar(CurrentSymbol)==true && AllowOrders==true && current_spread<=spread && OpenTradeOrderTicket[SymbolLoop] == 0)
      if(total_positions<orders && NewBar(CurrentSymbol)==true && AllowOrders==true && current_spread<=spread)
         {



         if(CopyBuffer(SAR_Handle_H4[SymbolLoop],0,0,2,SAR_H4) < 0)
            {
            //if the copying fails, tell the error code
            PrintFormat("Failed to copy data from the SAR indicator, error code %d",GetLastError());
            // quit with zero result - it means that the indicator is considered as not calculated
            }
            
         if(CopyBuffer(SAR_Handle_D1[SymbolLoop],0,0,2,SAR_D1) < 0)
            {
            //if the copying fails, tell the error code
            PrintFormat("Failed to copy data from the SAR indicator, error code %d",GetLastError());
            // quit with zero result - it means that the indicator is considered as not calculated
            }   
         
         double high_D1_0 = iHigh(CurrentSymbol,PERIOD_D1,0);
         double high_D1_1 = iHigh(CurrentSymbol,PERIOD_D1,1);
         double low_D1_0 = iLow(CurrentSymbol,PERIOD_D1,0);
         double low_D1_1 = iLow(CurrentSymbol,PERIOD_D1,1);
            
         double high_H4_0 = iHigh(CurrentSymbol,PERIOD_H4,0);
         double high_H4_1 = iHigh(CurrentSymbol,PERIOD_H4,1);
         double low_H4_0 = iLow(CurrentSymbol,PERIOD_H4,0);
         double low_H4_1 = iLow(CurrentSymbol,PERIOD_H4,1);
         
         datetime time_1 = iTime(CurrentSymbol,PERIOD_H4,1);
         datetime time_2 = iTime(CurrentSymbol,PERIOD_H4,2);
         

         
         //--- check for BUY position
      
         
         if(SAR_D1[1]<low_D1_0 && SAR_H4[0]>high_H4_1 && SAR_H4[1]<low_H4_0)
            {
            //--- declare and initialize the trade request and result of trade request
            
            MqlTradeRequest request={0};
            MqlTradeResult  result={0};
            
            ASK = SymbolInfoDouble(CurrentSymbol,SYMBOL_ASK);
             
            request.action   = TRADE_ACTION_DEAL;                     // type of trade operation
            request.symbol   = CurrentSymbol;                              // symbol
            //request.volume   = GetLots(SAR_H4[0],CurrentSymbol);                             // calculated lots
            request.volume   = 0.1;                             // calculated lots
            request.type     = ORDER_TYPE_BUY;                        // order type
            request.price    = SymbolInfoDouble(CurrentSymbol,SYMBOL_ASK); // price for opening
            request.deviation= 3;                                     // allowed deviation from the price
            //request.sl       = ASK-StopLoss*vPoint;
            request.sl       = SAR_H4[1];
            request.tp       = ASK+TakeProfit*vPoint;
            request.magic    = magic_number;                          // MagicNumber of the order
            request.comment  = "Blackrain Trend 0.0.1a";
            
            if(!OrderSend(request,result))
               PrintFormat("OrderSend error %d",GetLastError());     // if unable to send the request, output the error code
            //--- information about the operation
            PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
            
            //OpenTradeOrderTicket[SymbolLoop] = result.order;
            }      
         
         //--- check for SELL position
         
         
         if(SAR_D1[1]>high_D1_0 && SAR_H4[0]<low_H4_1 && SAR_H4[1]>high_H4_0)
            {
            //--- declare and initialize the trade request and result of trade request
            MqlTradeRequest request={0};
            MqlTradeResult  result={0};
            
            BID = SymbolInfoDouble(CurrentSymbol,SYMBOL_BID);
            
            //--- parameters of request
            request.action   = TRADE_ACTION_DEAL;                     // type of trade operation
            request.symbol   = CurrentSymbol;                              // symbol
            //request.volume   = GetLots(SAR_H4[0],CurrentSymbol);                             // calculated lots
            request.volume   = 0.1;                             // calculated lots
            request.type     = ORDER_TYPE_SELL;                       // order type
            request.price    = SymbolInfoDouble(CurrentSymbol,SYMBOL_BID); // price for opening
            request.deviation= 3;                                     // allowed deviation from the price
            //request.sl       = BID+StopLoss*vPoint;
            request.sl       = SAR_H4[1];
            request.tp       = BID-TakeProfit*vPoint;
            request.magic    = magic_number;                          // MagicNumber of the order
            request.comment  = "Blackrain Trend 0.0.1";
         
            //--- send the request
            if(!OrderSend(request,result))
               PrintFormat("OrderSend error %d",GetLastError());     // if unable to send the request, output the error code
            //--- information about the operation
            PrintFormat("retcode=%u  deal=%I64u  order=%I64u  ticket=%I64u",result.retcode,result.deal,result.order);
            
            //OpenTradeOrderTicket[SymbolLoop] = result.order;
            } 
         return;
         }

//+------------------------------------------------------------------+
//| MANAGE OPEN ORDERS: TRAILING & BREAKEVEN                         |
//+------------------------------------------------------------------+   
   
         // Trailing stop  IDEA: PARTIAL CLOSE WHEN PRICE MOVE TrailingStop VALUE
      //if(trailing == true && OpenTradeOrderTicket[SymbolLoop] != 0 && NewBar(CurrentSymbol)==true)
      if(trailing == true && CountOrder_symbol_magic(CurrentSymbol)>0 && NewBar(CurrentSymbol)==true)
         {
         if(CopyBuffer(SAR_Handle_H4[SymbolLoop],0,0,1,SAR_H4) < 0)
            {
            //if the copying fails, tell the error code
            PrintFormat("Failed to copy data from the SAR indicator, error code %d",GetLastError());
            // quit with zero result - it means that the indicator is considered as not calculated
            }
            
            //TS_pips();
            //TS_SAR(SAR[0]);
            //TS_SAR();
         
         MqlTradeRequest request = {0};
         MqlTradeResult  result = {0};  

         for(int cnt=PositionsTotal()-1; cnt>=0; cnt--)
            {
            ulong position_ticket=PositionGetTicket(cnt);
            string position_symbol = PositionGetString(POSITION_SYMBOL);
            ulong magic = PositionGetInteger(POSITION_MAGIC);
            ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
            double sl = PositionGetDouble(POSITION_SL);
            double tp = PositionGetDouble(POSITION_TP);
            double tickSize = SymbolInfoDouble(CurrentSymbol, SYMBOL_TRADE_TICK_SIZE);
            int digits = (int)SymbolInfoInteger(CurrentSymbol,SYMBOL_DIGITS);
            
            double new_sl = NormalizeDouble(SAR_H4[0],digits);
            //double new_sl = round((BID-TrailingStop*vPoint)/tickSize)*tickSize;
   
            //if(type==POSITION_TYPE_BUY && position_symbol==_Symbol && magic==magic_number)
            //if(type==POSITION_TYPE_BUY && position_symbol==CurrentSymbol && magic==magic_number && SAR_H4[0]>sl)
            if(type==POSITION_TYPE_BUY && position_symbol==CurrentSymbol && magic==magic_number && new_sl>sl)
               {
               Print("Positionticket is: ",position_ticket);
               
               //double new_sl = round((BID-TrailingStop*vPoint)/tickSize)*tickSize;
               
               ZeroMemory(request);
               ZeroMemory(result);
                              
               request.action = TRADE_ACTION_SLTP;
               request.position = position_ticket;
               request.symbol = position_symbol;
               request.tp = tp;
               request.magic=magic;
               //request.sl = SAR_price;
               request.sl = NormalizeDouble(SAR_H4[0],digits);
              
               Print("current price= ",BID," / Open Price=",open_price," / current SL= ",sl," / New SL= ",request.sl);
               PrintFormat("Modify SL - ticket #%I64d %s %s",request.position,request.symbol,EnumToString(type));
               
               if(!OrderSend(request,result))
                  {
                  PrintFormat("OrderSend error %d on Trailing-SL",GetLastError(),"Position #",position_ticket);
                  }
                  
               PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
               return;
               }   
               
            //if(type==POSITION_TYPE_SELL && position_symbol==_Symbol && magic==magic_number)
            //if(type==POSITION_TYPE_SELL && position_symbol==CurrentSymbol && magic==magic_number && SAR_H4[0]<sl)
            if(type==POSITION_TYPE_SELL && position_symbol==CurrentSymbol && magic==magic_number && new_sl<sl)
               {
               Print("Positionticket is: ",position_ticket);
               
               //double new_sl = round((ASK+TrailingStop*vPoint)/tickSize)*tickSize;
      
               ZeroMemory(request);
               ZeroMemory(result);
                              
               request.action = TRADE_ACTION_SLTP;
               request.position = position_ticket;
               request.symbol = position_symbol;
               request.tp = tp;
               request.magic=magic;
               //request.sl = SAR_price;
               request.sl = NormalizeDouble(SAR_H4[0],digits);
              
               Print("current price= ",ASK," / Open Price=",open_price," / current SL= ",sl," / New SL= ",request.sl);
               PrintFormat("Modify SL - ticket #%I64d %s %s",request.position,request.symbol,EnumToString(type));
               
               if(!OrderSend(request,result))
                  {
                  PrintFormat("OrderSend error %d on Trailing-SL",GetLastError(),"Position #",position_ticket);
                  }
                  
               PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
               return;
               }
            }      
         }

//+------------------------------------------------------------------+
//| MANAGE OPEN ORDERS: INVALIDATION OF TRADES                       |
//+------------------------------------------------------------------+ 

      //if(OpenTradeOrderTicket[SymbolLoop] != 0 && NewBar(CurrentSymbol)==true)
      if(CountOrder_symbol_magic(CurrentSymbol)>0 && NewBar(CurrentSymbol)==true)
         {
         MqlTradeRequest request;
         MqlTradeResult result;
         
         for(int cnt=PositionsTotal()-1; cnt>=0; cnt--)
            {
            ulong position_ticket=PositionGetTicket(cnt);
            string position_symbol = PositionGetString(POSITION_SYMBOL);
            ulong magic = PositionGetInteger(POSITION_MAGIC);
            ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
            double sl = PositionGetDouble(POSITION_SL);
            double tp = PositionGetDouble(POSITION_TP);
            double tickSize = SymbolInfoDouble(CurrentSymbol, SYMBOL_TRADE_TICK_SIZE);
            double volume = PositionGetDouble(POSITION_VOLUME);
            datetime open_time = (datetime)PositionGetInteger(POSITION_TIME);
      
            if((type==POSITION_TYPE_BUY || type==POSITION_TYPE_SELL) && position_symbol==CurrentSymbol && magic==magic_number)
               {
               if(invalidation_trade==true)
                  {
                     
                  if(CopyBuffer(SAR_Handle_H4[SymbolLoop],0,0,2,SAR_H4) < 0)
                     {
                     PrintFormat("Failed to copy data from the Stochastic (closing) indicator, error code %d",GetLastError());
                     // quit with zero result - it means that the indicator is considered as not calculated
                     }
                  
                  double high_D1_0 = iHigh(CurrentSymbol,PERIOD_D1,0);
                  double high_D1_1 = iHigh(CurrentSymbol,PERIOD_D1,1);
                  double low_D1_0 = iLow(CurrentSymbol,PERIOD_D1,0);
                  double low_D1_1 = iLow(CurrentSymbol,PERIOD_D1,1);
                     
                  double high_H4_0 = iHigh(CurrentSymbol,PERIOD_H4,0);
                  double high_H4_1 = iHigh(CurrentSymbol,PERIOD_H4,1);
                  double low_H4_0 = iLow(CurrentSymbol,PERIOD_H4,0);
                  double low_H4_1 = iLow(CurrentSymbol,PERIOD_H4,1);
                   
                  //ma_10 = iMA(Symbol(), PERIOD_M5, 10, 0, 1, PRICE_CLOSE, 0);
                  //ma_20 = iMA(Symbol(), PERIOD_M5, 20, 0, 1, PRICE_CLOSE, 0);
   
                  // Close BUY trades if the setup is invalid
                  //if(rsi_M5[0]>=rsi_inv_upper && stochastic_M5[0]>=stoch_inv_upper && type==POSITION_TYPE_BUY && (BID-open_price)>pips_invalidation*vPoint)
                  if(SAR_H4[0]<low_H4_1 && SAR_H4[1]>high_H4_0 && type==POSITION_TYPE_BUY)
                     {
                     ZeroMemory(request);
                     ZeroMemory(result);
                     
                     request.action = TRADE_ACTION_DEAL;
                     request.position = position_ticket;
                     request.symbol = position_symbol;
                     request.volume = volume;
                     request.deviation = 3;
                     request.magic = magic;
                     request.price = SymbolInfoDouble(position_symbol,SYMBOL_BID);
                     request.type = ORDER_TYPE_SELL;
                     
                     PrintFormat("Invalidation of trade #%I64d %s %s by #%I64d",position_ticket,position_symbol,EnumToString(type),request.position);
                     
                     if(!OrderSend(request,result))
                        PrintFormat("OrderSend error %d on Invalidation of trade. ",GetLastError(),"Position #",position_ticket);
                        
                     PrintFormat("retcode=%u  deal=%I64u  order=I64u",result.retcode,result.deal,result.order);
                     
                     //OpenTradeOrderTicket[SymbolLoop] = 0;
                     
                     return;
                     }
                  
                  // Close SELL trades if the setup is invalid
                  //if(rsi_M5[0]<=rsi_inv_lower && stochastic_M5[0]<=stoch_inv_lower && type==POSITION_TYPE_SELL && (open_price-ASK)>pips_invalidation*vPoint)
                  if(SAR_H4[0]>high_H4_1 && SAR_H4[1]<low_H4_0 && type==POSITION_TYPE_SELL)
                     {
                     ZeroMemory(request);
                     ZeroMemory(result);
                     
                     request.action = TRADE_ACTION_DEAL;
                     request.position = position_ticket;
                     request.symbol = position_symbol;
                     request.volume = volume;
                     request.deviation = 3;
                     request.magic = magic;
                     request.price = SymbolInfoDouble(position_symbol,SYMBOL_ASK);
                     request.type = ORDER_TYPE_BUY;
                     
                     PrintFormat("Invalidation of trade #%I64d %s %s by #%I64d",position_ticket,position_symbol,EnumToString(type),request.position);
                     
                     if(!OrderSend(request,result))
                        PrintFormat("OrderSend error %d on Invalidation of trade. ",GetLastError(),"Position #",position_ticket);
                        
                     PrintFormat("retcode=%u  deal=%I64u  order=I64u",result.retcode,result.deal,result.order);
                     
                     //OpenTradeOrderTicket[SymbolLoop] = 0;
                     
                     return;
                     }
                  }   
                     
                  // Close trades due to their duration
               if(CloseOnDuration==true)
                  {
                  int MaxDuration = (MaxDurationHours * 60 * 60) + (MaxDurationMin * 60); //transform hours to seconds
                  datetime Duration = TimeCurrent() - open_time;

                  if(Duration>=MaxDuration) // add condition to be applied only is price is lower or higher than open price, check both situations!!
                     {
                     if(type==POSITION_TYPE_BUY && BID>open_price)
                        {
                        ZeroMemory(request);
                        ZeroMemory(result);
                        
                        request.action = TRADE_ACTION_DEAL;
                        request.position = position_ticket;
                        request.symbol = position_symbol;
                        request.volume = volume;
                        request.deviation = 3;
                        request.magic = magic;
                        request.price = SymbolInfoDouble(position_symbol,SYMBOL_BID);
                        request.type = ORDER_TYPE_SELL;
                        
                        PrintFormat("Close by duration %I64d %s %s by #%I64d",position_ticket,position_symbol,EnumToString(type),request.position_by);
                        
                        if(!OrderSend(request,result))
                           PrintFormat("OrderSend error %d on Close by duration. ",GetLastError(),"Position #",position_ticket);
                           
                        PrintFormat("retcode=%u  deal=%I64u  order=I64u",result.retcode,result.deal,result.order);
                        
                        //OpenTradeOrderTicket[SymbolLoop] = 0;
                        
                        return;
                        }
                     if(type==POSITION_TYPE_SELL && ASK<open_price)
                        {
                        ZeroMemory(request);
                        ZeroMemory(result);
                        
                        request.action = TRADE_ACTION_DEAL;
                        request.position = position_ticket;
                        request.symbol = position_symbol;
                        request.volume = volume;
                        request.deviation = 3;
                        request.magic = magic;
                        request.price = SymbolInfoDouble(position_symbol,SYMBOL_ASK);
                        request.type = ORDER_TYPE_BUY;
                        
                        PrintFormat("Close by duration %I64d %s %s by #%I64d",position_ticket,position_symbol,EnumToString(type),request.position_by);
                        
                        if(!OrderSend(request,result))
                           PrintFormat("OrderSend error %d on Close by duration. ",GetLastError(),"Position #",position_ticket);
                           
                        PrintFormat("retcode=%u  deal=%I64u  order=I64u",result.retcode,result.deal,result.order);
                        
                        //OpenTradeOrderTicket[SymbolLoop] = 0;
                        
                        return;
                        }   
                     }
                  }
               
               
               //Use retrace function to give the price a bit more room to operate. If a limit is exceeded, TP is used as nearby SL. The hard-SL is set on SL parameter
               if(retrace==true)
                  {
                  if(type==POSITION_TYPE_BUY && (open_price-BID)>vPoint*PipsStick && BID<open_price && tp>open_price)
                     {
                     ZeroMemory(request);
                     ZeroMemory(result);
                                    
                     request.action = TRADE_ACTION_SLTP;
                     request.position = position_ticket;
                     request.symbol = position_symbol;
                     request.tp = open_price-PipsRetrace*vPoint;
                     request.magic=magic;
                     request.sl = sl;
                    
                     Print("current price= ",BID," / Open Price=",open_price," / current SL= ",sl," / New SL= ",request.sl);
                     PrintFormat("Modify ticket #%I64d %s %s",request.position,request.symbol,EnumToString(type));
                     
                     if(!OrderSend(request,result))
                        {
                        PrintFormat("OrderSend error %d on Retrace. ",GetLastError(),"Position #",position_ticket);
                        }
                        
                     PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
                     //Print("RETRACE done");
                     return;
                     }
                  if(type==POSITION_TYPE_SELL && (ASK-open_price)>vPoint*PipsStick && ASK>open_price && tp<open_price)
                     {
                     ZeroMemory(request);
                     ZeroMemory(result);
                                    
                     request.action = TRADE_ACTION_SLTP;
                     request.position = position_ticket;
                     request.symbol = position_symbol;
                     request.tp = open_price+PipsRetrace*vPoint;
                     request.magic=magic;
                     request.sl = sl;
                    
                     Print("current price= ",ASK," / Open Price=",open_price," / current SL= ",sl," / New SL= ",request.sl);
                     PrintFormat("Modify ticket #%I64d %s %s",request.position,request.symbol,EnumToString(type));
                     
                     if(!OrderSend(request,result))
                        {
                        PrintFormat("OrderSend error %d on Retrace. ",GetLastError(),"Position #",position_ticket);
                        }
                        
                     PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
                     //Print("RETRACE done");
                     return;
                     }
                  }   
               }
            }
         }
      }   
   
   //OUTPUT INFORMATION AND METRICS TO THE CHART (No point wasting time on this code if in the Strategy Tester)
   if(!MQLInfoInteger(MQL_TESTER))
      OutputStatusToChart(indicatorMetrics);   
   }


//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
   {
    //## Walk Forward Pro OnTester() code start (MQL5)- When NOT calculating your own Custom Performance Criterion ##
    double dCustomPerformanceCriterion = NULL;  //The default Walk Forward Pro Custom Perf Criterion will be used
    WFA_PerformCalculations(dCustomPerformanceCriterion);

    return(dCustomPerformanceCriterion);
    //## Walk Forward Pro OnTester() code end (MQL5) - When NOT calculating your own Custom Performance Criterion ##
   }

void OnTesterInit()
   {
    //## Walk Forward Pro OnTesterInit() code start (MQL5) ##
    WFA_OnTesterInit();
    //## Walk Forward Pro OnTesterInit() code end (MQL5) ##

    //## YOUR OWN CODE HERE ##

    return;
   }

void OnTesterDeinit()
   {
    //## Walk Forward Pro OnTesterDeinit() code start (MQL5) ##
    WFA_OnTesterDeinit();
    //## Walk Forward Pro OnTesterDeinit() code end (MQL5) #

    //## YOUR OWN CODE HERE ##

    return;
   }

//+------------------------------------------------------------------+
//| MONEY MANAGEMENT                                                 |
//+------------------------------------------------------------------+

//double GetLots() // Calculate the lots using the right currency conversion
double GetLots(double StopL, string CurrSymbol)
   {
   double minlot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxlot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lots = 0;
   double MaxLots = maxlots;
   int correction = 0;
   //double nTickValue=MarketInfo(Symbol(),MODE_TICKVALUE);
   double AccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   
   if(MM==true)
      {

      //if(Digits==3 || Digits==5)
      //{
      //nTickValue=nTickValue*10;
      //}
      
      //double BID = SymbolInfoDouble(CurrentSymbol,SYMBOL_BID);
      double ASK = SymbolInfoDouble(CurrSymbol,SYMBOL_ASK);
      
      if(_Digits==3) {correction = 1000;}
      if(_Digits==5) {correction = 100000;}
      
      double SL = (StopL-ASK)*10000;
      
      if(SL<=0) SL=40;
      
      //lots = NormalizeDouble((AccountBalance() * Risk/100) / (StopLoss*nTickValue) , LotDigits);
      //lots = NormalizeDouble((AccountBalance * Risk/100) / (StopLoss*vPoint*correction) , LotDigits);
      lots = NormalizeDouble((AccountBalance * Risk/100) / (SL*vPoint*correction) , LotDigits);

      if(lots<minlot) lots = minlot;
      if(lots>MaxLots) lots = MaxLots;
      if(MaxLots>maxlot) lots = maxlot;

      }
   else
      {
      if(lots<minlot) lots = minlot;
      if(lots>MaxLots) lots = MaxLots;
      if(MaxLots>maxlot) lots = maxlot;
      lots = NormalizeDouble(Lots,2);
      }   
   return(lots);   
   }


//+------------------------------------------------------------------+
//| CHECK NEW BAR BY OPEN TIME                                       |
//+------------------------------------------------------------------+
bool NewBar(string CurrSymbol)
   {
   
   //string CurrentSymbol = SymbolArray[SymbolLoop];
   
   static datetime lastbar;
   //datetime curbar = Time[0];
   datetime curbar = iTime(CurrSymbol,PERIOD_M1,0);
   //datetime curbar = iTime(_Symbol,PERIOD_H4,0);
   if(lastbar!=curbar)
      {
      lastbar=curbar;
      return (true);
      }
      else
      {
      return(false);
      }
   }


////+------------------------------------------------------------------+
////| COUNT OPEN ORDERS BY SYMBOL AND MAGIC NUMBER                     |
////+------------------------------------------------------------------+
int CountOrder_symbol_magic(string CurrSymbol)
   {
   int cnt;
   int count=0;
   int positiontotal = PositionsTotal();
   long magic;
   string symbol;
   ulong ticket;
   
   for(cnt=positiontotal-1; cnt>=0; cnt--)
      {
      if((ticket=PositionGetTicket(cnt))>0)
         {
         symbol = PositionGetSymbol(cnt);
         magic = PositionGetInteger(POSITION_MAGIC);
         if(symbol==CurrSymbol && magic==magic_number)
            {
            count++;
            }
         }   
      }
   return (count);
   }
   

void ResizeCoreArrays()
{
   ArrayResize(OpenTradeOrderTicket, NumberOfTradeableSymbols);
   //Add other trade arrays here as required
}

void ResizeIndicatorHandleArrays()
{
   //Indicator Handles
   ArrayResize(handle_BollingerBands, NumberOfTradeableSymbols);
   ArrayResize(SAR_Handle_H4, NumberOfTradeableSymbols);
   ArrayResize(SAR_Handle_D1, NumberOfTradeableSymbols);
   //Add other indicators here as required by your EA
}

//SET UP REQUIRED INDICATOR HANDLES (arrays because of multi-symbol capability in EA)
bool SetUpIndicatorHandles()
{  
   //Bollinger Bands
   for(int SymbolLoop=0; SymbolLoop < NumberOfTradeableSymbols; SymbolLoop++)
   {
      //Reset any previous error codes so that only gets set if problem setting up indicator handle
      ResetLastError();
   
      handle_BollingerBands[SymbolLoop] = iBands(SymbolArray[SymbolLoop], Period(), BBandsPeriods, 0, BBandsDeviations, PRICE_CLOSE);
      
      if(handle_BollingerBands[SymbolLoop] == INVALID_HANDLE) 
      { 
         string outputMessage = "";
         
         if(GetLastError() == 4302)
            outputMessage = "Symbol needs to be added to the MarketWatch";
         else
            StringConcatenate(outputMessage, "(error code ", GetLastError(), ")");

         MessageBox("Failed to create handle of the iBands indicator for " + SymbolArray[SymbolLoop] + "/" + EnumToString(Period()) + "\n\r\n\r" + 
                     outputMessage +
                     "\n\r\n\rEA will now terminate.");
                      
         //Don't proceed
         return false;
      } 
      
      Print("Handle for iBands / ", SymbolArray[SymbolLoop], " / ", EnumToString(Period()), " successfully created");
      
      
//   ma_M5_handle = iMA(_Symbol, PERIOD_M5, EMA, 0, MODE_EMA, PRICE_CLOSE);
//   
//   if(ma_M5_handle == INVALID_HANDLE)
//      {
//      Print("Error creating MA indicator");
//      return (INIT_FAILED);
//      }
//      
//   ma_H1_handle = iMA(_Symbol, MA_TF, MA_Period_H1, 0, MODE_SMMA, PRICE_CLOSE);
//   
//   if(ma_H1_handle == INVALID_HANDLE)
//      {
//      Print("Error creating MA indicator");
//      return (INIT_FAILED);
//      }
//   
//   rsi_M5_handle = iRSI(_Symbol, PERIOD_M5, RSIperiod, PRICE_CLOSE);
//   
//   if(rsi_M5_handle == INVALID_HANDLE)
//      {
//      Print("Error creating RSI indicator");
//      return (INIT_FAILED);
//      }
//      
//   //rsi_H1_handle = iRSI(_Symbol, MA_TF, RSIperiod, PRICE_CLOSE);
//   rsi_H1_handle = iRSI(_Symbol, MA_TF, 7, PRICE_CLOSE);
//   
//   if(rsi_H1_handle == INVALID_HANDLE)
//      {
//      Print("Error creating RSI indicator");
//      return (INIT_FAILED);
//      }
//   
//   stochastic_M5_handle = iStochastic(_Symbol, PERIOD_M5, KPeriod, DPeriod, Slowing, MODE_SMA, STO_LOWHIGH);
//   
//   if(stochastic_M5_handle == INVALID_HANDLE)
//      {
//      Print("Error creating Stochastic indicator");
//      return (INIT_FAILED);
//      }
//   
//   macd_H1_handle = iMACD(_Symbol, MA_TF, EMA_Fast, EMA_Slow, macd_signal, PRICE_CLOSE);
//   
//   if(macd_H1_handle == INVALID_HANDLE)
//      {
//      Print("Error creating MACD indicator");
//      return (INIT_FAILED);
//      }
      
      SAR_Handle_H4[SymbolLoop] = iSAR(SymbolArray[SymbolLoop], PERIOD_H4, SAR_accel_H4,0.2);
   
      if(SAR_Handle_H4[SymbolLoop] == INVALID_HANDLE)
         {
         string outputMessage = "";
         
         if(GetLastError() == 4302)
            outputMessage = "Symbol needs to be added to the MarketWatch";
         else
            StringConcatenate(outputMessage, "(error code ", GetLastError(), ")");

         MessageBox("Failed to create handle of the SAR_H4 indicator for " + SymbolArray[SymbolLoop] + "/" + EnumToString(Period()) + "\n\r\n\r" + 
                     outputMessage +
                     "\n\r\n\rEA will now terminate.");
                      
         //Don't proceed
         return false;
         }
      
      Print("Handle for SAR_H4 / ", SymbolArray[SymbolLoop], " / ", EnumToString(Period()), " successfully created");   
      
      
      SAR_Handle_D1[SymbolLoop] = iSAR(SymbolArray[SymbolLoop], PERIOD_D1, SAR_accel_D1,0.2);
      
      if(SAR_Handle_D1[SymbolLoop] == INVALID_HANDLE)
         {
         string outputMessage = "";
         
         if(GetLastError() == 4302)
            outputMessage = "Symbol needs to be added to the MarketWatch";
         else
            StringConcatenate(outputMessage, "(error code ", GetLastError(), ")");

         MessageBox("Failed to create handle of the SAR_D1 indicator for " + SymbolArray[SymbolLoop] + "/" + EnumToString(Period()) + "\n\r\n\r" + 
                     outputMessage +
                     "\n\r\n\rEA will now terminate.");
                      
         //Don't proceed
         return false;
         }
      Print("Handle for SAR_D1 / ", SymbolArray[SymbolLoop], " / ", EnumToString(Period()), " successfully created");   
   }
   
   //All completed without errors so return true
   return true;
}

string GetBBandsOpenSignalStatus(int SymbolLoop, string& signalDiagnosticMetrics)
{
   string CurrentSymbol = SymbolArray[SymbolLoop];
   
   //Need to copy values from indicator buffers to local buffers
   int    numValuesNeeded = 3;
   double bufferUpper[];
   double bufferLower[];
   
   bool fillSuccessUpper = tlamCopyBuffer(handle_BollingerBands[SymbolLoop], UPPER_BAND, bufferUpper, numValuesNeeded, CurrentSymbol, "BBANDS");
   bool fillSuccessLower = tlamCopyBuffer(handle_BollingerBands[SymbolLoop], LOWER_BAND, bufferLower, numValuesNeeded, CurrentSymbol, "BBANDS");
   
   if(fillSuccessUpper == false  ||  fillSuccessLower == false)
      return("FILL_ERROR");     //No need to log error here. Already done from tlamCopyBuffer() function
   
   double CurrentBBandsUpper = bufferUpper[0];
   double CurrentBBandsLower = bufferLower[0];
   
   double CurrentClose = iClose(CurrentSymbol, Period(), 0);
    
   //SET METRICS FOR BBANDS WHICH GET RETURNED TO CALLING FUNCTION BY REF FOR OUTPUT TO CHART
   StringConcatenate(signalDiagnosticMetrics, "UPPER=", DoubleToString(CurrentBBandsUpper, (int)SymbolInfoInteger(CurrentSymbol, SYMBOL_DIGITS)), "  |  LOWER=", DoubleToString(CurrentBBandsLower, (int)SymbolInfoInteger(CurrentSymbol, SYMBOL_DIGITS)), "  |  CLOSE=" + DoubleToString(CurrentClose, (int)SymbolInfoInteger(CurrentSymbol, SYMBOL_DIGITS)));
   
   
   //INSERT YOUR OWN ENTRY LOGIC HERE
   //e.g.
   //if(CurrentClose > CurrentBBandsUpper)
   //   return("SHORT");
   //else if(CurrentClose < CurrentBBandsLower)
   //   return("LONG");
   //else
        return("NO_TRADE");
}

string GetBBandsCloseSignalStatus(int SymbolLoop)
{
   string CurrentSymbol = SymbolArray[SymbolLoop];
   
   //Need to copy values from indicator buffers to local buffers
   int    numValuesNeeded = 3;
   double bufferUpper[];
   double bufferLower[];
   
   bool fillSuccessUpper = tlamCopyBuffer(handle_BollingerBands[SymbolLoop], UPPER_BAND, bufferUpper, numValuesNeeded, CurrentSymbol, "BBANDS");
   bool fillSuccessLower = tlamCopyBuffer(handle_BollingerBands[SymbolLoop], LOWER_BAND, bufferLower, numValuesNeeded, CurrentSymbol, "BBANDS");
   
   if(fillSuccessUpper == false  ||  fillSuccessLower == false)
      return("FILL_ERROR");     //No need to log error here. Already done from tlamCopyBuffer() function
   
   double CurrentBBandsUpper = bufferUpper[0];
   double CurrentBBandsLower = bufferLower[0];
   
   double CurrentClose = iClose(CurrentSymbol, Period(), 0);
    
   //INSERT YOUR OWN ENTRY LOGIC HERE
   //e.g.
   //if(CurrentClose < CurrentBBandsLower)
   //   return("CLOSE_SHORT");
   //else if(CurrentClose > CurrentBBandsUpper)
   //   return("CLOSE_LONG");
   //else
        return("NO_CLOSE_SIGNAL");
}

bool tlamCopyBuffer(int ind_handle,            // handle of the indicator 
                    int buffer_num,            // for indicators with multiple buffers
                    double &localArray[],      // local array 
                    int numBarsRequired,       // number of values to copy 
                    string symbolDescription,  
                    string indDesc)
{
   
   int availableBars;
   bool success = false;
   int failureCount = 0;
   
   //Sometimes a delay in prices coming through can cause failure, so allow 3 attempts
   while(!success)
   {
      availableBars = BarsCalculated(ind_handle);
      
      if(availableBars < numBarsRequired)
      {
         failureCount++;
         
         if(failureCount >= 3)
         {
            Print("Failed to calculate sufficient bars in tlamCopyBuffer() after ", failureCount, " attempts (", symbolDescription, "/", indDesc, " - Required=", numBarsRequired, " Available=", availableBars, ")");
            return(false);
         }
         
         Print("Attempt ", failureCount, ": Insufficient bars calculated for ", symbolDescription, "/", indDesc, "(Required=", numBarsRequired, " Available=", availableBars, ")");
         
         //Sleep for 0.1s to allow time for price data to become usable
         Sleep(100);
      }
      else
      {
         success = true;
         
         if(failureCount > 0) //only write success message if previous failures registered
            Print("Succeeded on attempt ", failureCount+1);
      }
   }
    
   ResetLastError(); 
   
   int numAvailableBars = CopyBuffer(ind_handle, buffer_num, 0, numBarsRequired, localArray);
   
   if(numAvailableBars != numBarsRequired) 
   { 
      Print("Failed to copy data from indicator with error code ", GetLastError(), ". Bars required = ", numBarsRequired, " but bars copied = ", numAvailableBars);
      return(false); 
   } 
   
   //Ensure that elements indexed like in a timeseries (with index 0 being the current, 1 being one bar back in time etc.)
   ArraySetAsSeries(localArray, true);
   
   return(true); 
}

void ProcessTradeOpen(int SymbolLoop, string TradeDirection)
{
   string CurrentSymbol = SymbolArray[SymbolLoop];
   
   //INSERT YOUR PRE-CHECKS HERE
   
   //SETUP MqlTradeRequest orderRequest and MqlTradeResult orderResult HERE 
   //Ensure that CurrentSymbol is used as the symbol 
   
   //bool success = OrderSend(orderRequest, orderResult);
   
   //CHECK FOR ERRORS AND HANDLE EXCEPTIONS HERE
   
   //SET TRADE ARRAY TO PREVENT FUTURE TRADES BEING OPENED UNTIL THIS IS CLOSED
   //OpenTradeOrderTicket[SymbolLoop] = orderResult.order;
}

void ProcessTradeClose(int SymbolLoop, string CloseDirection)
{
   string CurrentSymbol = SymbolArray[SymbolLoop];
   
   //INCLUSE PRE-CLOSURE CHECKS HERE
   
   //SETUP CTrade tradeObject HERE
      
   //bool bCloseCheck = tradeObject.PositionClose(OpenTradeOrderTicket[SymbolLoop], 0); 
   
   //CHECK FOR ERRORS AND HANDLE EXCEPTIONS HERE
   
   //IF SUCCESSFUL SET TRADE ARRAY TO 0 TO ALLOW FUTURE TRADES TO BE OPENED
   //OpenTradeOrderTicket[SymbolLoop] = 0;
}

void OutputStatusToChart(string additionalMetrics)
{      
   //GET GMT OFFSET OF MT5 SERVER
   double offsetInHours = (TimeCurrent() - TimeGMT()) / 3600.0;

   //SYMBOLS BEING TRADED
   string symbolsText = "SYMBOLS BEING TRADED: ";
   for(int SymbolLoop=0; SymbolLoop < NumberOfTradeableSymbols; SymbolLoop++)
      StringConcatenate(symbolsText, symbolsText, " ", SymbolArray[SymbolLoop]);
   
   Comment("\n\rMT5 SERVER TIME: ", TimeCurrent(), " (OPERATING AT UTC/GMT", StringFormat("%+.1f", offsetInHours), ")\n\r\n\r",
            Symbol(), " TICKS RECEIVED: ", TicksReceivedCount, "\n\r\n\r",
            symbolsText,
            "\n\r\n\r", additionalMetrics);
}
