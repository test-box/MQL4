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

extern double Lots      = 0.1;    // объем ордера в лотах
extern   bool LotsAuto  = true;   // автоматический расчет лота
extern double Deposit   = 10000;  // размер депозита
extern double PrcProfit = 0.5;    // фиксация прибыли при достижении профита (процент от депозита)
extern double MnlProfit = 0;       // задание размера профита вручную
extern double TP        = 0.0013; // тейкпрофит ордеров в пунктах
extern double BasePrice = 1.3603; // цена ask точки отсчета
extern double Spread    = 0.0003; // спрэд
extern double StepGrid  = 0.0010; // расстояние между стубеньками сетки
extern    int StepUp    = 4;      // количество ступенек от текущей цены вверх, которое мониторит советник
extern    int StepDn    = 5;      // количество ступенек от текущей цены вверх, которое мониторит советник
extern    int MagicKey  = 789;    // ключ советника, для распознавания своих ордеров

//+------------------------------------------------------------------+
//| block initialization Variables                                   |
//+------------------------------------------------------------------+
bool   ReBurnFlag = true; // Флаг перерождения
double NewBalance; // Обновленный баланс для автолота
double TakeMoney;  // 
double DiffPrice;  // Расстояние между отправной точкой и текущей ценой
double A1_Price;   // цена первой верхней ступеньки
double B1_Price;   // цена первой нижней ступеньки  
int    Grids;      // количество ступенек от отправной точки
double lots;       // размер лота
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
  //
  //if (ReBurnFlag == true) ReCalculateLot(); 
  count = CalcOurOrders();
  Print(" Инициализация: сосчитали ордера");
  if (count == 0)
    {
    NewBalance = AccountBalance();
    Print(" Инициализация: посчитали новый баланс = ", NewBalance, ", %= ", NewBalance*PrcProfit/100);
    ReCalculateLot();
    Print(" Инициализация: пересчитали лот");
    if (MnlProfit = 0) {TakeMoney = NewBalance + NewBalance*PrcProfit/100; Print(" Инициализация: посчитали условия перезапуска - % процент");}
    else {TakeMoney = NewBalance + MnlProfit; Print(" Инициализация: посчитали условия перезапуска - фиксированная сумма");}
    }
  return(0);
  }
int deinit() {return(0);}


//+------------------------------------------------------------------+
//|                     Expert Start function                        |
//+------------------------------------------------------------------+
int start()
  {
  Print(" Главная: TakeMoney= ", TakeMoney, ", AccountEquity= ", AccountEquity());
  if (TakeMoney < AccountEquity() && CalcOurOrders()!= 0) {ReBurn();}
  Print("Главная");
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
  for (i=1; i<=StepUp; i++)
    {
    A_PriceAsk[i] = A1_Price + (i-1)*StepGrid;
    A_PriceBid[i] = A_PriceAsk[i] - Spread;
    }
  for (i=1; i<=StepDn; i++)
    {
    B_PriceAsk[i] = B1_Price - (i-1)*StepGrid;
    B_PriceBid[i] = B_PriceAsk[i] - Spread;
    }
  RefreshOrders_A();
  RefreshOrders_B();
  return(0);
  }
//+------------------------------------------------------------------+
//|                              End                                 |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                           Functions                              |
//+------------------------------------------------------------------+

void ReBurn()
  {
  // пересчет лота, запомнить баланс, закрытие всех ордеров
  ReCalculateLot();
  Print(" ReBurn: пересчитали лот");
  NewBalance = AccountBalance();
  if (MnlProfit = 0) {TakeMoney = NewBalance + NewBalance*PrcProfit/100; Print(" ReBurn: посчитали условия перезапуска - % процент");}
    else {TakeMoney = NewBalance + MnlProfit; Print(" ReBurn: посчитали условия перезапуска - фиксированная сумма");}
  for (int j = 1; (CalcOurOrders() != 0) && (j<=5); j++) 
    {
    CloseAllOurOrders();
    Print(" Закрыли все ордера, наверное...");
    }  
  }

bool CloseAllOurOrders()
  {
  Print(" CloseAllOurOrders: закрываем все наши ордера");
  bool err = false;
  for (int j=0; j<OrdersTotal(); j++)
    {
    if (OrderSelect(j, SELECT_BY_POS, MODE_TRADES) == false) {continue;} // не смогли выбрать ордер - продолжаем цикл
    if (OrderMagicNumber() != MagicKey) {continue;} // не наш мэджик - продолжаем цикл
    if (OrderSymbol() != Symbol()) {continue;}      // не наш инструмент - продолжаем цикл
    switch(OrderType())                       // По типу ордера
      {
      case OP_BUY:       OrderClose(OrderTicket(),OrderLots(),Bid,3,clrNONE); Print(" CloseOrders: закрыли BUY"); break;
      case OP_SELL:      OrderClose(OrderTicket(),OrderLots(),Ask,3,clrNONE); Print(" CloseOrders: закрыли SELL"); break;   
      case OP_BUYSTOP:   OrderDelete(OrderTicket(), clrNONE); Print(" CloseOrders: закрыли BUYSTOP"); break;
      case OP_BUYLIMIT:  OrderDelete(OrderTicket(), clrNONE); Print(" CloseOrders: закрыли BUYLIMIT"); break;
      case OP_SELLSTOP:  OrderDelete(OrderTicket(), clrNONE); Print(" CloseOrders: закрыли SELLSTOP"); break;
      case OP_SELLLIMIT: OrderDelete(OrderTicket(), clrNONE); Print(" CloseOrders: закрыли SELLLIMIT"); break;
      }
    }
  return(err);
  }

void ReCalculateLot()
  {
  if (LotsAuto == true) {lots = AccountEquity()/Deposit*Lots;}  // AccountBalance() - как вариант использовать баланс вместо эквити
  else {lots = Lots;}
  }

int CalcOurOrders()
  {
  int c = 0;
  for (int j=0; j<OrdersTotal(); j++)
    {
    if (OrderSelect(j, SELECT_BY_POS, MODE_TRADES) == false) {continue;} // продолжаем цикл
    if (OrderMagicNumber() == MagicKey && OrderSymbol() == Symbol()) { c++; }
    }
  return(c);
  }


void RefreshOrders_A()
  {
  for (i=1; i<=StepUp; i++)
    {
    if (CheckOrder(A_PriceAsk[i]) == false) {SetOrderBuyStop(A_PriceAsk[i],lots);}
    if (CheckOrder(A_PriceBid[i]) == false) {SetOrderSellLimit(A_PriceBid[i],lots);}
    }
  }

void RefreshOrders_B()
  {
  for (i=1; i<=StepDn; i++)
    {
    if (CheckOrder(B_PriceAsk[i]) == false) {SetOrderBuyLimit(B_PriceAsk[i],lots);}
    if (CheckOrder(B_PriceBid[i]) == false) {SetOrderSellStop(B_PriceBid[i],lots);}
    }
  }


bool CheckOrder(double Price)
  {
  bool result = false;
  if (OrdersTotal() < 1) return(result);
  for (int j=0; j<OrdersTotal(); j++)
    {
    if (OrderSelect(j, SELECT_BY_POS, MODE_TRADES) == false) {continue;} // продолжаем цикл
    //Print(Price, ", Найден ", ordersType[OrderType()], ", OrderTicket=", OrderTicket(),", цена найденного ордера=  ", OrderOpenPrice(), ", Magic= ", OrderMagicNumber());
    if (NormalizeDouble(OrderOpenPrice(),_Digits) == NormalizeDouble(Price,_Digits) && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicKey)
       { result = true; return(result);  }
    }
  return(result); 
  }


void SetOrderBuyStop(double Price, double Lot)
  {
  double tp = Price + TP;
  OrderSend(Symbol(),OP_BUYSTOP,Lot,Price,0,0,tp,"Grid",MagicKey,0,Blue);
  }

void SetOrderBuyLimit(double Price, double Lot)
  {
  double tp = Price + TP;
  OrderSend(Symbol(),OP_BUYLIMIT,Lot,Price,0,0,tp,"Grid",MagicKey,0,LightBlue);
  }

void SetOrderSellStop(double Price, double Lot)
  {
  double tp = Price - TP;
  OrderSend(Symbol(),OP_SELLSTOP,Lot,Price,0,0,tp,"Grid",MagicKey,0,Red);
  }

void SetOrderSellLimit(double Price, double Lot)
  {
  double tp = Price - TP;
  OrderSend(Symbol(),OP_SELLLIMIT,Lot,Price,0,0,tp,"Grid",MagicKey,0,Magenta);
  }
