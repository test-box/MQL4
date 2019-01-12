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
extern double BasePrice	 = 1.3603;	// цена ask точки отсчета
extern double Spread        = 0.0003;	// спрэд
extern double StepGrid      = 0.0010;	// расстояние между стубеньками сетки
extern    int StepUp    = 5;		// количество ступенек от текущей цены вверх, которое мониторит советник
extern    int StepDn    = 5;		// количество ступенек от текущей цены вверх, которое мониторит советник
extern    int MagicKey      = 789;		// ключ советника, для распознавания своих ордеров
extern string CommentOrder = "Grid";   // комментарий к устанавливаемым ордерам, для визуального опознования ордеров советника
//+------------------------------------------------------------------+
//| block initialization Variables                                   |
//+------------------------------------------------------------------+
string version = "Grid v0.04";
double DiffPrice; // Расстояние между отправной точкой и текущей ценой
double NearPrice; // цена ближайшей к текущей цене ступеньки 
int    Grids;   // количество ступенек от отправной точки
int    EdgeDist;  // Расстояние до крайнего ордера
int    i;         // счетчик
bool   fresh = true;     // флаг первого исполнения
string tiketsUP[21];
string tiketsDN[21];
int OrdersUp[22][9];
int OrdersDn[22][9];
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
  Print("Советник: ", version, ", инициализация... ", "MagicKey: ", MagicKey, ", CommentOrder: ", CommentOrder);
  ArrayInitialize(tiketsUP,0); ArrayInitialize(tiketsDN,0);
  ArrayInitialize(OrdersUp,0); ArrayInitialize(OrdersDn,0);
  for (int i=1; i<= MathMax(StepUp,StepDn); i++)
    {
    tiketsUP[i] = "GRID_"+Symbol()+"_OrdersUp_" + IntegerToString(i,2,'0');
    if (GlobalVariableCheck(tiketsUP[i])) {OrdersUp[i][4] = GlobalVariableGet(tiketsUP[i]); Print(tiketsUP[i], "= ", OrdersUp[i][4]);}
    tiketsDN[i] = "GRID_"+Symbol()+"_OrdersDn_" + IntegerToString(i,2,'0');
    if (GlobalVariableCheck(tiketsDN[i])) {OrdersDn[i][4] = GlobalVariableGet(tiketsDN[i]); Print(tiketsDN[i], "= ", OrdersDn[i][4]);}
    }
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
  CheckStatus();
  for (int i=1; i<= MathMax(StepUp,StepDn); i++)
    {
    if 
    }
  
  DiffPrice = MathAbs(BasePrice-Ask); // расстояние в пунктах между текущей ценой и BasePrice
  Grids = MathRound(DiffPrice/StepGrid); // количество ступенек от ближайшей в текущей цене ступеньки до BasePrice
  if (BasePrice > Ask) {NearPrice = BasePrice - Grids*StepGrid;}
  else if (BasePrice < Ask) {NearPrice = BasePrice + Grids*StepGrid;}
       else {NearPrice = BasePrice;}
  EdgeDist = MathMax(StepUp,StepDn);
  for (i = 1; i <= EdgeDist; i++)                                             
    {
	double PriceAsk = NearPrice + StepGrid*i;
	double PriceBid = PriceAsk - Spread;
    if (CheckOrderBuy(PriceAsk) == false && StepUp <=  EdgeDist) { SetOrderBuy(PriceAsk,Lots);}
    if (CheckOrderSell(PriceBid) == false && StepUp <=  EdgeDist) { SetOrderSell(PriceBid,Lots);}
    double PriceAsk = NearPrice - StepGrid*i;
	double PriceBid = PriceAsk - Spread;
    if (CheckOrderBuy(PriceAsk) == false && StepDn <=  EdgeDist) { SetOrderBuy(PriceAsk,Lots);}
    if (CheckOrderSell(PriceBid) == false && StepDn <=  EdgeDist) { SetOrderSell(PriceBid,Lots);}
    }
  }
//+------------------------------------------------------------------+
//| End                                                              |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                           Functions                              |
//+------------------------------------------------------------------+

bool CheckOrderBuy(double Price)
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


bool CheckOrderSell(double Price)
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
  double tp = Price + TP; 
  if (Price > Ask) { OrderSend(Symbol(),OP_BUYSTOP,Lot,Price,0,0,tp,"Grid",MagicKey,0,Blue);}
  else { OrderSend(Symbol(),OP_BUYLIMIT,Lot,Price,0,0,tp,"Grid",MagicKey,0,LightBlue);}
  }


void SetOrderSell(double Price, double Lot)
  {
  double tp = Price - TP; 
  if (Price < Ask) { OrderSend(Symbol(),OP_SELLSTOP,Lot,Price,0,0,tp,"Grid",MagicKey,0,Red);}
  else { OrderSend(Symbol(),OP_SELLLIMIT,Lot,Price,0,0,tp,"Grid",MagicKey,0,Magenta);}
  }


void StartupSet()
  {
  DiffPrice = MathAbs(BasePrice-Ask); // расстояние в пунктах между текущей ценой и BasePrice
  Grids = MathRound(DiffPrice/StepGrid); // количество ступенек от ближайшей в текущей цене ступеньки до BasePrice
  if (BasePrice > Ask) {NearPrice = BasePrice - Grids*StepGrid;}
  else if (BasePrice < Ask) {NearPrice = BasePrice + Grids*StepGrid;}
       else {NearPrice = BasePrice;}
  double HiPrice = NearPrice - StepDn*StepGrid; // Цена нижнего ордера
  int TotalSteps = StepDn + StepUp; // всего устанавливаемых ступенек ордеров
  for (i = 1; i <= TotalSteps; i++)    // Цикл установки новых ордеров (начало работы эксперта)                                         
    {
    double PriceAsk = NearPrice + StepGrid*i;
    double PriceBid = PriceAsk - Spread;
    SetOrderBuy(PriceAsk, Lots);
    SetOrderSell(PriceBid, Lots);
    }
  }


void CheckStatus()
  {
  for (int i=1; i<= MathMax(StepUp,StepDn); i++)
    {
    if(i <= StepUp)
      {
      if(OrderSelect(OrdersUp[i][4],SELECT_BY_TICKET)==true) 
        {
        OrdersUp[i][1]=OrderOpenPrice();    // Цена открытия ордера
        OrdersUp[i][2]=OrderStopLoss();     // Цена SL
        OrdersUp[i][3]=OrderTakeProfit();   // Цена ТР
        //OrdersUp[i][4]=OrderTicket();       // Номер ордера
        OrdersUp[i][5]=OrderLots();         // Количество лотов
        OrdersUp[i][6]=OrderType();         // Тип ордера
        OrdersUp[i][7]=OrderMagicNumber();  // Магическое число 
        if (OrderComment()=="") OrdersUp[i][8]=0; // Если нет коммент
        else OrdersUp[i][8]=1;                // Если есть коммент
        }
      else OrdersUp[i][4] = -1;
      }
    }
    if(i <= StepDn)
      {
      if(OrderSelect(OrdersDn[i][4],SELECT_BY_TICKET)==true)
        {
        OrdersDn[i][1]=OrderOpenPrice();    // Цена открытия ордера
        OrdersDn[i][2]=OrderStopLoss();     // Цена SL
        OrdersDn[i][3]=OrderTakeProfit();   // Цена ТР
        //OrdersDn[i][4]=OrderTicket();       // Номер ордера
        OrdersDn[i][5]=OrderLots();         // Количество лотов
        OrdersDn[i][6]=OrderType();         // Тип ордера
        OrdersDn[i][7]=OrderMagicNumber();  // Магическое число 
        if (OrderComment()=="") OrdersDn[i][8]=0; // Если нет комментa
        else OrdersDn[i][8]=1;                // Если есть коммент
        }
      else OrdersDn[i][4] = -1;
      }
    }
  }