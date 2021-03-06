//+------------------------------------------------------------------+
//|                                                       levels.mq4 |
//|                                        Copyright © 2013,  GlobuX |
//|                                                gglobux@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2013,  GlobuX"
#property link      "globuq@gmail.com"
#include <stderror.mqh>

#define BUY       0
#define BUYLIMIT  2
#define BUYSTOP   4
#define SELL      1
#define SELLLIMIT 3
#define SELLSTOP  5

#define TICKET        1
#define TYPE          2
#define LOTS          3
#define OPEN_PRICE    4
#define STOP_LOSS     5
#define TAKE_PROFIT   6
#define MAGIC_NUMBER  7
#define COMMENT       8

extern int     takeprofit = 8;         // количество пунктов тейкпрофит
extern int     wl_level = 3;           // количество пунктов до безубыточности (исходя из уже установленных ордеров и этого параметра расчитывается лот для следующего ордера)
extern int     distance = 5;           // минимальное расстояние через которое может быть установлен следующий ордер
extern int     trail = 4;              // расстояние на котором будет устанавливаться стоп-ордер от максимумов и минимумов (трейлинг расстояние)
extern double  min_lot = 0.1;          // самый первый лот
extern double  max_lot = 10000;        // максимально допустимый лот
extern bool    Trade = true;           // торговля разрешена (при запрете торговли старые стоп-ордера удаляются, новые стоп-ордера не устанавливаются)
extern bool    Trade_to_Close = true;  // торговля до закрытия последнего ордера
extern bool    activeBuy =  true;      // остановить торговлю по Buy
extern bool    activeSell = true;      // отсановить торговлю по Sell
extern bool    auto_lot = false;       // лот расчитывается автоматически
extern double  depo_minlot = 25000;    // депозит на который расчитан начальный лот (нужен для расчета автолота)
extern double  LotValue = 10000;       //  размер контракта (размер лота в валюте)
extern int     Leverage = 1000;        //  кредитное плечо
extern int     MagicNumber = 555;      // Идентификатор советника (у каждоко советника должен быть свой ID, чтобы мог торговать параллельно с другими)
extern string  CommentOrder = "ML_v4.06.03";  // Martingale Levels Expert v4
extern int     LossAlert = 300;
extern int     TimeRealert = 180;

int ticket_sellstop = -1, ticket_buystop = -1;
//int sells = 0, buys = 0;
int ticket_last_sell, ticket_last_buy;
int time_b = 0;
int time_s = 0;

int ticket_sell[31];
int ticket_buy[31];
double lot, lot_01;
double NewOrdersTable[31][9]; 
double OldOrdersTable[31][9];
int OrdersNewCount[6];
int OrdersOldCount[6];
int BuyOrders;
int BuyStopOrders;
int SellOrders;
int SellStopOrders;
//int BuyLimitOrders;
//int SellLimitOrders;
double mid_price_buys, mid_price_sells;
double sum_lots_buys, sum_lots_sells;


//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
   ArrayInitialize(ticket_sell ,0);
   ArrayInitialize(ticket_buy ,0);
   lot_01 = min_lot;
   switch(UninitializeReason())
     {
      case REASON_CHARTCLOSE:  break;
      case REASON_REMOVE:      break;
      case REASON_RECOMPILE:   break;
      case REASON_CHARTCHANGE: break;
      case REASON_ACCOUNT:     break;
      case REASON_PARAMETERS:  ModifyTP(); break;
     }
   ViewInfo();
   return(0);
  }

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start() {
   if (auto_lot == true) {
      lot_01 = AccountBalance() / (depo_minlot / min_lot);
      if (lot_01 < min_lot) {lot_01 = min_lot;}
   } else {
      lot_01 = min_lot;
   }
   CheckOrders();
   //--------------// Блок BUY //--------------------------//
   if (BuyOrders == 0) {//Если нет установленных ордеров BUY, устанавливаем первый.
      SetFirstBuyStop();
   } else {
      if (BuyStopExist() == true) {
         if (IsPosibleTrailBuyStop() == true) TrailBuyStop(ticket_buystop);
      } else {
         ModifyBuys(); 
         if (AllowSetNextBuy()==true) SetNextBuyStop(); //Если условия позвояют устанавливаем следующий ордер BuyStop
      }
   }
   //--------------// Блок SELL //-------------------------//
   if (SellOrders == 0) { //Если нет установленных ордеров SELL, устанавливаем первый.
      SetFirstSellStop();
   } else {
      if (SellsStopExist() == true) {
         if (IsPosibleTrailSellStop() == true) TrailSellStop(ticket_sellstop);
      } else {
         ModifySells();
         if (AllowSetNextSell()==true) SetNextSellStop(); //Если условия позвояют устанавливаем следующий ордер SellStop
      }
   }
   //------------// Блок вывода информации //--------------//
  // ViewInfo(); // Вывод текущего состояния торговли

  }
//+------------------------------------------------------------------+


void CheckOrders()
  {
   int N = 0;                                     // Счётчик количества ордеров, обнуление счётчика
   ArrayCopy(OldOrdersTable, NewOrdersTable);   // Сохраняем предыдущую историю
   ArrayCopy(OrdersOldCount, OrdersNewCount);
   ArrayInitialize(NewOrdersTable, 0);           // Обнуление массива
   ArrayInitialize(OrdersCount, 0);              // Обнуление массива
   double min_price = 100000; double max_price = 0;
   int buys = 0; int sells = 0;
   BuyOrders  = 0; BuyStopOrders  = 0; //BuyLimitOrders  = 0;
   SellOrders = 0; SellStopOrders = 0; //SellLimitOrders = 0;
   double sum_lots_buys = 0; double sum_lots_sells = 0;  // Для подсчета средней цены
   double    sum_n_buys = 0; double    sum_n_sells = 0;  // Для подсчета средней цены
         mid_price_buys = 0;       mid_price_sells = 0;  // Для подсчета средней цены
   for(int i=0; i<OrdersTotal(); i++)           // Поиск по рыночным и отложенным ордерам
     {   // Если ордер не соответствует нашим требованиям продолжаем поиск
      if (OrderSelect(i,SELECT_BY_POS) == false) continue;
      if (OrderSymbol() != Symbol()) continue; 
      if (OrderMagicNumber() != MagicNumber) continue;
      // if (StringFind(OrderComment(), CommentOrder, 0) == -1) continue;
      N++;                                      // Увеличиваем счетчик количества ордеров
      OrdersNewCount[OrderType()]++;            // Количество ордеров по типам
      NewOrdersTable[N][TICKET]       = OrderTicket();       // Номер ордера
      NewOrdersTable[N][TYPE]         = OrderType();         // Тип ордера
      NewOrdersTable[N][LOTS]         = OrderLots();         // Количество лотов
      NewOrdersTable[N][OPEN_PRICE]   = OrderOpenPrice();    // Курс открытия ордера
      NewOrdersTable[N][STOP_LOSS]    = OrderStopLoss();     // Курс SL
      NewOrdersTable[N][TAKE_PROFIT]  = OrderTakeProfit();   // Курс ТР
      NewOrdersTable[N][MAGIC_NUMBER] = OrderMagicNumber();  // Магическое число 
      if (OrderComment() == "") NewOrdersTable[N][COMMENT]=0; // Если нет комментария
      else NewOrdersTable[N][COMMENT]=1;                      // Если есть комментарий
      // Запоминаем тикеты STOP-ордеров
      switch (OrderType())
        {
         case BUY:
           buys++; ticket_buy[buys] = OrderTicket();
           if (OrderOpenPrice() < min_price) {min_price = OrderOpenPrice(); ticket_last_buy = OrderTicket();}
           sum_lots_buys = sum_lots_buys + OrderLots();
           sum_n_buys = sum_n_buys + OrderOpenPrice() * OrderLots();
           break;
         case BUYSTOP:   ticket_buystop   = OrderTicket(); break;
       //case BUYLIMIT:  ticket_buylimit  = OrderTicket(); break;
         case SELL:
           sells++; ticket_sell[sells] = OrderTicket();
           if (OrderOpenPrice() > max_price) {max_price = OrderOpenPrice(); ticket_last_sell = OrderTicket();}
           sum_lots_sells = sum_lots_sells + OrderLots();
           sum_n_sells = sum_n_sells + OrderOpenPrice() * OrderLots();
           break;
         case SELLSTOP:  ticket_sellstop  = OrderTicket(); break;
       //case SELLLIMIT: ticket_selllimit = OrderTicket(); break;
         default: break;
        }
     }
   NewOrdersTable[0][0]=N;                      // Общее количество ордеров
   BuyOrders       = OrdersNewCount[BUY];
   BuyStopOrders   = OrdersNewCount[BUYSTOP];
 //BuyLimitOrders  = OrdersNewCount[BUYLIMIT];
   SellOrders      = OrdersNewCount[SELL];
   SellStopOrders  = OrdersNewCount[SELLSTOP];
 //SellLimitOrders = OrdersNewCount[SELLLIMIT];
   if (sum_lots_buys  != 0) mid_price_buys  = NormalizeDouble(sum_n_buys  / sum_lots_buys,  Digits);
   if (sum_lots_sells != 0) mid_price_sells = NormalizeDouble(sum_n_sells / sum_lots_sells, Digits);
  }


/*
void CheckOrdersStart()
  {
   buys = 0; sells = 0;
   int b_stop = 0, s_stop = 0;
   ticket_sellstop = -1; ticket_buystop = -1;
   double min_price = 100000, max_price = 0;
   for (int i=0; i<OrdersTotal(); i++)
     {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) continue;
      if ((OrderMagicNumber() != MagicNumber) || (OrderSymbol() != Symbol())) continue;
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
      if (OrderType() == OP_BUYSTOP) {b_stop++; if (b_stop > 1) {Print("!!! Больше одного ордера BUYSTOP !!!");}  continue;}
      if (OrderType() == OP_SELLSTOP) {s_stop++; if (s_stop > 1) {Print("!!! Больше одного ордера SELLSTOP !!!");}  continue;}
     }
  }
*/

/*
void CheckExistOrders()
  {
   buys = 0; sells = 0;
   ticket_sellstop = -1; ticket_buystop = -1;
   int min_price = 100000, max_price = 0;
   for (int i=0; i<OrdersTotal(); i++)
     {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) continue;
      if ((OrderMagicNumber() != MagicNumber) || (OrderSymbol() != Symbol())) continue;
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
*/

void ModifyTP()
  {
   if (IsTesting() == true) {return;}
   if (OrderExist(ticket_last_sell) == true) {double tp_s = OrderOpenPrice() - takeprofit*Point; double lot_s = OrderLots();}
   if (OrderExist(ticket_last_buy)  == true) {double tp_b = OrderOpenPrice() + takeprofit*Point; double lot_b = OrderLots();}
   for (int i=0; i<OrdersTotal(); i++)
     {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      switch (OrderType())
        {
         case  BUY:
           if (lot_b < max_lot) if (OrderTakeProfit() != tp_b) OrderModify(OrderTicket(), OrderOpenPrice(), 0, tp_b, 0,CLR_NONE);
           break;
         case SELL:
           if (lot_s < max_lot) if (OrderTakeProfit() != tp_s) OrderModify(OrderTicket(), OrderOpenPrice(), 0, tp_s, 0,CLR_NONE);
           break;
         default: break;
        }
     }
  }


bool OrderExist(int ticket)
  {
   if ((OrderSelect(ticket,SELECT_BY_TICKET) == false) return(false);
   if (OrderSymbol() != Symbol()) return(false); 
   if (OrderMagicNumber() != MagicNumber)) return(false);
   return(true);
  }


/*
bool CheckLastOrder(int ticket)
  {
   if ((OrderSelect(ticket,SELECT_BY_TICKET) == false) return(false)
   if (OrderMagicNumber() == MagicNumber)) return(true);
   else return(false);
  }


bool CheckStopOrderWorked(int ticket)
  {
   OrderSelect(ticket,SELECT_BY_TICKET);
   if ((OrderType() == OP_SELLSTOP) || (OrderType() == OP_BUYSTOP)) {return(false);}
   if ((OrderType() == OP_SELL) || (OrderType() == OP_BUY)) {return(true);}
  }
*/


bool BuyStopExist()
  {
   if (BuyStopOrders > 0) return(true);
   else return(false);
  }


bool SellStopExist()
  {
   if (SellStopOrders > 0) return(true);
   else return(false);
  }


bool IsPosibleTrailBuyStop()
  {
   if (NormalizeDouble(OrderOpenPrice(), Digits) > NormalizeDouble((Ask + trail*Point), Digits)) return(true);
   else return(false);
  }


bool IsPosibleTrailSellStop()
  {
   if (NormalizeDouble(OrderOpenPrice(), Digits) < NormalizeDouble((Bid - trail*Point), Digits)) return(true);
   else return(false);
  }


void TrailBuyStopOrder(int ticket)
  {
   OrderDelete(ticket, CLR_NONE);
   if (CheckError() != 0) return;
   ticket_buystop = SetBuyStopOrder();
   if (CheckError() != 0) ticket_buystop = -1;
  }


void TrailSellStopOrder(int ticket)
  {
   OrderDelete(ticket, CLR_NONE);
   if (CheckError() != 0) return;
   ticket_sellstop = SetSellStopOrder();
   if (CheckError() != 0) ticket_sellstop = -1;
  }


bool AllowSetNextBuy()
  {
   double price = NormalizeDouble(Ask + trail*Point, Digits);
   OrderSelect(ticket_last_buy,SELECT_BY_TICKET);
   if (OrderLots() >= max_lot) return(false);  // Если уже стоит ордер с максимальным лотом - больше ордеров не ставим
   if ((OrderOpenPrice()-distance*Point) < price) return(false);
   return(true);
  }


bool AllowSetNextSell()
  {
   double price = NormalizeDouble(Bid - trail*Point, Digits);
   OrderSelect(ticket_last_sell,SELECT_BY_TICKET);
   if (OrderLots() >= max_lot) return(false); // Если уже стоит ордер с максимальным лотом - больше ордеров не ставим
   if ((OrderOpenPrice()+distance*Point) > price) return(false);
   return(true);
  }


void SetFirstBuyStop()
  {
   double price = NormalizeDouble(Ask + trail*Point, Digits);
   double tp = price + takeprofit*Point;
   lot = lot_01;
   OrderSend(Symbol(),OP_BUYSTOP,lot,price,0,0,tp,"Martin",MagicNumber,0,Blue);
   if (CheckError() != 0) Print("Функция SetFirstBuyStop: ошибка при установке ордера");
  }


void SetFirstSellStop()
  {
   double price = NormalizeDouble(Bid - trail*Point, Digits); 
   double tp = price - takeprofit*Point;
   lot = lot_01;
   OrderSend(Symbol(),OP_SELLSTOP,lot,price,0,0,tp,"Martin",MagicNumber,0,Red);
   if (CheckError() != 0) Print("Функция SetFirstBuyStop: ошибка при установке ордера");
  }


void SetNextBuyStop()
  {
   double price = NormalizeDouble(Ask + trail*Point, Digits);
   double tp = price + takeprofit*Point;
   SetLotSize(price, BUY);
   if (lot > max_lot) {lot = max_lot; tp = NormalizeDouble(price + (mid_price_buys - price) / (max_lot / sum_lots_buys + 1) + (takeprofit - wl_level)*Point, Digits);}
   if (lot < lot_01) {lot = lot_01;}
   OrderSend(Symbol(),OP_BUYSTOP,lot,price,0,0,tp,"Martin",MagicNumber,0,Blue);
   if (CheckError() != 0) Print("Функция SetNextBuyStop: ошибка при установке очередного ордера");
  }


void SetNextSellStop()
  {
   double price = NormalizeDouble(Bid - trail*Point, Digits); 
   double tp = price - takeprofit*Point;
   SetLotSize(price, SELL);
   if (lot > max_lot) {lot = max_lot; tp = NormalizeDouble(price - ((price - mid_price_sells) / (sum_lots_sells / max_lot + 1)) - (takeprofit - wl_level)*Point, Digits);}
   if (lot < lot_01) {lot = lot_01;}
   OrderSend(Symbol(),OP_SELLSTOP,lot,price,0,0,tp,"Martin",MagicNumber,0,Red);
   if (CheckError() != 0) Print("Функция SetNextSellStop: ошибка при установке очередного ордера");
  }

/*
double CalculateBreakeven(double price, int order_type, double lots)
  {
   double sum_lots = 0;
   double sum_n = 0;
   double breakeven;
   for (int i=0; i<OrdersTotal(); i++)
    {
     if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) continue;
     if ((OrderSymbol() == Symbol()) && (OrderMagicNumber() == MagicNumber) && (OrderType() == order_type))
        {
         sum_lots = sum_lots + OrderLots();
         sum_n = sum_n + OrderOpenPrice() * OrderLots();
        }
    }
   if (sum_lots == 0) return (0);
   double mid_price = NormalizeDouble(sum_n / sum_lots, Digits);
   if (order_type == OP_BUY) {breakeven = (mid_price - price) / (lots / sum_lots + 1);}
   if (order_type == OP_SELL) {breakeven = (price - mid_price) / (sum_lots / lots + 1);}
   return(NormalizeDouble(breakeven, Digits)); // уровень безубытка
  }
*/


/*
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
     if (CheckError() != 0) {ticket = -1; Print("Функция SetSellStopOrder: ошибка при установке ордера");}
     return(ticket);
    }
   if (buys > 0)
    {
     OrderSelect(ticket_last_buy,SELECT_BY_TICKET);
     if ((OrderOpenPrice()-distance*Point) < price) return(ticket);
     if (OrderLots() >= max_lot) return(ticket);  // Если уже стоит ордер с максимальным лотом - больше не ставим
     SetLotSize(price, OP_BUY);
     if (lot > max_lot) {lot = max_lot; tp = price + CalculateBreakeven(price,OP_BUY,max_lot) + (takeprofit - wl_level)*Point;}
     if (lot < lot_01) {lot = lot_01;}
     ticket = OrderSend(Symbol(),OP_BUYSTOP,lot,price,0,0,tp,"Martin",MagicNumber,0,Blue);
     OrderSelect(ticket,SELECT_BY_TICKET);
     if ((OrderOpenTime() == 0) && (OrderOpenPrice() == 0)) ticket = -1;
     if (CheckError() != 0) {ticket = -1; Print("Функция SetSellStopOrder: ошибка при установке ордера");}
     return(ticket);
    }
   return(ticket);
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
     if (CheckError() != 0) {ticket = -1; Print("Функция SetSellStopOrder: ошибка при установке ордера");}
     return(ticket);
    }
   if (sells > 0)
    {
     OrderSelect(ticket_last_sell,SELECT_BY_TICKET);
     if ((OrderOpenPrice()+distance*Point) > price) return(ticket);
     if (OrderLots() >= max_lot) return(ticket); // Если уже стоит ордер с максимальным лотом - больше не ставим
     SetLotSize(price, OP_SELL);
     if (lot > max_lot) {lot = max_lot; tp = price - CalculateBreakeven(price, OP_SELL, max_lot) - (takeprofit - wl_level)*Point;}
     if (lot < lot_01) {lot = lot_01;}
     ticket = OrderSend(Symbol(),OP_SELLSTOP,lot,price,0,0,tp,"Martin",MagicNumber,0,Red);
     OrderSelect(ticket,SELECT_BY_TICKET);
     if ((OrderOpenTime() == 0) && (OrderOpenPrice() == 0)) ticket = -1;
     if (CheckError() != 0) {ticket = -1; Print("Функция SetSellStopOrder: ошибка при установке ордера");}
     return(ticket);
    }
   return(ticket);
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
     if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) continue;
     if ((OrderMagicNumber() != MagicNumber) || (OrderSymbol() != Symbol())) continue;
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

   Comment("          | лотов | стоим. п. | б/у | до слива \r\n",
           "BUY:  | ", sumlots_buy, " | ", pipscost_buy, " | ", mid_buy, " | ", pips_to_loss_buy, " | \r\n",
           "SELL: | ", sumlots_sell, " | ", pipscost_sell, " | ", mid_sell, " | ", pips_to_loss_sell, " | \r\n",
           "Расчет вместе со STOP-ордерами\r\n",
           "          | лотов | стоим. п. | б/у | до слива \r\n",
           "BUYSTOP:  | ", sumlotsBS, " | ", pipscostBS, " | ", mid_BS, " | ", pips_to_loss_BS, " | \r\n",
           "SELLSTOP: | ", sumlotsSS, " | ", pipscostSS, " | ", mid_SS, " | ", pips_to_loss_SS, " | ");
  }


void ModifyBuys()
  {
   if (BuyOrders < 2) return;    //если установленных ордеров меньше двух, то ничего менять не надо
   OrderSelect(ticket_last_buy, SELECT_BY_TICKET);
   double tp = OrderTakeProfit();
   for (int i = 1; i < BuyOrders; i++)
    {
     OrderSelect(ticket_buy[i], SELECT_BY_TICKET);
     if (OrderTakeProfit() != tp) OrderModify(OrderTicket(), OrderOpenPrice(), 0, tp, 0,CLR_NONE);
     if (CheckError() != 0) Print("Функция ModifyBuys: ошибка при модификации ордера");
    }
  }


void ModifySells()
  {
   if (SellOrders < 2) {return;}    //если установленных ордеров меньше двух, то ничего менять не надо
   OrderSelect(ticket_last_sell, SELECT_BY_TICKET);
   double tp = OrderTakeProfit();
   for (int i = 1; i < SellOrders; i++)
    {
     OrderSelect(ticket_sell[i], SELECT_BY_TICKET);
     if (OrderTakeProfit() != tp) OrderModify(OrderTicket(), OrderOpenPrice(), 0, tp, 0,CLR_NONE);
     if (CheckError() != 0) Print("Функция ModifyBuys: ошибка при модификации ордера");
    }
  }


/*
void ModifyBuys()
  {
   if (buys < 2) {return;}    //если установленных ордеров меньше двух, то ничего менять не надо
   OrderSelect(ticket_last_buy, SELECT_BY_TICKET);
   double tp = OrderTakeProfit();
   for (int i = 1; i < buys; i++)
    {
     OrderSelect(ticket_buy[i], SELECT_BY_TICKET);
     OrderModify(OrderTicket(), OrderOpenPrice(), 0, tp, 0,CLR_NONE);
    }
  }


void ModifySells()
  {
   if (sells < 2) {return;}    //если установленных ордеров меньше двух, то ничего менять не надо
   OrderSelect(ticket_last_sell, SELECT_BY_TICKET);
   double tp = OrderTakeProfit();
   for (int i=1; i<sells; i++)
    {
     OrderSelect(ticket_sell[i], SELECT_BY_TICKET);
     OrderModify(OrderTicket(), OrderOpenPrice(), 0, tp, 0,CLR_NONE);
    }
  }
*/


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
       pips_cost = OrderLots() * LotValue * Point; // стоимость 1 пипса для текущего ордера
       pips = MathAbs((price - wl_level*Point - OrderOpenPrice()) / Point);  // количество пипсов для расчета
       loss = loss + pips * pips_cost;   // убыток при пройденном расстоянии в pips
      }
    }
   if (order_type == OP_BUY)
    {
     for (i=1; i<=buys; i++)
      {
       OrderSelect(ticket_buy[i], SELECT_BY_TICKET);
       pips_cost = OrderLots() * LotValue * Point; // стоимость 1 пипса для текущего ордера
       pips = MathAbs((OrderOpenPrice() - (price + wl_level*Point)) / Point);  // количество пипсов для расчета
       loss = loss + pips * pips_cost;   // убыток при пройденном расстоянии в pips
      }
    }
   pips_cost = loss / wl_level;    //  Стоимость пункта для расчитываемого ордера
   lot = pips_cost / LotValue / Point;   // Размер для расчитываемого ордера
  } 




/*
void TrailingSellStop(int ticket)
  {
   if (OrderSelect(ticket,SELECT_BY_TICKET) == true) return;
   if ((OrderMagicNumber() != MagicNumber) || (OrderSymbol() != Symbol())) return;
   if (NormalizeDouble(OrderOpenPrice(), Digits) < NormalizeDouble((Bid - trail*Point), Digits))  
    {
     OrderDelete(ticket, CLR_NONE);
     if (CheckError() == 0)
      {
       if (((Trade == true) && (Trade_to_Close == true)) || ((Trade == false) && (Trade_to_Close == true))) {ticket_sellstop = SetSellStopOrder();}
         //else {if ((Trade_to_Close == true) && (sells > 0)) {ticket_sellstop = SetSellStopOrder();}}
      }
    }
  }
*/


/*
void TrailingBuyStop(int ticket)
  {
   if (OrderSelect(ticket,SELECT_BY_TICKET) == false) return;
   if ((OrderMagicNumber() != MagicNumber) || (OrderSymbol() != Symbol())) return;
   if (NormalizeDouble(OrderOpenPrice(), Digits) > NormalizeDouble((Ask + trail*Point), Digits)) 
    {
     OrderDelete(ticket, CLR_NONE);
     if (CheckError() == 0)
      {
       if (((Trade == true) && (Trade_to_Close == true)) || ((Trade == false) && (Trade_to_Close == true))) {ticket_buystop = SetBuyStopOrder();}
         //else {if ((Trade_to_Close == true) && (buys > 0)) {ticket_buystop = SetBuyStopOrder();}}
      }
    }
  }
*/



int CheckError()
  {
  int Error = GetLastError();
  switch (Error)
    {
     case ERR_NO_ERROR:
       /*Print("Нет ошибки."); */ break;
     case ERR_NO_RESULT:
       Print("Нет ошибки, но результат неизвестен (параметры не изменены)"); break;
     case ERR_COMMON_ERROR:
       Print("Общая ошибка"); break;
     case ERR_INVALID_TRADE_PARAMETERS:
       Print("Ошибка: Неправильные параметры"); break;
     case ERR_SERVER_BUSY:
       Print("Ошибка: Торговый сервер занят"); break;
     case ERR_OLD_VERSION:
       Print("Ошибка: Старая версия клиентского терминала"); break;
     case ERR_NO_CONNECTION:
       Print("Ошибка: Нет связи с торговым сервером"); break;
     case ERR_NOT_ENOUGH_RIGHTS:
       Print("Ошибка: Недостаточно прав"); break;
     case ERR_TOO_FREQUENT_REQUESTS:
       Print("Ошибка: Слишком частые запросы"); break;
     case ERR_MALFUNCTIONAL_TRADE:
       Print("Ошибка: Недопустимая операция нарушающая функционирование сервера"); break;
     case ERR_ACCOUNT_DISABLED:
       Print("Ошибка: Счет заблокирован"); break;
     case ERR_INVALID_ACCOUNT:
       Print("Ошибка: Неправильный номер счета"); break;
     case ERR_TRADE_TIMEOUT:
       Print("Ошибка: Истек срок ожидания совершения сделки"); break;
     case ERR_INVALID_PRICE:
       Print("Ошибка: Неправильная цена"); break;
     case ERR_INVALID_STOPS:
       Print("Ошибка: Неправильные стопы"); break;
     case ERR_INVALID_TRADE_VOLUME:
       Print("Ошибка: Неправильный объем"); break;
     case ERR_MARKET_CLOSED:
       Print("Ошибка: Рынок закрыт"); break;
     case ERR_TRADE_DISABLED:
       Print("Ошибка: Торговля запрещена"); break;
     case ERR_NOT_ENOUGH_MONEY:
       Print("Ошибка: Недостаточно денег для совершения операции"); break;
     case ERR_PRICE_CHANGED:
       Print("Ошибка: Цена изменилась"); break;
     case ERR_OFF_QUOTES:
       Print("Ошибка: Нет цен"); break;
     case ERR_BROKER_BUSY:
       Print("Ошибка: Брокер занят"); break;
     case ERR_REQUOTE:
       Print("Ошибка: Новые цены"); break;
     case ERR_ORDER_LOCKED:
       Print("Ошибка: Ордер заблокирован и уже обрабатывается"); break;
     case ERR_LONG_POSITIONS_ONLY_ALLOWED:
       Print("Ошибка: Разрешена только покупка"); break;
     case ERR_TOO_MANY_REQUESTS:
       Print("Ошибка: Слишком много запросов"); break;
     case ERR_TRADE_MODIFY_DENIED:
       Print("Ошибка: Модификация запрещена, так как ордер слишком близок к рынку"); break;
     case ERR_TRADE_CONTEXT_BUSY:
       Print("Ошибка: Подсистема торговли занята"); break;
     case ERR_TRADE_EXPIRATION_DENIED:
       Print("Ошибка: Использование даты истечения ордера запрещено брокером"); break;
     case ERR_TRADE_TOO_MANY_ORDERS:
       Print("Ошибка: Количество открытых и отложенных ордеров достигло предела, установленного брокером"); break;
     default:
       Print("Ошибка: не опознана, посмотрите по каталогу, №", Error); break;
    }
   return(Error); 
  }