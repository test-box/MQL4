//+------------------------------------------------------------------+
//|                                                         grid.mq4 |
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
extern double TP        = 0.0013; // Тейкпрофит ордеров в пунктах
extern double BasePrice = 1.3603; // цена ask точки отсчета
extern double Spread    = 0.0003; // спрэд
extern double StepGrid  = 0.0010; // расстояние между стубеньками сетки
extern    int StepUp    = 4;      // количество ступенек от текущей цены вверх, которое мониторит советник
extern    int StepDn    = 5;      // количество ступенек от текущей цены вверх, которое мониторит советник
extern    int MagicKey  = 789;    // ключ советника, для распознавания своих ордеров

//+------------------------------------------------------------------+
//| block initialization Variables                                   |
//+------------------------------------------------------------------+
double DiffPrice; // Расстояние между отправной точкой и текущей ценой
double NearPrice; // цена ступеньки ближайшей к текущей цене
double A1_Price;  // цена первой верхней ступеньки
double B1_Price;  // цена первой нижней ступеньки  
int    Grids;     // количество ступенек от отправной точки
int    EdgeStep;  // Расстояние до крайнего ордера
int    i;         // счетчик
double PriceAsk;
double PriceBid;
double A_PriceAsk[21], A_PriceBid[21];
double B_PriceAsk[21], B_PriceBid[21];
string ordersType[6] = {"BUY", "SELL", "BUYLIMIT", "SELLLIMIT", "BUYSTOP", "SELLSTOP"};
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init() {}
int deinit() {}

int start()
  {
  Print("GLAVNAYA");
  DiffPrice = MathAbs(BasePrice-Ask); // расстояние в пунктах между текущей ценой и BasePrice
  Print("DiffPrice= ", "BasePrice(", BasePrice, ") - ASK(", Ask, ") = ", DiffPrice*10000);
  if (BasePrice > Ask)
    {
    Grids = MathFloor(DiffPrice/StepGrid); // количество ступенек от BasePrice до ближайшей в текущей цене ступеньки 
    A1_Price = BasePrice - Grids*StepGrid; //цена первой верхней ступеньки
    B1_Price = A1_Price - StepGrid;        //цена первой нижней ступеньки
    Print("BasePrice > Ask", ", Grids= ", Grids, ", A1_Price= ", A1_Price, ", B1_Price= ", B1_Price);
    }
  if (BasePrice < Ask)
    {
    Grids = MathFloor(DiffPrice/StepGrid); // количество ступенек от BasePrice до ближайшей в текущей цене ступеньки
    B1_Price = BasePrice + Grids*StepGrid;
    A1_Price = B1_Price + StepGrid;
    Print("BasePrice < Ask", ", Grids= ", Grids, ", A1_Price= ", A1_Price, ", B1_Price= ", B1_Price);
    }
  if (BasePrice == Ask) return(-1);
  //if (A1_Price = Ask) {RefreshMarketOrder();}
  for (i=1; i<=StepUp; i++)
    {
    A_PriceAsk[i] = A1_Price + (i-1)*StepGrid;
    A_PriceBid[i] = A_PriceAsk[i] - Spread;
    Print(A_PriceAsk[i], ", ",A_PriceBid[i]);
    }
  for (i=1; i<=StepDn; i++)
    {
    B_PriceAsk[i] = B1_Price - (i-1)*StepGrid;
    B_PriceBid[i] = B_PriceAsk[i] - Spread;
    Print(B_PriceAsk[i], ", ",B_PriceBid[i]);
    }
  RefreshOrders_A();
  RefreshOrders_B();
  Print(" ");
  Print(" ");
  Print(" ");
  }
//+------------------------------------------------------------------+
//| End                                                              |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                           Functions                              |
//+------------------------------------------------------------------+

void RefreshOrders_A()
  {
  for (i=1; i<=StepUp; i++)
    {
    if (CheckOrder(A_PriceAsk[i]) == false) {SetOrderBuyStop(A_PriceAsk[i],Lots);}
    if (CheckOrder(A_PriceBid[i]) == false) {SetOrderSellLimit(A_PriceBid[i],Lots);}
    }
  }

void RefreshOrders_B()
  {
  for (i=1; i<=StepDn; i++)
    {
    if (CheckOrder(B_PriceAsk[i]) == false) {SetOrderBuyLimit(B_PriceAsk[i],Lots);}
    if (CheckOrder(B_PriceBid[i]) == false) {SetOrderSellStop(B_PriceBid[i],Lots);}
    }
  }

/*
bool CheckOrder(double Price)
  {
  if (OrdersTotal() < 1) return(false);
  for (int j=0; j<OrdersTotal(); j++)
    {
    if (OrderSelect(j, SELECT_BY_POS, MODE_TRADES) == false) {Print("Ошибка селекта, продолжаем цикл, выбираем другой"); continue; }
    Print("Найден", ordersType[OrderType()], ", OrderTicket=", OrderTicket(),", цена найденного ордера=  ", OrderOpenPrice(), "Magic= ", OrderMagicNumber());
    Print("Проверяем наш или нет");
    if (OrderMagicNumber() != MagicKey) { Print("Другой Магик"); continue;}
    if (OrderOpenPrice()!= Price) { Print("Другая цена"); continue;}
    Print("Цена и Магик не совпали. Будем ставить ордер, по цене =", Price);
    return(false);
    }   Print("Все ордера проверены, совпадений не найдено. Будем ставить ордер, по цене= ", Price);
  Print("Ордер такой уже есть, ставить новый не будем");   
  return(true); 
  } */


bool CheckOrder(double Price)
  {
  bool result = false;
  if (OrdersTotal() < 1) return(result);
  for (int j=0; j<OrdersTotal(); j++)
    {
    if (OrderSelect(j, SELECT_BY_POS, MODE_TRADES) == false) {continue;} // продолжаем цикл
    Print(Price, ", Найден ", ordersType[OrderType()], ", OrderTicket=", OrderTicket(),", цена найденного ордера=  ", OrderOpenPrice(), ", Magic= ", OrderMagicNumber());
    if ((OrderMagicNumber() == MagicKey) && (NormalizeDouble(OrderOpenPrice(),_Digits) == NormalizeDouble(Price,_Digits)))
       { Print("Цена и Магик совпали! Запрет на установку нового ордера!"); result = true; return(result);  }
    }
  return(result); 
  }


void SetOrderBuyStop(double Price, double Lot)
  {
  double tp = Price + TP;
  Print("ASK= ", Ask, ", BuyStop: Price= ", Price, ", TP= ", tp);
  OrderSend(Symbol(),OP_BUYSTOP,Lot,Price,0,0,tp,"Grid",MagicKey,0,Blue);
  }

void SetOrderBuyLimit(double Price, double Lot)
  {
  double tp = Price + TP;
  Print("ASK= ", Ask, ", BuyLimit: Price= ", Price, ", TP= ", tp); 
  OrderSend(Symbol(),OP_BUYLIMIT,Lot,Price,0,0,tp,"Grid",MagicKey,0,LightBlue);
  }

void SetOrderSellStop(double Price, double Lot)
  {
  double tp = Price - TP;
  Print("BID= ", Bid, ", SellStop: Price= ", Price, ", TP= ", tp);
  OrderSend(Symbol(),OP_SELLSTOP,Lot,Price,0,0,tp,"Grid",MagicKey,0,Red);
  }

void SetOrderSellLimit(double Price, double Lot)
  {
  double tp = Price - TP;
  Print("BID= ", Bid, ", SellLimit: Price= ", Price, ", TP= ", tp);
  OrderSend(Symbol(),OP_SELLLIMIT,Lot,Price,0,0,tp,"Grid",MagicKey,0,Magenta);
  }
