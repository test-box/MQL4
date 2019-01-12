//+------------------------------------------------------------------+
//|                                                       levels.mq4 |
//|                                        Copyright � 2012,  GlobuX |
//|                                                 globuq@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright � 2013,  GlobuX"
#property link      "globuq@gmail.com"
#include <stderror.mqh>


extern int     takeprofit     = 8;     // ���������� ������� ����������
extern int     wl_level       = 3;     // ���������� ������� �� �������������� (������ �� ��� ������������� ������� � ����� ��������� ������������� ��� ��� ���������� ������)
extern int     distance       = 5;     // ����������� ���������� ����� ������� ����� ���� ���������� ��������� �����
extern int     trail          = 4;     // ���������� �� ������� ����� ��������������� ����-����� �� ���������� � ��������� (�������� ����������)
extern double  min_lot        = 0.1;   // ����� ������ ���
extern double  max_lot        = 10000; // ����������� ���������� ���
extern bool    Trade          = true;  // �������� ��������� (��� ������� �������� ������ ����-������ ���������, ����� ����-������ �� ���������������)
extern bool    Trade_to_Close = true;  // �������� �� �������� ���������� ������
extern bool    auto_lot       = false; // ��� ������������� �������������
extern double  depo_minlot    = 25000; // ������� �� ������� �������� ��������� ��� (����� ��� ������� ��������)
extern double  LotValue       = 10000; // ������ ��������� (������ ���� � ������)
extern int     Leverage       = 1000;  // ��������� �����
extern int     MagicNumber    = 555;   // ������������� ��������� (� ������� ��������� ������ ���� ���� ID, ����� ��� ��������� ����������� � �������)
extern int     LossAlert      = 300;
extern int     TimeRealert    = 180;

int ticket_sell[50];
int ticket_buy[50];
int ticket_sellstop = -1, ticket_buystop = -1;
int sells = 0, buys = 0;
int ticket_last_sell, ticket_last_buy;
double lot, lot_01;
int time_b = 0;
int time_s = 0;

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
   ArrayInitialize(ticket_sell ,0);
   ArrayInitialize(ticket_buy ,0);
   CheckExistOrders();
   lot_01 = min_lot;
   ViewInfo();
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
   if (auto_lot == true)
    {
     lot_01 = AccountBalance() / (depo_minlot / min_lot);
     if (lot_01 < min_lot) {lot_01 = min_lot;}
    }
   else {lot_01 = min_lot;}
   CheckOrdersStart();
   if (OrderExist(ticket_sellstop) == true)
    {
     if (CheckStopOrderWorked(ticket_sellstop) == true)
      {
       PlaySound("sell.wav");
       ModifySells();
       ticket_sellstop = SetSellStopOrder();
      }
     else {TrailingSellStop(ticket_sellstop);}
    }
   else {if (Trade == true) {ticket_sellstop = SetSellStopOrder();}}

   if (OrderExist(ticket_buystop) == true)
    {
     if (CheckStopOrderWorked(ticket_buystop) == true)
      {
       PlaySound("buy.wav");
       ModifyBuys();
       ticket_buystop = SetBuyStopOrder();
      }
     else {TrailingBuyStop(ticket_buystop);}
    }
   else {if (Trade == true) {ticket_buystop = SetBuyStopOrder();}}
   ModifyTP();
   ViewInfo();
   return(0);
  }
//+------------------------------------------------------------------+


void CheckOrdersStart()
  {
   buys = 0; sells = 0;
   int b_stop = 0, s_stop = 0;
   double min_price = 100000, max_price = 0;
   for (int i=0; i<OrdersTotal(); i++)
     {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) continue;
      if ((OrderCloseTime() != 0) || (OrderMagicNumber() != MagicNumber)) continue;
      if (OrderType() == OP_BUY)
        {
         buys++;
         ticket_buy[buys] = OrderTicket();
         if (OrderOpenPrice() < min_price) {min_price = OrderOpenPrice(); ticket_last_buy = OrderTicket();}
         continue;
        }
      if (OrderType() == OP_SELL)
        {
         sells++;
         ticket_sell[sells] = OrderTicket();
         if (OrderOpenPrice() > max_price) {max_price = OrderOpenPrice(); ticket_last_sell = OrderTicket();}
         continue;
        }
      if (OrderType() == OP_BUYSTOP) {b_stop++; if (b_stop > 1) {Print("!!! ������ ������ ������ BUYSTOP !!!");}  continue;}
      if (OrderType() == OP_SELLSTOP) {s_stop++; if (s_stop > 1) {Print("!!! ������ ������ ������ SELLSTOP !!!");}  continue;}
     }
  }


void CheckExistOrders()
  {
   buys = 0; sells = 0;
   ticket_sellstop = -1; ticket_buystop = -1;
   int min_price = 100000, max_price = 0;
   for (int i=0; i<OrdersTotal(); i++)
     {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) continue;
      if ((OrderCloseTime() != 0) || (OrderMagicNumber() != MagicNumber)) continue;
      if (OrderType() == OP_SELL)
        {
         sells++; ticket_sell[sells] = OrderTicket();
         if (OrderOpenPrice() > max_price) {max_price = OrderOpenPrice(); ticket_last_sell = OrderTicket();}
         continue;
        }
      if (OrderType() == OP_BUY)
        {
         buys++; ticket_buy[buys] = OrderTicket();
         if (OrderOpenPrice() < min_price) {min_price = OrderOpenPrice(); ticket_last_buy = OrderTicket();}
         continue;
        }
      if (OrderType() == OP_SELLSTOP) {ticket_sellstop = OrderTicket(); continue;}
      if (OrderType() == OP_BUYSTOP) {ticket_buystop = OrderTicket();}
     }
  }


void ModifyTP()
  {
   if (IsTesting() == true) {return;}
   if (OrderExist(ticket_last_sell) == true) {double tp_s = OrderOpenPrice() - takeprofit*Point; double lot_s = OrderLots();}
   if (OrderExist(ticket_last_buy) == true) {double tp_b = OrderOpenPrice() + takeprofit*Point; double lot_b = OrderLots();}
   for (int i=0; i<OrdersTotal(); i++)
    {
     if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == true)
      {
       if ((OrderCloseTime() != 0) && (OrderMagicNumber() != MagicNumber)) continue;
        {
         if ((OrderType() == OP_SELL) && (lot_s < max_lot))
          {
           if (OrderTakeProfit() != tp_s) OrderModify(OrderTicket(), OrderOpenPrice(), 0, tp_s, 0,CLR_NONE);
          }
         if ((OrderType() == OP_BUY) && (lot_b < max_lot))
          {
           if (OrderTakeProfit() != tp_b) OrderModify(OrderTicket(), OrderOpenPrice(), 0, tp_b, 0,CLR_NONE);
          }
        }
      }
    }
  }


bool OrderExist(int ticket)
  {
   if ((OrderSelect(ticket,SELECT_BY_TICKET) == true) && (OrderMagicNumber() == MagicNumber) && (OrderCloseTime() == 0)) {return(true);}
   else {return(false);}
  }


bool CheckStopOrderWorked(int ticket)
  {
   OrderSelect(ticket,SELECT_BY_TICKET);
   if ((OrderType() == OP_SELLSTOP) || (OrderType() == OP_BUYSTOP)) {return(false);}
   if ((OrderType() == OP_SELL) || (OrderType() == OP_BUY)) {return(true);}
  }


void TrailingSellStop(int ticket)
  {
   if ((OrderSelect(ticket,SELECT_BY_TICKET) == true) && (OrderCloseTime() ==0) && (OrderMagicNumber() == MagicNumber))
    {
     if (NormalizeDouble(OrderOpenPrice(), Digits) < NormalizeDouble((Bid - trail*Point), Digits))  
      {
       OrderDelete(ticket, CLR_NONE);
       if (CheckError() == 0)
        {
         if (Trade == true) {ticket_sellstop = SetSellStopOrder();}
         else {if ((Trade_to_Close == true) && (sells != 0)) {ticket_sellstop = SetSellStopOrder();}}
        }
      }
    }
  }


void TrailingBuyStop(int ticket)
  {
   if ((OrderSelect(ticket,SELECT_BY_TICKET) == true) && (OrderCloseTime() ==0))
    {
     if (NormalizeDouble(OrderOpenPrice(), Digits) > NormalizeDouble((Ask + trail*Point), Digits)) 
      {
       OrderDelete(ticket, CLR_NONE);
       if (CheckError() == 0)
        {
         if (Trade == true) {ticket_buystop = SetBuyStopOrder();}
         else {if ((Trade_to_Close == true) && (buys != 0)) {ticket_buystop = SetBuyStopOrder();}}
        }
      }
    }
  }


int SetSellStopOrder()
  {
   double price = NormalizeDouble(Bid - trail*Point, Digits); 
   double tp = price - takeprofit*Point;
   int ticket = -1;
   if (sells == 0)
    {
     lot = lot_01;
     ticket = OrderSend(Symbol(),OP_SELLSTOP,lot,price,0,0,tp,"Martin",MagicNumber,0,Red);
     OrderSelect(ticket,SELECT_BY_TICKET);
     if ((OrderOpenTime() == 0) && (OrderOpenPrice() == 0)) ticket = -1;
     if (CheckError() != 0) {ticket = -1; Print("������� SetSellStopOrder: ������ ��� ��������� ������");}
     return(ticket);
    }
   if (sells > 0)
    {
     OrderSelect(ticket_last_sell,SELECT_BY_TICKET);
     if ((OrderOpenPrice()+distance*Point) > price) return(ticket);
     if (OrderLots() >= max_lot) return(ticket); // ���� ��� ����� ����� � ������������ ����� - ������ �� ������
     SetLotSize(price, OP_SELL);
     if (lot > max_lot) {lot = max_lot; tp = price - CalculateBreakeven(price, OP_SELL, max_lot) - (takeprofit - wl_level)*Point;}
     if (lot < lot_01) {lot = lot_01;}
     ticket = OrderSend(Symbol(),OP_SELLSTOP,lot,price,0,0,tp,"Martin",MagicNumber,0,Red);
     OrderSelect(ticket,SELECT_BY_TICKET);
     if ((OrderOpenTime() == 0) && (OrderOpenPrice() == 0)) ticket = -1;
     if (CheckError() != 0) {ticket = -1; Print("������� SetSellStopOrder: ������ ��� ��������� ������");}
     return(ticket);
    }
   return(ticket);
  }


int SetBuyStopOrder()
  {
   double price = NormalizeDouble(Ask + trail*Point, Digits);
   double tp = price + takeprofit*Point;
   int ticket = -1;
   if (buys == 0)
    {
     lot = lot_01;
     ticket = OrderSend(Symbol(),OP_BUYSTOP,lot,price,0,0,tp,"Martin",MagicNumber,0,Blue);
     OrderSelect(ticket,SELECT_BY_TICKET);
     if ((OrderOpenTime() == 0) && (OrderOpenPrice() == 0)) ticket = -1;
     if (CheckError() != 0) {ticket = -1; Print("������� SetSellStopOrder: ������ ��� ��������� ������");}
     return(ticket);
    }
   if (buys > 0)
    {
     OrderSelect(ticket_last_buy,SELECT_BY_TICKET);
     if ((OrderOpenPrice()-distance*Point) < price) return(ticket);
     if (OrderLots() >= max_lot) return(ticket);  // ���� ��� ����� ����� � ������������ ����� - ������ �� ������
     SetLotSize(price, OP_BUY);
     if (lot > max_lot) {lot = max_lot; tp = price + CalculateBreakeven(price,OP_BUY,max_lot) + (takeprofit - wl_level)*Point;}
     if (lot < lot_01) {lot = lot_01;}
     ticket = OrderSend(Symbol(),OP_BUYSTOP,lot,price,0,0,tp,"Martin",MagicNumber,0,Blue);
     OrderSelect(ticket,SELECT_BY_TICKET);
     if ((OrderOpenTime() == 0) && (OrderOpenPrice() == 0)) ticket = -1;
     if (CheckError() != 0) {ticket = -1; Print("������� SetSellStopOrder: ������ ��� ��������� ������");}
     return(ticket);
    }
   return(ticket);
  }


double CalculateBreakeven(double price, int order_type, double lots)
  {
   double sum_lots = 0;
   double sum_pl = 0;
   double breakeven;
   for (int i=0; i<OrdersTotal(); i++)
    {
     if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == true)
      {
       if ((OrderType() == order_type) && (OrderMagicNumber() == MagicNumber) && (OrderCloseTime() == 0))
        {
         sum_lots = sum_lots + OrderLots();
         sum_pl = sum_pl + OrderOpenPrice() * OrderLots();
        }
      }
    }
   if (sum_lots == 0) {return (0);}
   double mid_price = NormalizeDouble(sum_pl / sum_lots, Digits);
   if (order_type == OP_BUY) {breakeven = (mid_price - price) / (lots / sum_lots + 1);}
   if (order_type == OP_SELL) {breakeven = (price - mid_price) / (sum_lots / lots + 1);}
   return(NormalizeDouble(breakeven, Digits)); // ������� ���������
  }

/*
double ViewInfo()
  { 
   if (IsTesting() == true) {if (IsVisualMode() == false) return;}
   double sumlots_buy = 0;
   double sumlots_sell = 0;
   double sum_buy = 0;
   double sum_sell = 0;
   int spread = MarketInfo(Symbol(),MODE_SPREAD);
   for (int i=0; i<OrdersTotal(); i++)
    {
     if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == true)
      {
       if ((OrderType() == OP_BUY) && (OrderMagicNumber() == MagicNumber) && (OrderCloseTime() == 0))
        {
         sumlots_buy = sumlots_buy + OrderLots();
         sum_buy = sum_buy + OrderOpenPrice() * OrderLots();
        }
       if ((OrderType() == OP_SELL) && (OrderMagicNumber() == MagicNumber) && (OrderCloseTime() == 0))
        {
         sumlots_sell = sumlots_sell + OrderLots();
         sum_sell = sum_sell + OrderOpenPrice() * OrderLots();
        }
      }
    }
   if (OrderExist(ticket_buystop)) 
    {
     double sumlots_BS = sumlots_buy + OrderLots();
     double sum_BS = sum_buy + OrderOpenPrice() * OrderLots();
     if (sumlots_BS != 0) {double mid_BS = NormalizeDouble(sum_BS / sumlots_BS, Digits);}
     double pipscost_BS = sumlots_BS * LotValue * Point;
     double equity_BS = AccountBalance() - ((mid_BS - OrderOpenPrice() + (Ask - Bid)) / Point * pipscost_BS);
     if (pipscost_BS != 0) {int pips_to_loss_BS = MathFloor(equity_BS / pipscost_BS);}
    }
   if (OrderExist(ticket_sellstop)) 
    {
     double sumlots_SS = sumlots_sell + OrderLots();
     double sum_SS = sum_sell + OrderOpenPrice() * OrderLots();
     if (sumlots_SS != 0) {double mid_SS = NormalizeDouble(sum_SS / sumlots_SS, Digits);}
     double pipscost_SS = sumlots_SS * LotValue * Point;
     double equity_SS = AccountBalance() - ((OrderOpenPrice() - mid_SS + (Ask - Bid)) / Point * pipscost_SS);
     if (pipscost_SS != 0) {int pips_to_loss_SS = MathFloor(equity_SS / pipscost_SS);}
    }
   if (sumlots_buy != 0) {double mid_buy = NormalizeDouble(sum_buy / sumlots_buy, Digits);}
   if (sumlots_sell != 0) {double mid_sell = NormalizeDouble(sum_sell / sumlots_sell, Digits);}
   double pipscost_buy = sumlots_buy * LotValue * Point;
   double pipscost_sell = sumlots_sell * LotValue * Point;
   if (pipscost_buy != 0) {int pips_to_loss_buy = MathFloor(AccountEquity() / pipscost_buy) - spread;}
   if (pipscost_sell != 0) {int pips_to_loss_sell = MathFloor(AccountEquity() / pipscost_sell) - spread;}
   Comment("          | ����� | �����. �. | �/� | �� ����� \r\n",
           "BUY:  | ", sumlots_buy, " | ", pipscost_buy, " | ", mid_buy, " | ", pips_to_loss_buy, " | \r\n",
           "SELL: | ", sumlots_sell, " | ", pipscost_sell, " | ", mid_sell, " | ", pips_to_loss_sell, " | ");
  }
*/

void ViewInfo()
  {
   if (IsTesting() == true) {if (IsVisualMode() == false) return;}
   double sumlots_buy = 0;
   double sumlots_sell = 0;
   double sum_buy = 0;
   double sum_sell = 0;
   double profit_BS = 0;
   double profit_SS = 0;
   if (OrderExist(ticket_buystop)) {double lots_BS = OrderLots(); double price_BS = OrderOpenPrice();}
   if (OrderExist(ticket_sellstop)) {double lots_SS = OrderLots(); double price_SS = OrderOpenPrice();}
   int spread = MarketInfo(Symbol(),MODE_SPREAD);
   for (int i=0; i<OrdersTotal(); i++)
    {
     if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == true)
      {
       if ((OrderMagicNumber() == MagicNumber) && (OrderCloseTime() == 0))
        {
         double pips_cost = OrderLots() * LotValue * Point;
         if (OrderType() == OP_BUY)
          {
           sumlots_buy = sumlots_buy + OrderLots();
           sum_buy = sum_buy + OrderOpenPrice() * OrderLots();
           profit_BS = profit_BS + (price_BS - OrderOpenPrice()) / Point * pips_cost;
           profit_SS = profit_SS + (price_SS - OrderOpenPrice()) / Point * pips_cost;
          }
         if (OrderType() == OP_SELL)
          {
           sumlots_sell = sumlots_sell + OrderLots();
           sum_sell = sum_sell + OrderOpenPrice() * OrderLots();
           profit_BS = profit_BS + (OrderOpenPrice() - price_BS) / Point * pips_cost;
           profit_SS = profit_SS + (OrderOpenPrice() - price_SS) / Point * pips_cost;
          }
        }
      }
    }
   if (sumlots_buy != 0) {double mid_buy = NormalizeDouble(sum_buy / sumlots_buy, Digits);}
   if (sumlots_sell != 0) {double mid_sell = NormalizeDouble(sum_sell / sumlots_sell, Digits);}
   double pipscost_buy = sumlots_buy * LotValue * Point;
   double pipscost_sell = sumlots_sell * LotValue * Point;
   if (pipscost_buy != 0) {int pips_to_loss_buy = MathFloor(AccountEquity() / pipscost_buy) - spread;}
   if (pipscost_sell != 0) {int pips_to_loss_sell = MathFloor(AccountEquity() / pipscost_sell) - spread;}
   if (OrderExist(ticket_buystop))
    {
     double sumlotsBS = sumlots_buy + lots_BS;
     double sumBS = sum_buy + price_BS * lots_BS;
     if (sumlotsBS != 0) {double mid_BS = NormalizeDouble(sumBS / sumlotsBS, Digits);}
     double pipscostBS = sumlotsBS * LotValue * Point;
     double equity_BS =  AccountBalance() + profit_BS - spread * lots_BS * LotValue * Point;
     if (pipscostBS != 0)
      {
       int pips_to_loss_BS = MathFloor(equity_BS / pipscostBS) - spread;
       if ((pips_to_loss_BS < LossAlert) && (time_b+TimeRealert*1000 < GetTickCount())) {time_b = GetTickCount(); PlaySound("lossalarm.wav");}
      }
    }
   if (OrderExist(ticket_sellstop))
    {
     double sumlotsSS = sumlots_sell + lots_SS;
     double sumSS = sum_sell + price_SS * lots_SS;
     if (sumlotsSS != 0) {double mid_SS = NormalizeDouble(sumSS / sumlotsSS, Digits);}
     double pipscostSS = sumlotsSS * LotValue * Point;
     double equity_SS =  AccountBalance() + profit_SS - spread * lots_SS * LotValue * Point;
     if (pipscostSS != 0)
      {
       int pips_to_loss_SS = MathFloor(equity_SS / pipscostSS) - spread;
       if ((pips_to_loss_SS < LossAlert) && (time_s+TimeRealert*1000 < GetTickCount())) {time_s = GetTickCount(); PlaySound("lossalarm.wav");}
      }
    }

   Comment("          | ����� | �����. �. | �/� | �� ����� \r\n",
           "BUY:  | ", sumlots_buy, " | ", pipscost_buy, " | ", mid_buy, " | ", pips_to_loss_buy, " | \r\n",
           "SELL: | ", sumlots_sell, " | ", pipscost_sell, " | ", mid_sell, " | ", pips_to_loss_sell, " | \r\n",
           "������ ������ �� STOP-��������\r\n",
           "          | ����� | �����. �. | �/� | �� ����� \r\n",
           "BUYSTOP:  | ", sumlotsBS, " | ", pipscostBS, " | ", mid_BS, " | ", pips_to_loss_BS, " | \r\n",
           "SELLSTOP: | ", sumlotsSS, " | ", pipscostSS, " | ", mid_SS, " | ", pips_to_loss_SS, " | ");
  }


void ModifySells()
  {
   if (sells < 2) {return;}    //���� ������������� ������� ������ ����, �� ������ ������ �� ����
   OrderSelect(ticket_last_sell, SELECT_BY_TICKET);
   double tp = OrderTakeProfit();
   for (int i=1; i<sells; i++)
    {
     OrderSelect(ticket_sell[i], SELECT_BY_TICKET);
     OrderModify(OrderTicket(), OrderOpenPrice(), 0, tp, 0,CLR_NONE);
    }
  }


void ModifyBuys()
  {
   if (buys < 2) {return;}    //���� ������������� ������� ������ ����, �� ������ ������ �� ����
   OrderSelect(ticket_last_buy, SELECT_BY_TICKET);
   double tp = OrderTakeProfit();
   for (int i=1; i<buys; i++)
    {
     OrderSelect(ticket_buy[i], SELECT_BY_TICKET);
     OrderModify(OrderTicket(), OrderOpenPrice(), 0, tp, 0,CLR_NONE);
    }
  }


double SetLotSize(double price, int order_type)
  { 
   double loss = 0;
   double pips_cost = 0;
   double pips = 0;
   if (order_type == OP_SELL)
    {
     for (int i=1; i<=sells; i++)
      {
       OrderSelect(ticket_sell[i], SELECT_BY_TICKET);
       pips_cost = OrderLots() * LotValue * Point; // ��������� 1 ����� ��� �������� ������
       pips = MathAbs((price - wl_level*Point - OrderOpenPrice()) / Point);  // ���������� ������ ��� �������
       loss = loss + pips * pips_cost;   // ������ ��� ���������� ���������� � pips
      }
    }
   if (order_type == OP_BUY)
    {
     for (i=1; i<=buys; i++)
      {
       OrderSelect(ticket_buy[i], SELECT_BY_TICKET);
       pips_cost = OrderLots() * LotValue * Point; // ��������� 1 ����� ��� �������� ������
       pips = MathAbs((OrderOpenPrice() - (price + wl_level*Point)) / Point);  // ���������� ������ ��� �������
       loss = loss + pips * pips_cost;   // ������ ��� ���������� ���������� � pips
      }
    }
   pips_cost = loss / wl_level;    //  ��������� ������ ��� �������������� ������
   lot = pips_cost / LotValue / Point;   // ������ ��� �������������� ������
  } 


int CheckError()
  {
  int Error = GetLastError();
  if (Error == ERR_NO_ERROR)
    {
    // Print("��� ������.");
    return(Error);
    }
  if (Error == ERR_NO_RESULT)
    {
    Print("��� ������, �� ��������� ���������� (��������� �� ��������)");
    return(Error);
    }
  if (Error == ERR_COMMON_ERROR)
    {
    Print("����� ������");
    return(Error);
    }
  if (Error == ERR_INVALID_TRADE_PARAMETERS)
    {
    Print("������: ������������ ���������");
    return(Error);
    }
  if (Error == ERR_SERVER_BUSY)
    {
    Print("������: �������� ������ �����");
    return(Error);
    }
  if (Error == ERR_OLD_VERSION)
    {
    Print("������: ������ ������ ����������� ���������");
    return(Error);
    }
  if (Error == ERR_NO_CONNECTION)
    {
    Print("������: ��� ����� � �������� ��������");
    return(Error);
    }
  if (Error == ERR_NOT_ENOUGH_RIGHTS)
    {
    Print("������: ������������ ����");
    return(Error);
    }
  if (Error == ERR_TOO_FREQUENT_REQUESTS)
    {
    Print("������: ������� ������ �������");
    return(Error);
    }
  if (Error == ERR_MALFUNCTIONAL_TRADE)
    {
    Print("������: ������������ �������� ���������� ���������������� �������");
    return(Error);
    }
  if (Error == ERR_ACCOUNT_DISABLED)
    {
    Print("������: ���� ������������");
    return(Error);
    }
  if (Error == ERR_INVALID_ACCOUNT)
    {
    Print("������: ������������ ����� �����");
    return(Error);
    }
  if (Error == ERR_TRADE_TIMEOUT)
    {
    Print("������: ����� ���� �������� ���������� ������");
    return(Error);
    }
  if (Error == ERR_INVALID_PRICE)
    {
    Print("������: ������������ ����");
    return(Error);
    }
  if (Error == ERR_INVALID_STOPS)
    {
    Print("������: ������������ �����");
    return(Error);
    }
  if (Error == ERR_INVALID_TRADE_VOLUME)
    {
    Print("������: ������������ �����");
    return(Error);
    }
  if (Error == ERR_MARKET_CLOSED)
    {
    Print("������: ����� ������");
    return(Error);
    }
  if (Error == ERR_TRADE_DISABLED)
    {
    Print("������: �������� ���������");
    return(Error);
    }
  if (Error == ERR_NOT_ENOUGH_MONEY)
    {
    Print("������: ������������ ����� ��� ���������� ��������");
    return(Error);
    }
  if (Error == ERR_PRICE_CHANGED)
    {
    Print("������: ���� ����������");
    return(Error);
    }
  if (Error == ERR_OFF_QUOTES)
    {
    Print("������: ��� ���");
    return(Error);
    }
  if (Error == ERR_BROKER_BUSY)
    {
    Print("������: ������ �����");
    return(Error);
    }
  if (Error == ERR_REQUOTE)
    {
    Print("������: ����� ����");
    return(Error);
    }
  if (Error == ERR_ORDER_LOCKED)
    {
    Print("������: ����� ������������ � ��� ��������������");
    return(Error);
    }
  if (Error == ERR_LONG_POSITIONS_ONLY_ALLOWED)
    {
    Print("������: ��������� ������ �������");
    return(Error);
    }
  if (Error == ERR_TOO_MANY_REQUESTS)
    {
    Print("������: ������� ����� ��������");
    return(Error);
    }
  if (Error == ERR_TRADE_MODIFY_DENIED)
    {
    Print("������: ����������� ���������, ��� ��� ����� ������� ������ � �����");
    return(Error);
    }
  if (Error == ERR_TRADE_CONTEXT_BUSY)
    {
    Print("������: ���������� �������� ������");
    return(Error);
    }
  if (Error == ERR_TRADE_EXPIRATION_DENIED)
    {
    Print("������: ������������� ���� ��������� ������ ��������� ��������");
    return(Error);
    }
  if (Error == ERR_TRADE_TOO_MANY_ORDERS)
    {
    Print("������: ���������� �������� � ���������� ������� �������� �������, �������������� ��������");
    return(Error);
    }
  if (Error != 0)
    {
    Print("������: �� ��������, ���������� �� ��������, �", Error);
    return(Error);
    }
  }