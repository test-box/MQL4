//+------------------------------------------------------------------+
//|                                                   grid_02_01.mq4 |
//|                                        Copyright © 2014,  GlobuX |
//|                                                 globuq@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2014,  GlobuX"
#property link      "globuq@gmail.com"
#include <stderror.mqh>

//+------------------------------------------------------------------+
//| block initialization external Variables                          |
//+------------------------------------------------------------------+

extern   bool UseBalance= true // использовать для расчета TakeMoney - Balance либо Equity
extern double Lots      = 0.1;    // объем ордера в лотах
extern   bool LotsAuto  = false;   // автоматический расчет лота
extern double Deposit   = 10000;  // размер депозита
extern double PrcProfit = 0.5;    // фиксация прибыли при достижении профита (процент от депозита)
extern double MnlProfit = 3.77;       // задание размера профита вручную
extern double TP        = 0.0010; // тейкпрофит ордеров в пунктах
extern double BasePrice = 1.6701; // ask-цена точки отсчета
extern double Spread    = 0.0003; // спрэд
extern double StepGrid  = 0.0013; // расстояние между стубеньками сетки
extern    int StepUp    = 8;      // количество ступенек от текущей цены вверх, которое мониторит советник
extern    int StepDn    = 8;      // количество ступенек от текущей цены вверх, которое мониторит советник
extern    int MagicKey  = 333;    // ключ советника, для распознавания своих ордеров

//+------------------------------------------------------------------+
//| block initialization Variables                                   |
//+------------------------------------------------------------------+
double NewBalance; // Обновленный баланс для автолота
double TakeMoney;  // 
string takemoney_GV; //
string lot_GV;     // 
double DiffPrice;  // Расстояние между отправной точкой и текущей ценой
double A1_Price;   // цена первой верхней ступеньки
double B1_Price;   // цена первой нижней ступеньки  
int    Grids;      // количество ступенек от отправной точки
int    CountOrders; // количество ордеров (возвращает CalcOurOrders)
double lots;       // размер лота
int    NormLot;    //
double count;      // Счетчик наших ордеров (MagicKey)
double A_PriceAsk[21], A_PriceBid[21]; // Массивы с ценами ордеров выше рыночной цены
double B_PriceAsk[21], B_PriceBid[21]; // Массивы с ценами ордеров ниже рыночной цены
int    i;          // счетчик
//string ordersType[6] = {"BUY", "SELL", "BUYLIMIT", "SELLLIMIT", "BUYSTOP", "SELLSTOP"};


//+------------------------------------------------------------------+
//| expert initialization and deinitialization function              |
//+------------------------------------------------------------------+
int init()
  {
  double minlot = MarketInfo(Symbol(),MODE_MINLOT);
  if (minlot == 0.0001) NormLot = 4;
  else if (minlot == 0.001) NormLot = 3;
       else if (minlot == 0.01) NormLot = 2;
            else if (minlot == 0.1) NormLot = 1;
                 else if (minlot == 1) NormLot = 0;
                      else NormLot = 2;
  Print("Минимальный лот (", minlot, ") : ", NormLot);
  if (IsTesting())
     {
      Print("Эксперт работает в ТЕСТЕ. Используются тестовые глобальные переменные.");
      takemoney_GV="Grid-"+IntegerToString(MagicKey,4,'0')+"_TEST_"+Symbol()+"_TakeMoney";  //Устанавливаем название глобальной переменной
      lot_GV="Grid-"+IntegerToString(MagicKey,4,'0')+"_TEST_"+Symbol()+"_Lot"; 
     }
   else if(IsDemo())
     {
      Print("Эксперт работает на ДЕМО-счете. Используются демо-глобальные переменные.");
      takemoney_GV="Grid-"+IntegerToString(MagicKey,4,'0')+"_DEMO_"+Symbol()+"_TakeMoney";  //Устанавливаем название глобальной переменной
      lot_GV="Grid-"+IntegerToString(MagicKey,4,'0')+"_DEMO_"+Symbol()+"_Lot";
     }
   else
     {
      Print("Эксперт работает на РЕАЛЬНОМ счете. Используются глобальные переменные реального счета.");
      takemoney_GV="Grid-"+IntegerToString(MagicKey,4,'0')+"_"+Symbol()+"_TakeMoney";  //Устанавливаем название глобальной переменной (Distance)
      lot_GV="Grid-"+IntegerToString(MagicKey,4,'0')+"_"+Symbol()+"_Lot";
     }
   if (GlobalVariableCheck(takemoney_GV)) {
      TakeMoney = GlobalVariableGet(takemoney_GV);
      Print("Предыдущие настройки: закрытие текущих ордеров при Эквити (", takemoney_GV, ")= ", TakeMoney);
     }
   if (GlobalVariableCheck(lot_GV)) {
      lots = GlobalVariableGet(lot_GV);
      Print("Предыдущие настройки: Lot (", lot_GV, ")= ", lots);
     }
  count = CalcOurOrders();
  Print(" Инициализация: сосчитали ордера = ", count);
  if (count == 0)
    {
    NewBalance = AccountBalance();
    Print(" Инициализация: посчитали новый баланс = ", NewBalance, ", %= ", NewBalance*PrcProfit/100);
    ReCalculateLot();
    if (lots < minlot) {Print(" Какого-то хуя лот стал меньше ", minlot, ", поменяем на = ", minlot); lots = minlot;}
    Print(" Инициализация: пересчитали лот = ", lots);
    if (MnlProfit == 0)
      {
      TakeMoney = NewBalance + NewBalance*PrcProfit/100;
      SaveSettings();
      Print(" Инициализация: условия перезапуска - % процент, TakeMoney= ", TakeMoney);
      }
    else
      {
      TakeMoney = NewBalance + MnlProfit;
      SaveSettings();
      Print(" Инициализация: условия перезапуска - фиксированная сумма, TakeMoney= ", TakeMoney);
      }
    }
  return(0);
  }

  int deinit() {return(0);}


//+------------------------------------------------------------------+
//|                     Expert Start function                        |
//+------------------------------------------------------------------+
int start()
  {
  //double minlot = MarketInfo(Symbol(),MODE_MINLOT);
  //if (lots < minlot) {Print(" Какого-то хуя лот стал меньше ", minlot, ", поменяем на = ", Lots); lots = Lots;}
  //lots = Lots;
  //SaveSettings();
  TakeMoney = GlobalVariableGet(takemoney_GV);
  //Print(" Главная: TakeMoney= ", TakeMoney, ", AccountEquity= ", AccountEquity());
  if (TakeMoney < AccountEquity() && CalcOurOrders()!= 0) {ReBurn();}
  //Print("Главная");
  DiffPrice = MathAbs(BasePrice-Ask); // расстояние в пунктах между текущей ценой и BasePrice
  //Print("DiffPrice= ", "BasePrice(", BasePrice, ") - ASK(", Ask, ") = ", DiffPrice*10000);
  if (BasePrice > Ask)
    {
    Grids = MathFloor(DiffPrice/StepGrid); // количество ступенек от BasePrice до ближайшей в текущей цене ступеньки 
    A1_Price = BasePrice - Grids*StepGrid; //цена первой верхней ступеньки
    B1_Price = A1_Price - StepGrid;        //цена первой нижней ступеньки
    }
  if (BasePrice < Ask)
    {
    Grids = MathFloor(DiffPrice/StepGrid); // количество ступенек от BasePrice до ближайшей в текущей цене ступеньки
    B1_Price = BasePrice + Grids*StepGrid;
    A1_Price = B1_Price + StepGrid;
    }
  if (BasePrice == Ask) return(-1);
  int max = MathMax(StepUp, StepDn);
  for (i=1; i<=max; i++)  // Заполнение массивов ценами для сетки ордеров
    {
    if (i <= StepUp)
	  {
	  A_PriceAsk[i] = A1_Price + (i-1)*StepGrid;
      A_PriceBid[i] = A_PriceAsk[i] - Spread;
	  }
	if (i <= StepDn)
	  {
	  B_PriceAsk[i] = B1_Price - (i-1)*StepGrid;
      B_PriceBid[i] = B_PriceAsk[i] - Spread;
	  }
    }
  RefreshOrders();
  return(0);
  }
//+------------------------------------------------------------------+
//|                              End                                 |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                           Functions                              |
//+------------------------------------------------------------------+

void SaveSettings()
  {
   if (GlobalVariableSet(takemoney_GV, TakeMoney) == 0) {
      Print("При сохранении глобальной переменной takemoney_GV= ", takemoney_GV, "  возникла ошибка!");
      Print("Ошибка #", GetLastError());
      }
   if (GlobalVariableSet(lot_GV, lots) == 0) {
      Print("При сохранении глобальной переменной lot_GV= ", lot_GV, "  возникла ошибка!");
      Print("Ошибка #", GetLastError());
      }
  }


void ReBurn()
  {
  // пересчет лота, запомнить баланс, закрытие всех ордеров
  Print(" ReBurn потому что: TakeMoney= ", TakeMoney, ", AccountEquity= ", AccountEquity(), ", ордеров= ", CountOrders);
  CloseAllOurOrders();
  Print(" Закрыли все ордера, наверное...");
  double minlot = MarketInfo(Symbol(),MODE_MINLOT);
  ReCalculateLot();
  if (lots < minlot) {Print(" Какого-то хуя лот стал меньше ", minlot, ", поменяем на = ", minlot); lots = minlot;}
  NewBalance = AccountBalance();
  Print(" ReBurn: NewBalance= ", NewBalance);
  if (MnlProfit == 0)
    {
    TakeMoney = NewBalance + NewBalance*PrcProfit/100;
    SaveSettings();
    Print(" ReBurn: условия перезапуска - ", PrcProfit,"% процент, TakeMoney= ", TakeMoney);
    }
  else
    {
    TakeMoney = NewBalance + MnlProfit;
    SaveSettings();
    Print(" ReBurn: условия перезапуска - фиксированная сумма, TakeMoney= ", TakeMoney);
    }
  }


void CloseAllOurOrders()
  {
   Print("-= Функция закрытия всех оставшихся ордеров =-");
   int count;
   int k = 0;
   int OrderTicketMassive[200];
   ArrayInitialize(OrderTicketMassive,0);
   for (int t=0; t<OrdersTotal(); t++)  //Цикл поиска ордеров советника, создает массив тикетов ордеров
     {
      if (OrderSelect(t, SELECT_BY_POS, MODE_TRADES) == false) {Print("1-я проверка: ошибка, (OrderSelect)"); continue;}
      if (OrderMagicNumber() != MagicKey) {Print("2-я проверка: ошибка, (OrderMagicNumber)"); continue;}
      if (OrderSymbol() != Symbol()) {Print("3-я проверка: ошибка, (OrderSymbol)"); continue;}
      Print("Найден ордер, тикет = ", OrderTicket());
      count++;
      OrderTicketMassive[count] = OrderTicket();
     }
   for (int i=1; i <= count; i++)      //Цикл удаления найденных ордеров
     {
      OrderSelect(OrderTicketMassive[i],SELECT_BY_TICKET);
      Print("Ордер: тикет #", OrderTicket(), ", тип ордера=", OrderType(), ", валюта=", OrderSymbol(),
            ", цена открытия=", OrderOpenPrice(), ", уровень ТП=",OrderTakeProfit(), ", объем лотов=", OrderLots(),
            ", idNum=", OrderMagicNumber(), ", комментарий=", OrderComment()); 
      switch(OrderType())                       // По типу ордера
        {
        case OP_BUY:       Print(" CloseOrders: закрываем BUY");
                           ResetLastError();
                           while (OrderClose(OrderTicket(),OrderLots(),Bid,3,clrNONE) != true) {
                             if (_LastError == ERR_INVALID_TICKET || _LastError == ERR_TRADE_NOT_ALLOWED) break; 
                             }
                           break;
        case OP_SELL:      Print(" CloseOrders: закрываем SELL");
                           ResetLastError();
                           while (OrderClose(OrderTicket(),OrderLots(),Ask,3,clrNONE) != true) {
                             if (_LastError == ERR_INVALID_TICKET || _LastError == ERR_TRADE_NOT_ALLOWED) break; 
                             }
                           break;
        case OP_BUYSTOP:   Print(" CloseOrders: закрываем BUYSTOP");
                           ResetLastError();
                           while (OrderDelete(OrderTicket(), clrNONE) != true) {
                             if (_LastError == ERR_INVALID_TICKET || _LastError == ERR_TRADE_NOT_ALLOWED) break; 
                             }
                           break;
        case OP_BUYLIMIT:  Print(" CloseOrders: закрываем BUYLIMIT");
                           ResetLastError();
                           while (OrderDelete(OrderTicket(), clrNONE) != true) {
                             if (_LastError == ERR_INVALID_TICKET || _LastError == ERR_TRADE_NOT_ALLOWED) break; 
                             }
                           break;
        case OP_SELLSTOP:  Print(" CloseOrders: закрываем SELLSTOP");
                           ResetLastError();
                           while (OrderDelete(OrderTicket(), clrNONE) != true) {
                             if (_LastError == ERR_INVALID_TICKET || _LastError == ERR_TRADE_NOT_ALLOWED) break; 
                             }
                           break;
        case OP_SELLLIMIT: Print(" CloseOrders: закрываем SELLLIMIT");
                           ResetLastError();
                           while (OrderDelete(OrderTicket(), clrNONE) != true) {
                             if (_LastError == ERR_INVALID_TICKET || _LastError == ERR_TRADE_NOT_ALLOWED) break; 
                             }
                           break;
      }
     }
   Print("Количество удаленных ордеров: ", count);
  }


void ReCalculateLot()
  {
  // Пересчитываем лот на новый баланс
  if (LotsAuto == true) {
     Print(" Autolot: активен");
     lots = AccountEquity()/Deposit*Lots; // AccountBalance() - как вариант использовать баланс вместо эквити
     Print("  Лот:", lots, " = AccountEquity:", AccountEquity(), " / Deposit:", Deposit, " * Lots:", Lots);}  
  else {
     lots = Lots;
     Print("  Лот установлен вручную: ", lots, "(", Lots, ")");}
  lots = NormalizeDouble(lots,NormLot);
  Print("  Нормализуем значение лота до ", NormLot, " знаков после запятой, получается = ", lots);
  }

int CalcOurOrders()
  {
  // Подсчитываем количество наших ордеров
  int c = 0;
  for (int j=0; j<OrdersTotal(); j++)
    {
    if (OrderSelect(j, SELECT_BY_POS, MODE_TRADES) == false) {continue;} // продолжаем цикл
    if (OrderMagicNumber() == MagicKey && OrderSymbol() == Symbol()) { c++; }
    }
  CountOrders = c;
  return(c);
  }


void RefreshOrders()
  {
  // Восстанавливаем сетку ордеров, если были закрытые ордера
  int max = MathMax(StepUp, StepDn);
  for (i=1; i<=max; i++)
    {
    if (i <= StepUp)
	  {
	  if (CheckOrder(A_PriceAsk[i]) == false) {SetOrderBuyStop(A_PriceAsk[i],lots);}
      if (CheckOrder(A_PriceBid[i]) == false) {SetOrderSellLimit(A_PriceBid[i],lots);}
	  }
	if (i <= StepDn)
	  {
	  if (CheckOrder(B_PriceAsk[i]) == false) {SetOrderBuyLimit(B_PriceAsk[i],lots);}
      if (CheckOrder(B_PriceBid[i]) == false) {SetOrderSellStop(B_PriceBid[i],lots);}
	  }
    }
  }


bool CheckOrder(double Price)
  {
  // Проверяем есть ли наш ордер с указанной ценой
  bool result = false;
  if (OrdersTotal() < 1) return(result);
  for (int j=0; j<OrdersTotal(); j++)
    {
    if (OrderSelect(j, SELECT_BY_POS, MODE_TRADES) == false) {continue;} // продолжаем цикл
    //Print(Price, ", Найден ", ordersType[OrderType()], ", OrderTicket=", OrderTicket(),", цена найденного ордера=  ", OrderOpenPrice(), ", Magic= ", OrderMagicNumber());
    if (NormalizeDouble(OrderOpenPrice(),_Digits) == NormalizeDouble(Price,_Digits) && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicKey)
      { result = true; return(result);}
    }
  return(result); 
  }


void SetOrderBuyStop(double Price, double Lot)
  {
  double tp = Price + TP;
  OrderSend(Symbol(),OP_BUYSTOP,Lot,Price,0,0,tp,"BuyStop   ",MagicKey,0,Blue);
  }

void SetOrderBuyLimit(double Price, double Lot)
  {
  double tp = Price + TP;
  OrderSend(Symbol(),OP_BUYLIMIT,Lot,Price,0,0,tp,"BuyLimit  ",MagicKey,0,LightBlue);
  }

void SetOrderSellStop(double Price, double Lot)
  {
  double tp = Price - TP;
  OrderSend(Symbol(),OP_SELLSTOP,Lot,Price,0,0,tp,"SellStop  ",MagicKey,0,Red);
  }

void SetOrderSellLimit(double Price, double Lot)
  {
  double tp = Price - TP;
  OrderSend(Symbol(),OP_SELLLIMIT,Lot,Price,0,0,tp,"SellLimit ",MagicKey,0,Magenta);
  }
