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
extern double Lots          = 0.1;     // объем ордера в лотах
extern double TP            = 0.0010;  // Тейкпрофит ордеров в пунктах
extern double BaseBuyPrice	 = 1.3603;	// цена ask точки отсчета
extern double BaseSellPrice = 1.3600;	// цена bid точки отсчета
extern double Spread        = 0.0003;	// спрэд
extern double DistGrid      = 0.0010;	// расстояние между стубеньками сетки
extern    int DistUp    = 20;		// количество ступенек от текущей цены вверх, которое мониторит советник
extern    int DistDown  = 20;		// количество ступенек от текущей цены вверх, которое мониторит советник
extern    int MagicKey      = 789;		// ключ советника, для распознавания своих ордеров

//+------------------------------------------------------------------+
//| block initialization Variables                                   |
//+------------------------------------------------------------------+
double DiffPrice; // Расстояние между отправной точкой и текущей ценой
double NearPrice; // цена ближайшей к текущей цене ступеньки 
int    QntGrid;   // количество ступенек от отправной точки
int    EdgeDist;
int    i;         // итератор


//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {

  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {

  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
   DiffPrice = MathAbs(BaseBuyPrice-Ask); // расстояние в пунктах между текущей ценой и BaseBuyPrice
   QntGrid = MathRound(DiffPrice/DistGrid); // количество ступенек от ближайшей в текущей цене ступеньки до BaseBuyPrice
   if (BaseBuyPrice > Ask) {NearPrice = BaseBuyPrice - QntGrid*DistGrid;}
   else if (BaseBuyPrice == Ask) {NearPrice = BaseBuyPrice;}
        else {NearPrice = BaseBuyPrice + QntGrid*DistGrid;}
   if (DistUp > DistDown) {EdgeDist = DistUp;}
   else EdgeDist = DistDown;
   
   for (i = 1; i <= EdgeDist; i++)                                             
    {
     double PriceStageUp = NearPrice+DistGrid*i;
     if (CheckSelectPriceForOrderBuy(PriceStageUp) == false && DistUp <=  EdgeDist) {Print("+yeahhh!");SetOrderBuy(PriceStageUp,Lots);}
     if (CheckSelectPriceForOrderSell(PriceStageUp-Spread) == false && DistUp <=  EdgeDist) {Print("+yeahhh!"); SetOrderSell(PriceStageUp-Spread,Lots);}
     double PriceStageDown = NearPrice-DistGrid*i;
     if (CheckSelectPriceForOrderBuy(PriceStageDown) == false && DistDown <=  EdgeDist) {Print("-yeahhh!"); SetOrderBuy(PriceStageDown,Lots);}
     if (CheckSelectPriceForOrderSell(PriceStageDown-Spread) == false && DistDown <=  EdgeDist) {Print("-yeahhh!"); SetOrderSell(PriceStageDown-Spread,Lots);}
    }
  }
//+------------------------------------------------------------------+
//| End                                                              |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| CheckSelectPriceForOrderBuy                                      |
//+------------------------------------------------------------------+

bool CheckSelectPriceForOrderBuy(double Price)
 {
  for (int j=0; j<OrdersTotal(); j++)
    {
     if (OrderSelect(j, SELECT_BY_POS, MODE_TRADES) == false) continue;
     if (OrderOpenPrice()!= Price) { continue;}
     if (OrderMagicNumber() != MagicKey) {continue;}
     if (OrderType() == OP_BUYSTOP)  { return(true);}
     if (OrderType() == OP_BUYLIMIT) { return(true);}
    }
  return(false); 
 }


bool CheckSelectPriceForOrderSell(double Price)
 {
  for (int j=0; j<OrdersTotal(); j++)
    {
     if (OrderSelect(j, SELECT_BY_POS, MODE_TRADES) == false) continue;
     if (OrderOpenPrice()!= Price) { continue;}
     if (OrderMagicNumber() != MagicKey) {continue;}
     if (OrderType() == OP_SELLSTOP)  { return(true);}
     if (OrderType() == OP_SELLLIMIT) { return(true);}
    }
  return(false); 
 }


void SetOrderBuy(double Price, double Lot)
 {
  if (Price > Ask) { OrderSend(Symbol(),OP_BUYSTOP,Lot,Price,0,0,Price+TP,"Grid",MagicKey,0,Blue);}
  else { OrderSend(Symbol(),OP_BUYLIMIT,Lot,Price,0,0,Price+TP,"Grid",MagicKey,0,LightBlue);}
 }


void SetOrderSell(double Price, double Lot)
 {
  if (Price < Ask) { OrderSend(Symbol(),OP_SELLSTOP,Lot,Price,0,0,Price+TP,"Grid",MagicKey,0,Red);}
  else { OrderSend(Symbol(),OP_SELLLIMIT,Lot,Price,0,0,Price+TP,"Grid",MagicKey,0,Magenta);}
 }