//+------------------------------------------------------------------+
//|                                                    ATW_07_00.mq4 |
//|                                         Copyright © 2012, GlobuX |
//|                                                 globuq@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2012, GlobuX"
#property link      "globuq@gmail.com"
#include <stderror.mqh>

//---------Переменные-параметры-эксперта---------//
extern bool    Trade = true;            // продолжать торговлю или нет после закрытия всех сделок
extern int     correctTP = 34;          // корректировка ТЕЙКПРОФИТА
extern int     correctDistance = 12;    // корректировка ДИСТАНЦИИ
extern bool    AutoLot = true;          // автоматический расчет лотов, если TRUE
extern double  minLot = 0.01;           // минимальный лот, который допускает брокер
extern double  firstlot = 0.07;         // количестов лотов для первого ордера в расчете на DEPOSIT
extern double  deposit = 1000;          // DEPOSIT для расчета лотов первого ордера
extern int     maxQOrders = 7;          // максимальное количество установленных ордеров
extern int     PeriodMV = 10;           // период для расчета дистанции между ордерами
extern bool    Limiter = false;         // Включение условий для установки первого ордера
extern int     PeriodMP = 1;            // период для расчета отклонения текущей от средней цены, в единицах периода (если PERIOD=60, то 24 будет означать сутки)
extern int     PERIOD = 1440;           // размер единицы периода в минутах, 1-1 минута, 5-5 минут, 15-15 минут, 30-30 минут, 60-1 час, 240-4 часа, 1440-1 день, 10080-1 неделя, 43200-1 месяц; СТРОГО ЭТИ ЗНАЧЕНИЯ!!!
extern int     DeviationMP = 25;        // отклонение текущей цены от средней
extern int     ManualTP = 0;            // жесткий не регулируемый ТЕЙКПРОФИТ, если 0, то не учитывается
extern double  DefaultLots = 0.05;      // количество лотов для первого ордера, если не установлен АВТОЛОТ
extern bool    calcLastWeek = false;    // подсчет ДИСТАНЦИИ по периоду PeriodMV не включая текущую неделю, если TRUE
extern int     IdNum = 700;             // идентификатор советника, необходим для распознования советником своих ордеров
extern string  CommentOrder = "ATW_v7.0";   // комментарий к устанавливаемым ордерам, для визуального опознования ордеров советника
extern bool    enable_min_distance = true; // задействовать минимальную дистанцию, если TRUE
extern int     minDistance = 60;        // минимальная дистанция между ордерами, возможно отключить

//--------Глобальные переменные терминала----------//
double DistanceBuy;
double DistanceSell;
string distBuy_GV;
string distSell_GV;
int    LastOrderTicket;
int    LastBuyOrderTicket;
int    LastSellOrderTicket;
string lastticketBuy_GV;
string lastticketSell_GV;

//--------Глобальные переменные эксперта----------//
int    calcDay;
double MedianATW;
double CurrentBuyTP;    //Берется с уже установленных ордеров
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
   Print("Советник: ATWv07x, инициализация. ", "IdNum: ", IdNum, ", CommentOrder: ", CommentOrder);
   if (Point < 0.0001) POINT = Point*10;
   else POINT = Point;
   ArrayInitialize(ticketsB,0);
   ArrayInitialize(ticketsS,0);
   distBuy_GV="ATW_"+Symbol()+"_distBuy";  //Устанавливаем название глобальной переменной (Distance)
   distSell_GV="ATW_"+Symbol()+"_distSell";  //Устанавливаем название глобальной переменной (Distance)
   Print("distBuy_GV=", distBuy_GV, ", distSell_GV=", distSell_GV);
   if (GlobalVariableCheck(distBuy_GV))
     {
      DistanceBuy = GlobalVariableGet(distBuy_GV);
      Print("Предыдущие настройки: дистанция между BUY ордерами: ", DistanceBuy);
     }
   if (GlobalVariableCheck(distSell_GV))
     {
      DistanceSell = GlobalVariableGet(distSell_GV);
      Print("Предыдущие настройки: дистанция между SELL ордерами: ", DistanceSell);
     }
   lastticketBuy_GV="ATW_"+Symbol()+"_lastticketBuy";  //Устанавливаем название глобальной переменной (lastticket)
   lastticketSell_GV="ATW_"+Symbol()+"_lastticketSell";  //Устанавливаем название глобальной переменной (lastticket)
   Print("lastticketBuy_GV=", lastticketBuy_GV, ", lastticketSell_GV=", lastticketSell_GV);
   if (GlobalVariableCheck(lastticketBuy_GV))
     {
      LastBuyOrderTicket = GlobalVariableGet(lastticketBuy_GV);
      Print("Предыдущие настройки: тикет последнего ордера: ", LastBuyOrderTicket);
     }
   if (GlobalVariableCheck(lastticketSell_GV))
     {
      LastSellOrderTicket = GlobalVariableGet(lastticketSell_GV);
      Print("Предыдущие настройки: тикет последнего ордера: ", LastSellOrderTicket);
     }
   if (DistanceBuy < minDistance*POINT) DistanceBuy = calcDistance() + correctDistance*POINT;
   if (DistanceSell < minDistance*POINT) DistanceSell = calcDistance() + correctDistance*POINT;
   FindOrders(); //Поиск существующих ордеров
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
   //if (TimeDay(TimeCurrent())!= calcDay) {calcDistance();}//если наступил следующий день, пересчитываем дистанцию.
   /* Блок BUY ордеров */
   if (quantityBuyOrders==0) SetFirstBuyOrder();               //Если нет установленных BUY ордеров, устанавливаем первый,
   else if (LastBuyOrderClosed()==true) ClosedAllBuyOrders();  //иначе Если крайний BUY ордер закрыт, то закрываем остальные BUY ордера,
   else if (AllowSetNextBuyOrder()==true) SetNextBuyOrder();   //иначе Если условия позвояют устанавливаем следующий BUY ордер с удвоеенным лотом.
   /* Блок SELL ордеров */
   if (quantitySellOrders==0) SetFirstSellOrder();             //Если нет установленных SELL ордеров, устанавливаем первый,
   else if (LastSellOrderClosed()==true) ClosedAllSellOrders();//иначе Если крайний SELL ордер закрыт, то закрываем остальные SELL ордера,
   else if (AllowSetNextSellOrder()==true) SetNextSellOrder(); //иначе Если условия позвояют устанавливаем следующий SELL ордер с удвоеенным лотом.
   return(0);
  }


//+------------------------------------------------------------------+


bool ExistHistory()
  {
   if (iBars(NULL,PERIOD_D1) == 0 || GetLastError() == 4066)
     {
      Print("Загружается история...");
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
      Print("При установке глобальной переменной lastticket_GV возникла ошибка");
      Print("Ошибка #", GetLastError());
     }
  }

void SaveLastSellOrderTicket(int ticket)
  {
   if (GlobalVariableSet(lastticketSell_GV, ticket) == 0)
     {
      Print("При установке глобальной переменной lastticket_GV возникла ошибка");
      Print("Ошибка #", GetLastError());
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
   Print("Найдено BUY ордеров:", quantityBuyOrders, "; последний ордер: лоты=", LotsBuy, ", тикет=", LastBuyTicket, ", относительный ТП=", CurrentBuyTP, ", абсолютный ТП=", absBuyTP);
   Print("Найдено SELL ордеров:", quantitySellOrders, "; последний ордер: лоты=", LotsSell, ", тикет=", LastSellTicket, ", относительный ТП=", CurrentBuyTP, ", абсолютный ТП=", absSellTP);
  }


bool DetectSettedNewOrder()
  {
   Print("# Функция поиска неучтенных ордеров #");
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
      Print("Найден новый ордер, тикет=", LastTicket, ", всего ордеров = ", orders, "; ранее было ордеров = ", quantityOrders, ", старый тикет", LastOrderTicket);
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
   Print("Всего ордеров = ", orders, ", тикет последнего = ", LastTicket);
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
   Print("-+Функция установки первого BUY ордера+-");
   DistanceBuy = calcDistance() + correctDistance*POINT;
   if (enable_min_distance == true && DistanceBuy < minDistance*POINT) DistanceBuy = minDistance*POINT; //если минимальная дистанция активна
   if (GlobalVariableSet(distBuy_GV,DistanceBuy) == 0) {Print("При установке глобальной переменной возникла ошибка"); Print("Ошибка #", GetLastError());}
   Print("Дистанция между BUY ордерами установлена: ", DistanceBuy);
   CurrentBuyTP = DistanceBuy + correctTP*POINT;
   if (AutoLot == true) Lots = AccountBalance()/(deposit/firstlot);
   else Lots = DefaultLots;
   if (Lots < minLot) Lots = minLot;
   /* */
   Print("Отправлен ордер BUY ");
   SendOrder(OP_BUY);
   if (GetLastError()==0)
     {
      LastBuyOrderTicket = ticket; //Запоминаем тикет крайнего ордера
      SaveLastBuyOrderTicket(ticket);
      ticketsB[quantityBuyOrders] = ticket;
      quantityBuyOrders++; //увеличиваем счетчик ордеров на 1.
      quantityOrders++;
      Print("Ордер установлен успешно.");
     }
   else {Print("Установка первого ордера - ОШИБКА!");}
  }

void SetFirstSellOrder()
  {
   if (Trade == false) return;
   if ((Limiter == true) && (MiddlePriceForPeriod() == false)) return;
   Print("-+Функция установки первого SELL ордера+-");
   DistanceSell = calcDistance() + correctDistance*POINT;
   if (enable_min_distance == true && DistanceSell < minDistance*POINT) DistanceSell = minDistance*POINT; //если минимальная дистанция активна
   if (GlobalVariableSet(distSell_GV,DistanceSell) == 0) {Print("При установке глобальной переменной возникла ошибка"); Print("Ошибка #", GetLastError());}
   Print("Дистанция между SELL ордерами установлена: ", DistanceSell);
   CurrentSellTP = DistanceSell + correctTP*POINT;
   if (AutoLot == true) Lots = AccountBalance()/(deposit/firstlot);
   else Lots = DefaultLots;
   if (Lots < minLot) Lots = minLot;
   /* */
   Print("Отправлен ордер SELL ");
   SendOrder(OP_SELL);
   if (GetLastError()==0)
     {
      LastSellOrderTicket = ticket; //Запоминаем тикет крайнего ордера
      SaveLastSellOrderTicket(ticket);
      ticketsS[quantitySellOrders] = ticket;
      quantitySellOrders++; //увеличиваем счетчик ордеров на 1.
      quantityOrders++;
      Print("Ордер установлен успешно.");
     }
   else {Print("Установка первого ордера - ОШИБКА!");}
  }


bool LastBuyOrderClosed()
  {
   if (OrderSelect(LastBuyOrderTicket, SELECT_BY_TICKET)==false)
      {Print("-%Функция проверки существования крайнего BUY ордера%- ", "Ошибка при выборе ордера: ", GetLastError()); return(true);}
   if (OrderCloseTime()==0) return(false);
   Print("Крайний BUY ордер был закрыт, тикет # ", LastBuyOrderTicket, ", количество ордеров было: ", quantityBuyOrders);
   quantityBuyOrders--;
   ticketsB[quantityBuyOrders] = 0;
   return(true);
  }

bool LastSellOrderClosed()
  {
   if (OrderSelect(LastSellOrderTicket, SELECT_BY_TICKET)==false)
      {Print("-%Функция проверки существования крайнего SELL ордера%- ", "Ошибка при выборе ордера: ", GetLastError()); return(true);}
   if (OrderCloseTime()==0) return(false);
   Print("Крайний SELL ордер был закрыт, тикет # ", LastSellOrderTicket, ", количество ордеров было: ", quantitySellOrders);
   quantitySellOrders--;
   ticketsS[quantitySellOrders] = 0;
   return(true);
  }


void ClosedAllBuyOrders()
  {
   Print("-= Функция закрытия всех оставшихся BUY ордеров =-");
   int count;
   int k = 0;
   int OrderTicketMassive[30];
   ArrayInitialize(OrderTicketMassive,0);
   for (int t=0; t<OrdersTotal(); t++)  //Цикл поиска ордеров советника, создает массив тикетов BUY ордеров
     {
      if (OrderSelect(t, SELECT_BY_POS, MODE_TRADES) == false) {Print("1-я проверка: ошибка, (OrderSelect)"); continue;}
      if (OrderMagicNumber() != IdNum) {Print("2-я проверка: ошибка, (OrderMagicNumber)"); continue;}
      if (OrderSymbol() != Symbol()) {Print("3-я проверка: ошибка, (OrderSymbol)"); continue;}
      if (OrderType() != OP_BUY) continue;
      Print("Найден BUY ордер, тикет = ", OrderTicket());
      count++;
      OrderTicketMassive[count] = OrderTicket();
     }
   for (int i=1; i <= count; i++)      //Цикл удаления найденных ордеров
     {
      OrderSelect(OrderTicketMassive[i],SELECT_BY_TICKET);
      Print("Ордер: тикет #", OrderTicket(), ", тип ордера=", OrderType(), ", валюта=", OrderSymbol(),
            ", цена открытия=", OrderOpenPrice(), ", уровень ТП=",OrderTakeProfit(), ", объем лотов=", OrderLots(),
            ", idNum=", OrderMagicNumber(), ", комментарий=", OrderComment()); 
      bool err = true;
      while (err == true)
       {
        if (count < 1) break;
        RefreshRates();
        Print("Тикет = ", OrderTicket(), ", лотов = ", OrderLots(), ", цена = ", Bid, "count =", count);
        OrderClose(OrderTicket(),OrderLots(),Bid,3,Blue);   //Закрытие BUY ордера
        int error = CheckError();
        if (error == 0) {err = false; k++; Print("Удален успешно."); break;}
        if (error == ERR_INVALID_TICKET || error == ERR_INVALID_FUNCTION_PARAMVALUE) break;
        else Sleep(15000);
       }
     }
   Print("Количество удаленных ордеров: ", k);
   ArrayInitialize(ticketsB,0);
   quantityBuyOrders = 0;
  }

void ClosedAllSellOrders()
  {
   Print("-= Функция закрытия всех оставшихся SELL ордеров =-");
   int count;
   int k = 0;
   int OrderTicketMassive[30];
   ArrayInitialize(OrderTicketMassive,0);
   for (int t=0; t<OrdersTotal(); t++)  //Цикл поиска ордеров советника, создает массив тикетов SELL ордеров
     {
      if (OrderSelect(t, SELECT_BY_POS, MODE_TRADES) == false) {Print("1-я проверка: ошибка, (OrderSelect)"); continue;}
      if (OrderMagicNumber() != IdNum) {Print("2-я проверка: ошибка, (OrderMagicNumber)"); continue;}
      if (OrderSymbol() != Symbol()) {Print("3-я проверка: ошибка, (OrderSymbol)"); continue;}
      if (OrderType() != OP_SELL) continue;
      Print("Найден SELL ордер, тикет = ", OrderTicket());
      count++;
      OrderTicketMassive[count] = OrderTicket();
     }
   for (int i=1; i <= count; i++)      //Цикл удаления найденных ордеров
     {
      OrderSelect(OrderTicketMassive[i],SELECT_BY_TICKET);
      Print("Ордер: тикет #", OrderTicket(), ", тип ордера=", OrderType(), ", валюта=", OrderSymbol(),
            ", цена открытия=", OrderOpenPrice(), ", уровень ТП=",OrderTakeProfit(), ", объем лотов=", OrderLots(),
            ", idNum=", OrderMagicNumber(), ", комментарий=", OrderComment()); 
      bool err = true;
      while (err == true)
       {
        if (count < 1) break;
        RefreshRates();
        Print("Тикет = ", OrderTicket(), ", лотов = ", OrderLots(), ", цена = ", Ask, "count =", count);
        OrderClose(OrderTicket(),OrderLots(),Ask,3,Red);    //Закрытие SELL ордера
        int error = CheckError();
        if (error == 0) {err = false; k++; Print("Удален успешно."); break;}
        if (error == ERR_INVALID_TICKET || error == ERR_INVALID_FUNCTION_PARAMVALUE) break;
        else Sleep(15000);
       }
     }
   Print("Количество удаленных ордеров: ", k);
   ArrayInitialize(ticketsS,0);
   quantitySellOrders = 0;
  }


bool AllowSetNextBuyOrder()
  {
   if (quantityBuyOrders < 1) return(false); // Если ордеров меньше 1, выходим, возвращаем false
   if (OrderSelect(LastBuyOrderTicket,SELECT_BY_TICKET)==false) return(false);
   if (OrderOpenPrice()-DistanceBuy >= Ask) return(true);
   return(false);
  }

bool AllowSetNextSellOrder()
  {
   if (quantitySellOrders < 1) return(false); // Если ордеров меньше 1, выходим, возвращаем false
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
         Print("Не достаточно маржи для установки следующего ордера.");
         bool mess_printed = true;
        }
      return(-1); //Не достаточно маржи для установки следующего ордера
     }
   int ototal = OrdersTotal();
   Print("-@Функция установки следующего BUY ордера@-");
   Lots = OrderLots()*2;
   Print("Отправлен ордер BUY ");
   SendOrder(OP_BUY);
   int error = CheckError();
   switch (error)
     {
      case 0: //ERR_NO_ERROR; Нет ошибки
       LastBuyOrderTicket = ticket;
       SaveLastBuyOrderTicket(ticket);
       ticketsB[quantityBuyOrders]=ticket;
       quantityBuyOrders++;
       quantityOrders++;
       Print("Ордер BUY успешно установлен, тикет=", ticket);
       return(0);
      case 1: //ERR_NO_RESULT;  Нет ошибки, но результат неизвестен
       Print("Проверяем установлен ли все-таки ордер");
       RefreshRates();
       if (ototal < OrdersTotal() && DetectSettedNewOrder()==true) return(0);
      default:
       ticket = LastBuyOrderTicket;
       Print("Тикет не изменен.");
       Print("Делаем паузу 15 сек.");
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
         Print("Не достаточно маржи для установки следующего ордера.");
         bool mess_printed = true;
        }
      return(-1); //Не достаточно маржи для установки следующего ордера
     }
   int ototal = OrdersTotal();
   Print("-@Функция установки следующего SELL ордера@-");
   Lots = OrderLots()*2;
   Print("Отправлен ордер SELL ");
   SendOrder(OP_SELL);
   int error = CheckError();
   switch (error)
     {
      case 0: //ERR_NO_ERROR; Нет ошибки
       LastSellOrderTicket = ticket;
       SaveLastSellOrderTicket(ticket);
       ticketsS[quantitySellOrders]=ticket;
       quantitySellOrders++;
       quantityOrders++;
       Print("Ордер BUY успешно установлен, тикет=", ticket);
       return(0);
      case 1: //ERR_NO_RESULT;  Нет ошибки, но результат неизвестен
       Print("Проверяем установлен ли все-таки ордер");
       RefreshRates();
       if (ototal < OrdersTotal() && DetectSettedNewOrder()==true) return(0);
      default:
       ticket = LastSellOrderTicket;
       Print("Тикет не изменен.");
       Print("Делаем паузу 15 сек.");
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
        Print("Ордер Покупки /\: ", "цена аск=", Ask, ", уровень ТП=", Ask+TP, ", относительный ТП=", TP, ", лотов=", Lots, ", distance=", DistanceBuy);
        ticket = OrderSend(Symbol(),OP_BUY,Lots,Ask,1,0,Ask+TP,CommentOrder,IdNum,0,Blue); 
        break;
      case OP_SELL: 
        TP = CurrentSellTP;
        Print("Ордер Продажи \/: ", "цена бид=", Bid, ", уровень ТП=", Bid-TP, ", относительный ТП=", TP, ", лотов=", Lots, ", distance=", DistanceSell);
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
   calcDay = Day(); //Запоминаем день подсчета.
   if (ManualTP == 0) calcDist = MedATW() / 2;
   else calcDist = ManualTP * POINT;
   Print("Базовая дистанция пересчитана: ", calcDist);
   return(calcDist);
  }


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
     case ERR_TRADE_HEDGE_PROHIBITED:
       Print("Ошибка: Попытка открыть противоположную позицию к уже существующей в случае, если хеджирование запрещено"); break;
     case ERR_TRADE_PROHIBITED_BY_FIFO:
       Print("Ошибка: Попытка закрыть позицию по инструменту в противоречии с правилом FIFO."); break;
     case ERR_NO_MQLERROR:
       /*Print("Ошибка: Нет ошибки");*/ break;
     case ERR_WRONG_FUNCTION_POINTER:
       Print("Ошибка: Неправильный указатель функции"); break;
     case ERR_ARRAY_INDEX_OUT_OF_RANGE:
       Print("Ошибка: Индекс массива - вне диапазона"); break;
     case ERR_NO_MEMORY_FOR_CALL_STACK:
       Print("Ошибка: Нет памяти для стека функций"); break;
     case ERR_RECURSIVE_STACK_OVERFLOW:
       Print("Ошибка: Переполнение стека после рекурсивного вызова"); break;
     case ERR_NOT_ENOUGH_STACK_FOR_PARAM:
       Print("Ошибка: На стеке нет памяти для передачи параметров"); break;
     case ERR_NO_MEMORY_FOR_PARAM_STRING:
       Print("Ошибка: Нет памяти для строкового параметра"); break;
     case ERR_NO_MEMORY_FOR_TEMP_STRING:
       Print("Ошибка: Нет памяти для временной строки"); break;
     case ERR_NOT_INITIALIZED_STRING:
       Print("Ошибка: Неинициализированная строка"); break;
     case ERR_NOT_INITIALIZED_ARRAYSTRING:
       Print("Ошибка: Неинициализированная строка в массиве"); break;
     case ERR_NO_MEMORY_FOR_ARRAYSTRING:
       Print("Ошибка: Нет памяти для строкового массива"); break;
     case ERR_TOO_LONG_STRING:
       Print("Ошибка: Слишком длинная строка"); break;
     case ERR_REMAINDER_FROM_ZERO_DIVIDE:
       Print("Ошибка: Остаток от деления на ноль"); break;
     case ERR_ZERO_DIVIDE:
       Print("Ошибка: Деление на ноль"); break;
     case ERR_UNKNOWN_COMMAND:
       Print("Ошибка: Неизвестная команда"); break;
     case ERR_WRONG_JUMP:
       Print("Ошибка: Неправильный переход"); break;
     case ERR_NOT_INITIALIZED_ARRAY:
       Print("Ошибка: Неинициализированный массив"); break;
     case ERR_DLL_CALLS_NOT_ALLOWED:
       Print("Ошибка: Вызовы DLL не разрешены"); break;
     case ERR_CANNOT_LOAD_LIBRARY:
       Print("Ошибка: Невозможно загрузить библиотеку"); break;
     case ERR_CANNOT_CALL_FUNCTION:
       Print("Ошибка: Невозможно вызвать функцию"); break;
     case ERR_EXTERNAL_CALLS_NOT_ALLOWED:
       Print("Ошибка: Вызовы внешних библиотечных функций не разрешены"); break;
     case ERR_NO_MEMORY_FOR_RETURNED_STR:
       Print("Ошибка: Недостаточно памяти для строки, возвращаемой из функции"); break;
     case ERR_SYSTEM_BUSY:
       Print("Ошибка: Система занята"); break;
     case ERR_INVALID_FUNCTION_PARAMSCNT:
       Print("Ошибка: Неправильное количество параметров функции"); break;
     case ERR_INVALID_FUNCTION_PARAMVALUE:
       Print("Ошибка: Недопустимое значение параметра функции"); break;
     case ERR_STRING_FUNCTION_INTERNAL:
       Print("Ошибка: Внутренняя ошибка строковой функции"); break;
     case ERR_SOME_ARRAY_ERROR:
       Print("Ошибка: Ошибка массива"); break;
     case ERR_INCORRECT_SERIESARRAY_USING:
       Print("Ошибка: Неправильное использование массива-таймсерии"); break;
     case ERR_CUSTOM_INDICATOR_ERROR:
       Print("Ошибка: Ошибка пользовательского индикатора"); break;
     case ERR_INCOMPATIBLE_ARRAYS:
       Print("Ошибка: Массивы несовместимы"); break;
     case ERR_GLOBAL_VARIABLES_PROCESSING:
       Print("Ошибка: Ошибка обработки глобальныех переменных"); break;
     case ERR_GLOBAL_VARIABLE_NOT_FOUND:
       Print("Ошибка: Глобальная переменная не обнаружена"); break;
     case ERR_FUNC_NOT_ALLOWED_IN_TESTING:
       Print("Ошибка: Функция не разрешена в тестовом режиме"); break;
     case ERR_FUNCTION_NOT_CONFIRMED:
       Print("Ошибка: Функция не разрешена"); break;
     case ERR_SEND_MAIL_ERROR:
       Print("Ошибка: Ошибка отправки почты"); break;
     case ERR_STRING_PARAMETER_EXPECTED:
       Print("Ошибка: Ожидается параметр типа string"); break;
     case ERR_INTEGER_PARAMETER_EXPECTED:
       Print("Ошибка: Ожидается параметр типа integer"); break;
     case ERR_DOUBLE_PARAMETER_EXPECTED:
       Print("Ошибка: Ожидается параметр типа double"); break;
     case ERR_ARRAY_AS_PARAMETER_EXPECTED:
       Print("Ошибка: В качестве параметра ожидается массив"); break;
     case ERR_HISTORY_WILL_UPDATED:
       Print("Ошибка: Запрошенные исторические данные в состоянии обновления"); break;
     case ERR_TRADE_ERROR:
       Print("Ошибка: Ошибка при выполнении торговой операции"); break;
     case ERR_END_OF_FILE:
       Print("Ошибка: Конец файла"); break;
     case ERR_SOME_FILE_ERROR:
       Print("Ошибка: Ошибка при работе с файлом"); break;
     case ERR_WRONG_FILE_NAME:
       Print("Ошибка: Неправильное имя файла"); break;
     case ERR_TOO_MANY_OPENED_FILES:
       Print("Ошибка: Слишком много открытых файлов"); break;
     case ERR_CANNOT_OPEN_FILE:
       Print("Ошибка: Невозможно открыть файл"); break;
     case ERR_INCOMPATIBLE_FILEACCESS:
       Print("Ошибка: Несовместимый режим доступа к файлу"); break;
     case ERR_NO_ORDER_SELECTED:
       Print("Ошибка: Ни один ордер не выбран"); break;
     case ERR_UNKNOWN_SYMBOL:
       Print("Ошибка: Неизвестный символ"); break;
     case ERR_INVALID_PRICE_PARAM:
       Print("Ошибка: Неправильный параметр цены для торговой функции"); break;
     case ERR_INVALID_TICKET:
       Print("Ошибка: Неверный номер тикета"); break;
     case ERR_TRADE_NOT_ALLOWED:
       Print("Ошибка: Торговля не разрешена. Необходимо включить опцию /Разрешить советнику торговать/ в свойствах эксперта."); break;
     case ERR_LONGS_NOT_ALLOWED:
       Print("Ошибка: Длинные позиции не разрешены. Необходимо проверить свойства эксперта."); break;
     case ERR_SHORTS_NOT_ALLOWED:
       Print("Ошибка: Короткие позиции не разрешены. Необходимо проверить свойства эксперта."); break;
     case ERR_OBJECT_ALREADY_EXISTS:
       Print("Ошибка: Объект уже существует"); break;
     case ERR_UNKNOWN_OBJECT_PROPERTY:
       Print("Ошибка: Запрошено неизвестное свойство объекта"); break;
     case ERR_OBJECT_DOES_NOT_EXIST:
       Print("Ошибка: Объект не существует"); break;
     case ERR_UNKNOWN_OBJECT_TYPE:
       Print("Ошибка: Неизвестный тип объекта"); break;
     case ERR_NO_OBJECT_NAME:
       Print("Ошибка: Нет имени объекта"); break;
     case ERR_OBJECT_COORDINATES_ERROR:
       Print("Ошибка: Ошибка координат объекта"); break;
     case ERR_NO_SPECIFIED_SUBWINDOW:
       Print("Ошибка: Не найдено указанное подокно"); break;
     case ERR_SOME_OBJECT_ERROR:
       Print("Ошибка: Ошибка при работе с объектом"); break;
     case 4250: //ERR_NOTIFICATION_SEND_ERROR
       Print("Ошибка: Ошибка постановки уведомления в очередь на отсылку"); break;
     case 4251:  //ERR_NOTIFICATION_WRONG_PARAMETER
       Print("Ошибка: Неверный параметр - в функцию SendNotification() передали пустую строку"); break;
     case 4252:  //ERR_NOTIFICATION_WRONG_SETTINGS
       Print("Ошибка: Неверные настройки для отправки уведомлений (не указан ID или не выставлено разрешение"); break;
     case 4253:  //ERR_NOTIFICATION_TOO_FREQUENT
       Print("Ошибка: Слишком частая отправка уведомлений"); break;
     default:
       Print("Ошибка: не опознана, посмотрите по каталогу, #", Error); break;
    }
   return(Error); 
  }




