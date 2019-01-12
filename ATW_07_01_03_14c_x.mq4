//+------------------------------------------------------------------+
//|                                                    ATW_07_00.mq4 |
//|                                         Copyright � 2012, GlobuX |
//|                                                 globuq@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright � 2012, GlobuX"
#property link      "globuq@gmail.com"
#include <stderror.mqh>

//---------����������-���������-��������---------//
extern bool    Trade = true;            // ���������� �������� ��� ��� ����� �������� ���� ������
extern int     correctTP = 34;          // ������������� �����������
extern int     correctDistance = 12;    // ������������� ���������
extern bool    AutoLot = true;          // �������������� ������ �����, ���� TRUE
extern double  minLot = 0.01;           // ����������� ���, ������� ��������� ������
extern double  firstlot = 0.07;         // ���������� ����� ��� ������� ������ � ������� �� DEPOSIT
extern double  deposit = 1000;          // DEPOSIT ��� ������� ����� ������� ������
extern int     maxQOrders = 7;          // ������������ ���������� ������������� �������
extern int     PeriodMV = 10;           // ������ ��� ������� ��������� ����� ��������
extern bool    Limiter = false;         // ��������� ������� ��� ��������� ������� ������
extern int     PeriodMP = 1;            // ������ ��� ������� ���������� ������� �� ������� ����, � �������� ������� (���� PERIOD=60, �� 24 ����� �������� �����)
extern int     PERIOD = 1440;           // ������ ������� ������� � �������, 1-1 ������, 5-5 �����, 15-15 �����, 30-30 �����, 60-1 ���, 240-4 ����, 1440-1 ����, 10080-1 ������, 43200-1 �����; ������ ��� ��������!!!
extern int     DeviationMP = 25;        // ���������� ������� ���� �� �������
extern int     ManualTP = 0;            // ������� �� ������������ ����������, ���� 0, �� �� �����������
extern double  DefaultLots = 0.05;      // ���������� ����� ��� ������� ������, ���� �� ���������� �������
extern bool    calcLastWeek = false;    // ������� ��������� �� ������� PeriodMV �� ������� ������� ������, ���� TRUE
extern int     IdNum = 700;             // ������������� ���������, ��������� ��� ������������� ���������� ����� �������
extern string  CommentOrder = "ATW_v7.0";   // ����������� � ��������������� �������, ��� ����������� ����������� ������� ���������
extern bool    enable_min_distance = true; // ������������� ����������� ���������, ���� TRUE
extern int     minDistance = 60;        // ����������� ��������� ����� ��������, �������� ���������

//--------���������� ���������� ���������----------//
double DistanceBuy;
double DistanceSell;
string distBuy_GV;
string distSell_GV;
int    LastOrderTicket;
int    LastBuyOrderTicket;
int    LastSellOrderTicket;
string lastticketBuy_GV;
string lastticketSell_GV;

//--------���������� ���������� ��������----------//
int    calcDay;
double MedianATW;
double CurrentBuyTP;    //������� � ��� ������������� �������
double CurrentSellTP;
double TP;
double calcDist;   
int    ticket;
int    ticketsB[50];
int    ticketsS[50];
int    quantityOrders;
int    quantityBuyOrders;
int    quantitySellOrders;
double Lots;
double LotsBuy;
double LotsSell;
double LastBuyLots;
double LastSellLots;
double POINT;
bool mess_printed = false;



//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
   Print("��������: ATWv07x, �������������. ", "IdNum: ", IdNum, ", CommentOrder: ", CommentOrder);
   if (Point < 0.0001) POINT = Point*10;
   else POINT = Point;
   ArrayInitialize(ticketsB,0);
   ArrayInitialize(ticketsS,0);
   distBuy_GV="ATW_"+Symbol()+"_distBuy";  //������������� �������� ���������� ���������� (Distance)
   distSell_GV="ATW_"+Symbol()+"_distSell";  //������������� �������� ���������� ���������� (Distance)
   Print("distBuy_GV=", distBuy_GV, ", distSell_GV=", distSell_GV);
   if (GlobalVariableCheck(distBuy_GV))
     {
      DistanceBuy = GlobalVariableGet(distBuy_GV);
      Print("���������� ���������: ��������� ����� BUY ��������: ", DistanceBuy);
     }
   if (GlobalVariableCheck(distSell_GV))
     {
      DistanceSell = GlobalVariableGet(distSell_GV);
      Print("���������� ���������: ��������� ����� SELL ��������: ", DistanceSell);
     }
   lastticketBuy_GV="ATW_"+Symbol()+"_lastticketBuy";  //������������� �������� ���������� ���������� (lastticket)
   lastticketSell_GV="ATW_"+Symbol()+"_lastticketSell";  //������������� �������� ���������� ���������� (lastticket)
   Print("lastticketBuy_GV=", lastticketBuy_GV, ", lastticketSell_GV=", lastticketSell_GV);
   if (GlobalVariableCheck(lastticketBuy_GV))
     {
      LastBuyOrderTicket = GlobalVariableGet(lastticketBuy_GV);
      Print("���������� ���������: ����� ���������� ������: ", LastBuyOrderTicket);
     }
   if (GlobalVariableCheck(lastticketSell_GV))
     {
      LastSellOrderTicket = GlobalVariableGet(lastticketSell_GV);
      Print("���������� ���������: ����� ���������� ������: ", LastSellOrderTicket);
     }
   if (DistanceBuy < minDistance*POINT) DistanceBuy = calcDistance() + correctDistance*POINT;
   if (DistanceSell < minDistance*POINT) DistanceSell = calcDistance() + correctDistance*POINT;
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
   if (ExistHistory() == false) return; 
   //if (TimeDay(TimeCurrent())!= calcDay) {calcDistance();}//���� �������� ��������� ����, ������������� ���������.
   /* ���� BUY ������� */
   if (quantityBuyOrders==0) SetFirstBuyOrder();               //���� ��� ������������� BUY �������, ������������� ������,
   else if (LastBuyOrderClosed()==true) ClosedAllBuyOrders();  //����� ���� ������� BUY ����� ������, �� ��������� ��������� BUY ������,
   else if (AllowSetNextBuyOrder()==true) SetNextBuyOrder();   //����� ���� ������� �������� ������������� ��������� BUY ����� � ���������� �����.
   /* ���� SELL ������� */
   if (quantitySellOrders==0) SetFirstSellOrder();             //���� ��� ������������� SELL �������, ������������� ������,
   else if (LastSellOrderClosed()==true) ClosedAllSellOrders();//����� ���� ������� SELL ����� ������, �� ��������� ��������� SELL ������,
   else if (AllowSetNextSellOrder()==true) SetNextSellOrder(); //����� ���� ������� �������� ������������� ��������� SELL ����� � ���������� �����.
   return(0);
  }


//+------------------------------------------------------------------+


bool ExistHistory()
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

void SaveLastBuyOrderTicket(int ticket)
  {
   if (GlobalVariableSet(lastticketBuy_GV, ticket) == 0)
     {
      Print("��� ��������� ���������� ���������� lastticket_GV �������� ������");
      Print("������ #", GetLastError());
     }
  }

void SaveLastSellOrderTicket(int ticket)
  {
   if (GlobalVariableSet(lastticketSell_GV, ticket) == 0)
     {
      Print("��� ��������� ���������� ���������� lastticket_GV �������� ������");
      Print("������ #", GetLastError());
     }
  }

void FindOrders()
  {
   double absBuyTP = 0;
   double absSellTP = 0;
   double preTime = 0;
   double preBuyTime = 0;
   double preSellTime = 0;
   quantityOrders = 0;
   quantityBuyOrders = 0;
   quantitySellOrders = 0;
   LotsBuy = 0;
   LotsSell = 0;
   ArrayInitialize(ticketsB,0);
   ArrayInitialize(ticketsS,0);
   for (int i=0; i<OrdersTotal(); i++)
     {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) continue;
      if (OrderMagicNumber() != IdNum) continue;
      if (OrderSymbol() != Symbol()) continue;
      // if (StringFind(OrderComment(), CommentOrder, 0) == -1) continue;
      quantityOrders++;
      if (OrderOpenTime() > preTime) {preTime = OrderOpenTime(); LastOrderTicket = OrderTicket();}
      switch(OrderType())
        {
         case OP_BUY:
         ticketsB[quantityBuyOrders] = OrderTicket();
         quantityBuyOrders++;
         if (OrderOpenTime() > preBuyTime)
           {
            preBuyTime = OrderOpenTime();
            int LastBuyTicket = OrderTicket();
            CurrentBuyTP = MathAbs(OrderOpenPrice()-OrderTakeProfit());
            absBuyTP = OrderTakeProfit();
            LotsBuy = OrderLots();
           }
         break;
         case OP_SELL:
         ticketsS[quantitySellOrders] = OrderTicket();
         quantitySellOrders++;
         if (OrderOpenTime() > preSellTime)
           {
            preSellTime = OrderOpenTime();
            int LastSellTicket = OrderTicket();
            CurrentSellTP = MathAbs(OrderOpenPrice()-OrderTakeProfit());
            absSellTP = OrderTakeProfit();
            LotsSell = OrderLots();
           }
         break;
        }
     }
   Print("������� BUY �������:", quantityBuyOrders, "; ��������� �����: ����=", LotsBuy, ", �����=", LastBuyTicket, ", ������������� ��=", CurrentBuyTP, ", ���������� ��=", absBuyTP);
   Print("������� SELL �������:", quantitySellOrders, "; ��������� �����: ����=", LotsSell, ", �����=", LastSellTicket, ", ������������� ��=", CurrentBuyTP, ", ���������� ��=", absSellTP);
  }


bool DetectSettedNewOrder()
  {
   Print("# ������� ������ ���������� ������� #");
   double preTime = 0;
   int orders = 0;
   int LastTicket;
   RefreshRates();
   for (int i=0; i<OrdersTotal(); i++)
     {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) continue;
      if (OrderMagicNumber() != IdNum) continue;
      if (OrderSymbol() != Symbol()) continue;
      // if (StringFind(OrderComment(), CommentOrder, 0) == -1) continue;
      orders++;
      if (OrderOpenTime() > preTime)
        {
         preTime = OrderOpenTime();
         LastTicket = OrderTicket();
        }
     }
   if (orders > quantityOrders && LastTicket != LastOrderTicket)
     {
      Print("������ ����� �����, �����=", LastTicket, ", ����� ������� = ", orders, "; ����� ���� ������� = ", quantityOrders, ", ������ �����", LastOrderTicket);
      ticket = LastTicket;
      LastOrderTicket = ticket;
      quantityOrders = orders;
      switch(OrderType())
        {
         case OP_BUY:
         SaveLastBuyOrderTicket(ticket);
         quantityBuyOrders++;
         ticketsB[quantityBuyOrders]=ticket;
         break;
         case OP_SELL:
         SaveLastSellOrderTicket(ticket);
         quantitySellOrders++;
         ticketsS[quantitySellOrders]=ticket;
         break;
        }
      return(true);
     }
   Print("����� ������� = ", orders, ", ����� ���������� = ", LastTicket);
   return(false);
  }


bool MiddlePriceForPeriod()
  {
   double MiddlePrice = (iHigh(Symbol(), PERIOD, iHighest(Symbol(), PERIOD, MODE_HIGH, PeriodMP, 0))
                        + iLow(Symbol(), PERIOD, iLowest(Symbol(), PERIOD, MODE_LOW, PeriodMP, 0))) / 2;
   if ((Bid <= MiddlePrice + DeviationMP*POINT) && (Bid >= MiddlePrice - DeviationMP*POINT)) return(true);
   else return(false);
  }


void SetFirstBuyOrder()
  {
   if (Trade == false) return;
   if ((Limiter == true) && (MiddlePriceForPeriod() == false)) return;
   Print("-+������� ��������� ������� BUY ������+-");
   DistanceBuy = calcDistance() + correctDistance*POINT;
   if (enable_min_distance == true && DistanceBuy < minDistance*POINT) DistanceBuy = minDistance*POINT; //���� ����������� ��������� �������
   if (GlobalVariableSet(distBuy_GV,DistanceBuy) == 0) {Print("��� ��������� ���������� ���������� �������� ������"); Print("������ #", GetLastError());}
   Print("��������� ����� BUY �������� �����������: ", DistanceBuy);
   CurrentBuyTP = DistanceBuy + correctTP*POINT;
   if (AutoLot == true) Lots = AccountBalance()/(deposit/firstlot);
   else Lots = DefaultLots;
   if (Lots < minLot) Lots = minLot;
   /* */
   Print("��������� ����� BUY ");
   SendOrder(OP_BUY);
   if (GetLastError()==0)
     {
      LastBuyOrderTicket = ticket; //���������� ����� �������� ������
      SaveLastBuyOrderTicket(ticket);
      ticketsB[quantityBuyOrders] = ticket;
      quantityBuyOrders++; //����������� ������� ������� �� 1.
      quantityOrders++;
      Print("����� ���������� �������.");
     }
   else {Print("��������� ������� ������ - ������!");}
  }

void SetFirstSellOrder()
  {
   if (Trade == false) return;
   if ((Limiter == true) && (MiddlePriceForPeriod() == false)) return;
   Print("-+������� ��������� ������� SELL ������+-");
   DistanceSell = calcDistance() + correctDistance*POINT;
   if (enable_min_distance == true && DistanceSell < minDistance*POINT) DistanceSell = minDistance*POINT; //���� ����������� ��������� �������
   if (GlobalVariableSet(distSell_GV,DistanceSell) == 0) {Print("��� ��������� ���������� ���������� �������� ������"); Print("������ #", GetLastError());}
   Print("��������� ����� SELL �������� �����������: ", DistanceSell);
   CurrentSellTP = DistanceSell + correctTP*POINT;
   if (AutoLot == true) Lots = AccountBalance()/(deposit/firstlot);
   else Lots = DefaultLots;
   if (Lots < minLot) Lots = minLot;
   /* */
   Print("��������� ����� SELL ");
   SendOrder(OP_SELL);
   if (GetLastError()==0)
     {
      LastSellOrderTicket = ticket; //���������� ����� �������� ������
      SaveLastSellOrderTicket(ticket);
      ticketsS[quantitySellOrders] = ticket;
      quantitySellOrders++; //����������� ������� ������� �� 1.
      quantityOrders++;
      Print("����� ���������� �������.");
     }
   else {Print("��������� ������� ������ - ������!");}
  }


bool LastBuyOrderClosed()
  {
   if (OrderSelect(LastBuyOrderTicket, SELECT_BY_TICKET)==false)
      {Print("-%������� �������� ������������� �������� BUY ������%- ", "������ ��� ������ ������: ", GetLastError()); return(true);}
   if (OrderCloseTime()==0) return(false);
   Print("������� BUY ����� ��� ������, ����� # ", LastBuyOrderTicket, ", ���������� ������� ����: ", quantityBuyOrders);
   quantityBuyOrders--;
   ticketsB[quantityBuyOrders] = 0;
   return(true);
  }

bool LastSellOrderClosed()
  {
   if (OrderSelect(LastSellOrderTicket, SELECT_BY_TICKET)==false)
      {Print("-%������� �������� ������������� �������� SELL ������%- ", "������ ��� ������ ������: ", GetLastError()); return(true);}
   if (OrderCloseTime()==0) return(false);
   Print("������� SELL ����� ��� ������, ����� # ", LastSellOrderTicket, ", ���������� ������� ����: ", quantitySellOrders);
   quantitySellOrders--;
   ticketsS[quantitySellOrders] = 0;
   return(true);
  }


void ClosedAllBuyOrders()
  {
   Print("-= ������� �������� ���� ���������� BUY ������� =-");
   int count;
   int k = 0;
   int OrderTicketMassive[30];
   ArrayInitialize(OrderTicketMassive,0);
   for (int t=0; t<OrdersTotal(); t++)  //���� ������ ������� ���������, ������� ������ ������� BUY �������
     {
      if (OrderSelect(t, SELECT_BY_POS, MODE_TRADES) == false) {Print("1-� ��������: ������, (OrderSelect)"); continue;}
      if (OrderMagicNumber() != IdNum) {Print("2-� ��������: ������, (OrderMagicNumber)"); continue;}
      if (OrderSymbol() != Symbol()) {Print("3-� ��������: ������, (OrderSymbol)"); continue;}
      if (OrderType() != OP_BUY) continue;
      Print("������ BUY �����, ����� = ", OrderTicket());
      count++;
      OrderTicketMassive[count] = OrderTicket();
     }
   for (int i=1; i <= count; i++)      //���� �������� ��������� �������
     {
      OrderSelect(OrderTicketMassive[i],SELECT_BY_TICKET);
      Print("�����: ����� #", OrderTicket(), ", ��� ������=", OrderType(), ", ������=", OrderSymbol(),
            ", ���� ��������=", OrderOpenPrice(), ", ������� ��=",OrderTakeProfit(), ", ����� �����=", OrderLots(),
            ", idNum=", OrderMagicNumber(), ", �����������=", OrderComment()); 
      bool err = true;
      while (err == true)
       {
        if (count < 1) break;
        RefreshRates();
        Print("����� = ", OrderTicket(), ", ����� = ", OrderLots(), ", ���� = ", Bid, "count =", count);
        OrderClose(OrderTicket(),OrderLots(),Bid,3,Blue);   //�������� BUY ������
        int error = CheckError();
        if (error == 0) {err = false; k++; Print("������ �������."); break;}
        if (error == ERR_INVALID_TICKET || error == ERR_INVALID_FUNCTION_PARAMVALUE) break;
        else Sleep(15000);
       }
     }
   Print("���������� ��������� �������: ", k);
   ArrayInitialize(ticketsB,0);
   quantityBuyOrders = 0;
  }

void ClosedAllSellOrders()
  {
   Print("-= ������� �������� ���� ���������� SELL ������� =-");
   int count;
   int k = 0;
   int OrderTicketMassive[30];
   ArrayInitialize(OrderTicketMassive,0);
   for (int t=0; t<OrdersTotal(); t++)  //���� ������ ������� ���������, ������� ������ ������� SELL �������
     {
      if (OrderSelect(t, SELECT_BY_POS, MODE_TRADES) == false) {Print("1-� ��������: ������, (OrderSelect)"); continue;}
      if (OrderMagicNumber() != IdNum) {Print("2-� ��������: ������, (OrderMagicNumber)"); continue;}
      if (OrderSymbol() != Symbol()) {Print("3-� ��������: ������, (OrderSymbol)"); continue;}
      if (OrderType() != OP_SELL) continue;
      Print("������ SELL �����, ����� = ", OrderTicket());
      count++;
      OrderTicketMassive[count] = OrderTicket();
     }
   for (int i=1; i <= count; i++)      //���� �������� ��������� �������
     {
      OrderSelect(OrderTicketMassive[i],SELECT_BY_TICKET);
      Print("�����: ����� #", OrderTicket(), ", ��� ������=", OrderType(), ", ������=", OrderSymbol(),
            ", ���� ��������=", OrderOpenPrice(), ", ������� ��=",OrderTakeProfit(), ", ����� �����=", OrderLots(),
            ", idNum=", OrderMagicNumber(), ", �����������=", OrderComment()); 
      bool err = true;
      while (err == true)
       {
        if (count < 1) break;
        RefreshRates();
        Print("����� = ", OrderTicket(), ", ����� = ", OrderLots(), ", ���� = ", Ask, "count =", count);
        OrderClose(OrderTicket(),OrderLots(),Ask,3,Red);    //�������� SELL ������
        int error = CheckError();
        if (error == 0) {err = false; k++; Print("������ �������."); break;}
        if (error == ERR_INVALID_TICKET || error == ERR_INVALID_FUNCTION_PARAMVALUE) break;
        else Sleep(15000);
       }
     }
   Print("���������� ��������� �������: ", k);
   ArrayInitialize(ticketsS,0);
   quantitySellOrders = 0;
  }


bool AllowSetNextBuyOrder()
  {
   if (quantityBuyOrders < 1) return(false); // ���� ������� ������ 1, �������, ���������� false
   if (OrderSelect(LastBuyOrderTicket,SELECT_BY_TICKET)==false) return(false);
   if (OrderOpenPrice()-DistanceBuy >= Ask) return(true);
   return(false);
  }

bool AllowSetNextSellOrder()
  {
   if (quantitySellOrders < 1) return(false); // ���� ������� ������ 1, �������, ���������� false
   if (OrderSelect(LastSellOrderTicket,SELECT_BY_TICKET)==false) return(false);
   if (OrderOpenPrice()+DistanceSell <= Bid) return(true);
   return(false);
  }


void SetNextBuyOrder()
  {
   if (OrderSelect(LastBuyOrderTicket,SELECT_BY_TICKET)==false) return;
   if (quantityBuyOrders > maxQOrders) return(2);
   if ((AccountFreeMarginCheck(Symbol(),OrderType(),OrderLots()*2)<=0) || (GetLastError()==134))
     {
      if (mess_printed == false)
        {
         Print("�� ���������� ����� ��� ��������� ���������� ������.");
         bool mess_printed = true;
        }
      return(-1); //�� ���������� ����� ��� ��������� ���������� ������
     }
   int ototal = OrdersTotal();
   Print("-@������� ��������� ���������� BUY ������@-");
   Lots = OrderLots()*2;
   Print("��������� ����� BUY ");
   SendOrder(OP_BUY);
   int error = CheckError();
   switch (error)
     {
      case 0: //ERR_NO_ERROR; ��� ������
       LastBuyOrderTicket = ticket;
       SaveLastBuyOrderTicket(ticket);
       ticketsB[quantityBuyOrders]=ticket;
       quantityBuyOrders++;
       quantityOrders++;
       Print("����� BUY ������� ����������, �����=", ticket);
       return(0);
      case 1: //ERR_NO_RESULT;  ��� ������, �� ��������� ����������
       Print("��������� ���������� �� ���-���� �����");
       RefreshRates();
       if (ototal < OrdersTotal() && DetectSettedNewOrder()==true) return(0);
      default:
       ticket = LastBuyOrderTicket;
       Print("����� �� �������.");
       Print("������ ����� 15 ���.");
       Sleep(15000);
     }
  }

void SetNextSellOrder()
  {
   if (OrderSelect(LastSellOrderTicket,SELECT_BY_TICKET)==false) return;
   if (quantitySellOrders > maxQOrders) return(2);
   if ((AccountFreeMarginCheck(Symbol(),OrderType(),OrderLots()*2)<=0) || (GetLastError()==134))
     {
      if (mess_printed == false)
        {
         Print("�� ���������� ����� ��� ��������� ���������� ������.");
         bool mess_printed = true;
        }
      return(-1); //�� ���������� ����� ��� ��������� ���������� ������
     }
   int ototal = OrdersTotal();
   Print("-@������� ��������� ���������� SELL ������@-");
   Lots = OrderLots()*2;
   Print("��������� ����� SELL ");
   SendOrder(OP_SELL);
   int error = CheckError();
   switch (error)
     {
      case 0: //ERR_NO_ERROR; ��� ������
       LastSellOrderTicket = ticket;
       SaveLastSellOrderTicket(ticket);
       ticketsS[quantitySellOrders]=ticket;
       quantitySellOrders++;
       quantityOrders++;
       Print("����� BUY ������� ����������, �����=", ticket);
       return(0);
      case 1: //ERR_NO_RESULT;  ��� ������, �� ��������� ����������
       Print("��������� ���������� �� ���-���� �����");
       RefreshRates();
       if (ototal < OrdersTotal() && DetectSettedNewOrder()==true) return(0);
      default:
       ticket = LastSellOrderTicket;
       Print("����� �� �������.");
       Print("������ ����� 15 ���.");
       Sleep(15000);
     }
  }


void SendOrder(int command)
  {
   RefreshRates();
   switch (command)
     {
      case OP_BUY: 
        TP = CurrentBuyTP;
        Print("����� ������� /\: ", "���� ���=", Ask, ", ������� ��=", Ask+TP, ", ������������� ��=", TP, ", �����=", Lots, ", distance=", DistanceBuy);
        ticket = OrderSend(Symbol(),OP_BUY,Lots,Ask,1,0,Ask+TP,CommentOrder,IdNum,0,Blue); 
        break;
      case OP_SELL: 
        TP = CurrentSellTP;
        Print("����� ������� \/: ", "���� ���=", Bid, ", ������� ��=", Bid-TP, ", ������������� ��=", TP, ", �����=", Lots, ", distance=", DistanceSell);
        ticket = OrderSend(Symbol(),OP_SELL,Lots,Bid,1,0,Bid-TP,CommentOrder,IdNum,0,Red);
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


double calcDistance()
  {
   calcDay = Day(); //���������� ���� ��������.
   if (ManualTP == 0) calcDist = MedATW() / 2;
   else calcDist = ManualTP * POINT;
   Print("������� ��������� �����������: ", calcDist);
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




