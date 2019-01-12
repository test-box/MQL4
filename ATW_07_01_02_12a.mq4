//+------------------------------------------------------------------+
//|                                                    ATW_07_00.mq4 |
//|                                         Copyright � 2012, GlobuX |
//|                                                 globuq@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright � 2012, GlobuX"
#property link      "globuq@gmail.com"
#include <stderror.mqh>

//----------------���������-----------------//
extern bool    Trade = true;
extern int     PeriodMV = 10;
extern int     ManualTP = 0;
extern int     correctTP = 34;
extern int     correctDistance = 13;
extern double  DefaultLots = 1;
extern bool    calcLastWeek = false;
extern int     IdNum = 700;
extern string  CommentOrder = "ATW_v7.0";
extern bool    AutoLot = true;
extern double  minLot = 0.01;
extern double  deposit = 1000;
extern double  firstlot = 0.10;
extern bool    enable_min_distance = false;
extern int     minDistance = 50;
extern int     SafeDistance = 50;

//-----���������� ���������� ���������------//
double Distance;
string dist_GV;
int    LastOrderTicket;
string lastticket_GV;

//-----���������� ���������� ��������-------//
int    calcDay;
double MedianATW;
double TP;
double CurrentTP;
double calcDist; 
int    ticket;
int    tickets[50];
int    quantityOrders;
double Lots;
double LastLots;
int    nextOrder=6;
double POINT;



//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
   dist_GV="ATW7_"+Symbol()+"_dist"; Print("dist_GV=", dist_GV); // ������������� �������� ���������� ���������� (Distance) ��� ���������
   lastticket_GV = "ATW7_"+Symbol()+"_lastticket"; Print("lastticket_GV=", lastticket_GV);
   if (Point < 0.0001) POINT = Point*10;
   else POINT = Point;
   Print("��������: ATWv07, �������� �������������. ", "IdNum: ", IdNum, ", CommentOrder: ", CommentOrder);
   ArrayInitialize(tickets,0);
   calcDay = Day(); //���������� ���� ��������. 
   if (HistoryLoaded() == true) 
     {
      calcTakeProfit();  // ����������� ����������
      if (GlobalVariableCheck(dist_GV))
        {
         Distance = GlobalVariableGet(dist_GV);
         Print("��������� ����� �������� (����� ����������� ���������): ", Distance);
         if (Distance == 0) {Distance = calcDist; Print("��������� �� ����� ���� (0), ����������� ������ ��������� =", Distance);}
        }
      else {Distance = calcDist; Print("calcDist=", calcDist, "; ��������� ����� ��������: ", Distance);}
     }
   else Distance = SafeDistance*POINT;
   if (enable_min_distance == true && Distance < minDistance) {Distance = minDistance*POINT; Print("��������� ������ �����������, ����������� ������ ��������� =", Distance);}
   FindOrders(); //����� ������������ �������
  }

//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+ 
/*
int deinit()
  {
   return(0);
  } */

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
   if (HistoryLoaded() == false) return; 
   if (TimeDay(TimeCurrent())!= calcDay) { calcTakeProfit();} //���� �������� ��������� ����, ������������� ����������.
   if (quantityOrders==0) {SetFirstOrder(); return(0);} //���� ��� ������������� �������, ������������� ������.
   if (LastOrderClosed()==true) {ClosedAllOrders(); return(0);} //���� ������� ����� ������, �� ��������� ��������� ������.
   if (AllowSetNextOrder()==true) SetNextOrder(); //���� ������� �������� ������������� ��������� ����� � ���������� �����.
  }


//+------------------------------------------------------------------+


int GetLastOrderTicket()
  {
   if (GlobalVariableCheck(lastticket_GV))
     {
      int lastticket = GlobalVariableGet(lastticket_GV);
      if (OrderSelect(lastticket,SELECT_BY_TICKET) == true && OrderCloseTime() == 0) return(lastticket);
      else lastticket = -1;
     }
   else lastticket = -1;
   return(lastticket);
  }


bool HistoryLoaded()
  {
   if (iBars(NULL,PERIOD_D1) == 0 || GetLastError() == 4066)
     {
      Print("����������� �������...");
      Sleep(15000);
      RefreshRates();
      return(false);
     }
   else return(true);
  }


void FindOrders()
  {
   double absTP = 0;
   double preTime = 0;
   quantityOrders = 0;
   Lots = 0;
   ArrayInitialize(tickets,0);
   for (int i=0; i<OrdersTotal(); i++)
     {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) continue;
      if (OrderMagicNumber() != IdNum) continue;
      if (OrderSymbol() != Symbol()) continue;
      // if (StringFind(OrderComment(), CommentOrder, 0) == -1) continue;
      tickets[quantityOrders] = OrderTicket();
      quantityOrders++;
      if (OrderOpenTime() > preTime)
        {
         preTime = OrderOpenTime();
         int LastOrderTicketFind = OrderTicket();
         CurrentTP = MathAbs(OrderOpenPrice()-OrderTakeProfit());
         absTP = OrderTakeProfit();
         Lots = OrderLots();
        }
     }
   Print("������� �������:", quantityOrders, "; ��������� ��������� �����: ����=", Lots, ", �����=", LastOrderTicketFind, ", ������������� ��=", CurrentTP, ", ���������� ��=", absTP);
   LastOrderTicket = GetLastOrderTicket(); Print("����� ���������� �������������� ������: ", LastOrderTicket);
  }
  

void SetFirstOrder()
  {
   if (Trade == false) return;
   Print("-+������� ��������� ������� ������+-");
   Distance = calcDist + correctDistance*POINT;
   if (enable_min_distance == true && Distance < minDistance) Distance = minDistance*POINT;
   if (Distance == 0) Distance = SafeDistance*POINT;
   Print("��������� ����� �������� �����������: ", Distance);
   //Print("�������� ���������� ���������� - ", dist_GV);
   if (GlobalVariableSet(dist_GV,Distance) == 0) {Print("��� ��������� ���������� ���������� �������� ������"); Print("������ #", GetLastError());}
   CurrentTP = Distance + correctTP*POINT;
   if (AutoLot == true) Lots = AccountBalance()/(deposit/firstlot);
   else Lots = DefaultLots;
   if (Lots < minLot) Lots = minLot;
   /* */
   if (nextOrder == OP_BUY) {Print("��������� ����� ��� "); SendOrder(OP_BUY); nextOrder = OP_SELL;} 
   else if (nextOrder == OP_SELL) {Print("��������� ����� ���� "); SendOrder(OP_SELL); nextOrder = OP_BUY;}
   else /* */ if (iClose(Symbol(),PERIOD_D1,1) > iOpen(Symbol(),PERIOD_D1,1)) {Print("��������� ����� ��� "); SendOrder(OP_BUY); nextOrder = OP_SELL;} //���� ���� �������� ���� ���� �������� ����������� ��� �� �������� BUY
              else {Print("��������� ����� ���� "); SendOrder(OP_SELL); nextOrder = OP_BUY;} //�����, ������� SELL
   if (GetLastError()==0)
     {
      tickets[quantityOrders] = ticket;
      quantityOrders++; //���� ������ �� ����, ����������� ������� ������� �� 1.
      LastOrderTicket = ticket; //���������� ����� �������� ������
      if (GlobalVariableSet(lastticket_GV,LastOrderTicket) == 0) {Print("��� ��������� ���������� ���������� lastticket_GV �������� ������"); Print("����� ������� #", GetLastError());}
      Print("����� ���������� �������.");
     }
   else {Print("��������� ������� ������ - ������!"); nextOrder = 6;}
  }


bool LastOrderClosed()
  {
   if (OrderSelect(LastOrderTicket, SELECT_BY_TICKET)==false)
      {Print("-%������� �������� ������������� �������� ������%- ", "������ ��� ������ ������: ", GetLastError()); return(true);}
   if (OrderCloseTime()==0) return(false);
   Print("������� ����� ��� ������, ����� # ", LastOrderTicket, ", ���������� ������� ����: ", quantityOrders);
   quantityOrders--;
   tickets[quantityOrders] = 0;
   return(true);
  }


void ClosedAllOrders()
  {
   Print("-= ������� �������� ���� ���������� ������� =-");
   Print("���������� ���������� �������: �� ����������� ���������=", quantityOrders, ", �� ������� (OrdersTotal)=", OrdersTotal());
   int k = 0;
   int OrderTicketMassive[30];
   ArrayInitialize(OrderTicketMassive,0);
   for (int t=0; t<OrdersTotal(); t++)  //���� ������ ������� ���������, ������� ������ �������
     {
      if (OrderSelect(t, SELECT_BY_POS, MODE_TRADES) == false) {Print("1-� ��������: ������, (OrderSelect)"); continue;}
      if (OrderMagicNumber() != IdNum) {Print("2-� ��������: ������, (OrderMagicNumber)"); continue;}
      if (OrderSymbol() != Symbol()) {Print("3-� ��������: ������, (OrderSymbol)"); continue;}
      
      OrderTicketMassive[t+1] = OrderTicket();
     }
   for (int i=1; i <= t; i++)      //���� �������� ��������� �������
     {
      OrderSelect(OrderTicketMassive[i],SELECT_BY_TICKET);
      Print("�����: ����� #", OrderTicket(), ", ��� ������=", OrderType(), ", ������=", OrderSymbol(),
            ", ���� ��������=", OrderOpenPrice(), ", ������� ��=",OrderTakeProfit(), ", ����� �����=", OrderLots(),
            ", idNum=", OrderMagicNumber(), ", �����������=", OrderComment()); 
      bool err = true;
      while (err == true)
       {
        RefreshRates();
        switch(OrderType())
         {
          case OP_BUY:
            OrderClose(OrderTicket(),OrderLots(),Bid,3,Blue);
            break;   
          case OP_SELL:
            OrderClose(OrderTicket(),OrderLots(),Ask,3,Red);
            break;
         }
        int error = CheckError();
        if (error == 0) {err = false; k++; Print("������ �������."); break;}
        if (error == ERR_INVALID_TICKET) break;
        else Sleep(15000);
       }
     }
   Print("���������� ��������� �������: ", k);
   ArrayInitialize(tickets,0);
   quantityOrders = 0;
  } 


bool AllowSetNextOrder()
  {
   if (quantityOrders < 1) return(false); // ���� ������� ������ 1, �������, ���������� false
   if (OrderSelect(LastOrderTicket,SELECT_BY_TICKET)==false) return(false);
   switch(OrderType())
     {
      case OP_BUY:
        if (OrderOpenPrice()-Distance >= Ask) return(true);
        break;   
      case OP_SELL:
        if (OrderOpenPrice()+Distance <= Bid) return(true);
        break;
     }
   return(false);
  }


void SetNextOrder()
  {
   if ((AccountFreeMarginCheck(Symbol(),OrderType(),OrderLots()*2)<=0) || (GetLastError()==134)) return(-1);
   Print("-@������� ��������� ���������� ������@-");
   Lots = OrderLots()*2;
   bool err = true;
   while (err == true)
     {
      switch(OrderType())
        {
         case OP_BUY:
           Print("��������� ����� ��� ");
           SendOrder(OP_BUY);
           nextOrder = OP_SELL;
           break;   
         case OP_SELL:
           Print("��������� ����� ���� ");
           SendOrder(OP_SELL);
           nextOrder = OP_BUY;
           break;
        }
      int error = CheckError();
      if (error==0) err = false;
      else
        {
         Print("������ ����� 15 ���.");
         Sleep(15000);
         if (error == 134) return (-1);
        }
     }
   LastOrderTicket = ticket;
   if (GlobalVariableSet(lastticket_GV,LastOrderTicket) == 0) {Print("��� ��������� ���������� ���������� lastticket_GV �������� ������"); Print("����� ������� #", GetLastError());}
   tickets[quantityOrders]=ticket;
   quantityOrders++;
   Print("����� ���������� �������");
  }


void SendOrder(int command)
  {
   TP = CurrentTP;
   RefreshRates();
   switch (command)
     {
      case OP_BUY:
        Print("����� ������� /\: ", "���� ���=", Ask, ", ������� ��=", Ask+TP, ", ������������� ��=", TP, ", �����=", Lots, ", ��������=", Distance);
        ticket = OrderSend(Symbol(),OP_BUY,Lots,Ask,1,0,Ask+TP,CommentOrder,IdNum,0,Blue); 
        break;
      case OP_SELL: 
        Print("����� ������� \/: ", "���� ���=", Bid, ", ������� ��=", Bid-TP, ", ������������� ��=", TP, ", �����=", Lots, ", ��������=", Distance);
        ticket = OrderSend(Symbol(),OP_SELL,Lots,Bid,1,0,Bid-TP,CommentOrder,IdNum,0,Red);
        break;
      case OP_BUYLIMIT: 
        break;
      case OP_SELLLIMIT: 
        break;
      case OP_BUYSTOP: 
        break;
      case OP_SELLSTOP: 
        break;
     }
  }


double CalcMV()
  {
   double val;
   val=0;
   for (int i=1;i<PeriodMV+1;i++)
     {
      val=val+iHigh(NULL,PERIOD_D1,i)-iLow(NULL,PERIOD_D1,i);
     }
   val=val/PeriodMV;
   return(val);
  }


double CalcMVLastWeek()
  {
   double val;
   val=0;
   for (int i=TimeDayOfWeek(TimeCurrent());i<PeriodMV+1;i++)
     {
      val=val+iHigh(NULL,PERIOD_D1,i)-iLow(NULL,PERIOD_D1,i);
     }
   val=val/PeriodMV;
   return(val);
  }


double MedATW()
  {
   if (calcLastWeek == true) MedianATW = CalcMVLastWeek();
   else MedianATW = CalcMV(); // Print("MedianATW=", MedianATW);
   return(MedianATW);
  }


double calcTakeProfit()
  {
   if (ManualTP == 0) calcDist = MedATW() / 2;
   else calcDist = ManualTP * POINT;
   return(calcDist);
  }


int CheckError()
  {
  int Error = GetLastError();
  switch (Error)
    {
     case ERR_NO_ERROR:
       /*Print("��� ������."); */ break;
     case ERR_NO_RESULT:
       Print("��� ������, �� ��������� ���������� (��������� �� ��������)"); break;
     case ERR_COMMON_ERROR:
       Print("����� ������"); break;
     case ERR_INVALID_TRADE_PARAMETERS:
       Print("������: ������������ ���������"); break;
     case ERR_SERVER_BUSY:
       Print("������: �������� ������ �����"); break;
     case ERR_OLD_VERSION:
       Print("������: ������ ������ ����������� ���������"); break;
     case ERR_NO_CONNECTION:
       Print("������: ��� ����� � �������� ��������"); break;
     case ERR_NOT_ENOUGH_RIGHTS:
       Print("������: ������������ ����"); break;
     case ERR_TOO_FREQUENT_REQUESTS:
       Print("������: ������� ������ �������"); break;
     case ERR_MALFUNCTIONAL_TRADE:
       Print("������: ������������ �������� ���������� ���������������� �������"); break;
     case ERR_ACCOUNT_DISABLED:
       Print("������: ���� ������������"); break;
     case ERR_INVALID_ACCOUNT:
       Print("������: ������������ ����� �����"); break;
     case ERR_TRADE_TIMEOUT:
       Print("������: ����� ���� �������� ���������� ������"); break;
     case ERR_INVALID_PRICE:
       Print("������: ������������ ����"); break;
     case ERR_INVALID_STOPS:
       Print("������: ������������ �����"); break;
     case ERR_INVALID_TRADE_VOLUME:
       Print("������: ������������ �����"); break;
     case ERR_MARKET_CLOSED:
       Print("������: ����� ������"); break;
     case ERR_TRADE_DISABLED:
       Print("������: �������� ���������"); break;
     case ERR_NOT_ENOUGH_MONEY:
       Print("������: ������������ ����� ��� ���������� ��������"); break;
     case ERR_PRICE_CHANGED:
       Print("������: ���� ����������"); break;
     case ERR_OFF_QUOTES:
       Print("������: ��� ���"); break;
     case ERR_BROKER_BUSY:
       Print("������: ������ �����"); break;
     case ERR_REQUOTE:
       Print("������: ����� ����"); break;
     case ERR_ORDER_LOCKED:
       Print("������: ����� ������������ � ��� ��������������"); break;
     case ERR_LONG_POSITIONS_ONLY_ALLOWED:
       Print("������: ��������� ������ �������"); break;
     case ERR_TOO_MANY_REQUESTS:
       Print("������: ������� ����� ��������"); break;
     case ERR_TRADE_MODIFY_DENIED:
       Print("������: ����������� ���������, ��� ��� ����� ������� ������ � �����"); break;
     case ERR_TRADE_CONTEXT_BUSY:
       Print("������: ���������� �������� ������"); break;
     case ERR_TRADE_EXPIRATION_DENIED:
       Print("������: ������������� ���� ��������� ������ ��������� ��������"); break;
     case ERR_TRADE_TOO_MANY_ORDERS:
       Print("������: ���������� �������� � ���������� ������� �������� �������, �������������� ��������"); break;
     case ERR_TRADE_HEDGE_PROHIBITED:
       Print("������: ������� ������� ��������������� ������� � ��� ������������ � ������, ���� ������������ ���������"); break;
     case ERR_TRADE_PROHIBITED_BY_FIFO:
       Print("������: ������� ������� ������� �� ����������� � ������������ � �������� FIFO."); break;
     case ERR_NO_MQLERROR:
       /*Print("������: ��� ������");*/ break;
     case ERR_WRONG_FUNCTION_POINTER:
       Print("������: ������������ ��������� �������"); break;
     case ERR_ARRAY_INDEX_OUT_OF_RANGE:
       Print("������: ������ ������� - ��� ���������"); break;
     case ERR_NO_MEMORY_FOR_CALL_STACK:
       Print("������: ��� ������ ��� ����� �������"); break;
     case ERR_RECURSIVE_STACK_OVERFLOW:
       Print("������: ������������ ����� ����� ������������ ������"); break;
     case ERR_NOT_ENOUGH_STACK_FOR_PARAM:
       Print("������: �� ����� ��� ������ ��� �������� ����������"); break;
     case ERR_NO_MEMORY_FOR_PARAM_STRING:
       Print("������: ��� ������ ��� ���������� ���������"); break;
     case ERR_NO_MEMORY_FOR_TEMP_STRING:
       Print("������: ��� ������ ��� ��������� ������"); break;
     case ERR_NOT_INITIALIZED_STRING:
       Print("������: �������������������� ������"); break;
     case ERR_NOT_INITIALIZED_ARRAYSTRING:
       Print("������: �������������������� ������ � �������"); break;
     case ERR_NO_MEMORY_FOR_ARRAYSTRING:
       Print("������: ��� ������ ��� ���������� �������"); break;
     case ERR_TOO_LONG_STRING:
       Print("������: ������� ������� ������"); break;
     case ERR_REMAINDER_FROM_ZERO_DIVIDE:
       Print("������: ������� �� ������� �� ����"); break;
     case ERR_ZERO_DIVIDE:
       Print("������: ������� �� ����"); break;
     case ERR_UNKNOWN_COMMAND:
       Print("������: ����������� �������"); break;
     case ERR_WRONG_JUMP:
       Print("������: ������������ �������"); break;
     case ERR_NOT_INITIALIZED_ARRAY:
       Print("������: �������������������� ������"); break;
     case ERR_DLL_CALLS_NOT_ALLOWED:
       Print("������: ������ DLL �� ���������"); break;
     case ERR_CANNOT_LOAD_LIBRARY:
       Print("������: ���������� ��������� ����������"); break;
     case ERR_CANNOT_CALL_FUNCTION:
       Print("������: ���������� ������� �������"); break;
     case ERR_EXTERNAL_CALLS_NOT_ALLOWED:
       Print("������: ������ ������� ������������ ������� �� ���������"); break;
     case ERR_NO_MEMORY_FOR_RETURNED_STR:
       Print("������: ������������ ������ ��� ������, ������������ �� �������"); break;
     case ERR_SYSTEM_BUSY:
       Print("������: ������� ������"); break;
     case ERR_INVALID_FUNCTION_PARAMSCNT:
       Print("������: ������������ ���������� ���������� �������"); break;
     case ERR_INVALID_FUNCTION_PARAMVALUE:
       Print("������: ������������ �������� ��������� �������"); break;
     case ERR_STRING_FUNCTION_INTERNAL:
       Print("������: ���������� ������ ��������� �������"); break;
     case ERR_SOME_ARRAY_ERROR:
       Print("������: ������ �������"); break;
     case ERR_INCORRECT_SERIESARRAY_USING:
       Print("������: ������������ ������������� �������-���������"); break;
     case ERR_CUSTOM_INDICATOR_ERROR:
       Print("������: ������ ����������������� ����������"); break;
     case ERR_INCOMPATIBLE_ARRAYS:
       Print("������: ������� ������������"); break;
     case ERR_GLOBAL_VARIABLES_PROCESSING:
       Print("������: ������ ��������� ����������� ����������"); break;
     case ERR_GLOBAL_VARIABLE_NOT_FOUND:
       Print("������: ���������� ���������� �� ����������"); break;
     case ERR_FUNC_NOT_ALLOWED_IN_TESTING:
       Print("������: ������� �� ��������� � �������� ������"); break;
     case ERR_FUNCTION_NOT_CONFIRMED:
       Print("������: ������� �� ���������"); break;
     case ERR_SEND_MAIL_ERROR:
       Print("������: ������ �������� �����"); break;
     case ERR_STRING_PARAMETER_EXPECTED:
       Print("������: ��������� �������� ���� string"); break;
     case ERR_INTEGER_PARAMETER_EXPECTED:
       Print("������: ��������� �������� ���� integer"); break;
     case ERR_DOUBLE_PARAMETER_EXPECTED:
       Print("������: ��������� �������� ���� double"); break;
     case ERR_ARRAY_AS_PARAMETER_EXPECTED:
       Print("������: � �������� ��������� ��������� ������"); break;
     case ERR_HISTORY_WILL_UPDATED:
       Print("������: ����������� ������������ ������ � ��������� ����������"); break;
     case ERR_TRADE_ERROR:
       Print("������: ������ ��� ���������� �������� ��������"); break;
     case ERR_END_OF_FILE:
       Print("������: ����� �����"); break;
     case ERR_SOME_FILE_ERROR:
       Print("������: ������ ��� ������ � ������"); break;
     case ERR_WRONG_FILE_NAME:
       Print("������: ������������ ��� �����"); break;
     case ERR_TOO_MANY_OPENED_FILES:
       Print("������: ������� ����� �������� ������"); break;
     case ERR_CANNOT_OPEN_FILE:
       Print("������: ���������� ������� ����"); break;
     case ERR_INCOMPATIBLE_FILEACCESS:
       Print("������: ������������� ����� ������� � �����"); break;
     case ERR_NO_ORDER_SELECTED:
       Print("������: �� ���� ����� �� ������"); break;
     case ERR_UNKNOWN_SYMBOL:
       Print("������: ����������� ������"); break;
     case ERR_INVALID_PRICE_PARAM:
       Print("������: ������������ �������� ���� ��� �������� �������"); break;
     case ERR_INVALID_TICKET:
       Print("������: �������� ����� ������"); break;
     case ERR_TRADE_NOT_ALLOWED:
       Print("������: �������� �� ���������. ���������� �������� ����� /��������� ��������� ���������/ � ��������� ��������."); break;
     case ERR_LONGS_NOT_ALLOWED:
       Print("������: ������� ������� �� ���������. ���������� ��������� �������� ��������."); break;
     case ERR_SHORTS_NOT_ALLOWED:
       Print("������: �������� ������� �� ���������. ���������� ��������� �������� ��������."); break;
     case ERR_OBJECT_ALREADY_EXISTS:
       Print("������: ������ ��� ����������"); break;
     case ERR_UNKNOWN_OBJECT_PROPERTY:
       Print("������: ��������� ����������� �������� �������"); break;
     case ERR_OBJECT_DOES_NOT_EXIST:
       Print("������: ������ �� ����������"); break;
     case ERR_UNKNOWN_OBJECT_TYPE:
       Print("������: ����������� ��� �������"); break;
     case ERR_NO_OBJECT_NAME:
       Print("������: ��� ����� �������"); break;
     case ERR_OBJECT_COORDINATES_ERROR:
       Print("������: ������ ��������� �������"); break;
     case ERR_NO_SPECIFIED_SUBWINDOW:
       Print("������: �� ������� ��������� �������"); break;
     case ERR_SOME_OBJECT_ERROR:
       Print("������: ������ ��� ������ � ��������"); break;
     case 4250: //ERR_NOTIFICATION_SEND_ERROR
       Print("������: ������ ���������� ����������� � ������� �� �������"); break;
     case 4251:  //ERR_NOTIFICATION_WRONG_PARAMETER
       Print("������: �������� �������� - � ������� SendNotification() �������� ������ ������"); break;
     case 4252:  //ERR_NOTIFICATION_WRONG_SETTINGS
       Print("������: �������� ��������� ��� �������� ����������� (�� ������ ID ��� �� ���������� ����������"); break;
     case 4253:  //ERR_NOTIFICATION_TOO_FREQUENT
       Print("������: ������� ������ �������� �����������"); break;
     default:
       Print("������: �� ��������, ���������� �� ��������, #", Error); break;
    }
   return(Error); 
  }




