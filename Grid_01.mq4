//+------------------------------------------------------------------+
//|                                                         grid.mq4 |
//|                                        Copyright � 2014,  GlobuX |
//|                                                 globuq@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright � 2014,  GlobuX"
#property link      "globuq@gmail.com"
#include <stderror.mqh>

//+------------------------------------------------------------------+
//| block initialization external Variables                          |
//+------------------------------------------------------------------+
extern double Lots          = 0.1;     // ����� ������ � �����
extern double TP            = 0.0010;  // ���������� ������� � �������
extern double BaseBuyPrice	 = 1.3603;	// ���� ask ����� �������
extern double BaseSellPrice = 1.3600;	// ���� bid ����� �������
extern double Spread        = 0.0003;	// �����
extern double DistGrid      = 0.0010;	// ���������� ����� ����������� �����
extern    int DistUp    = 20;		// ���������� �������� �� ������� ���� �����, ������� ��������� ��������
extern    int DistDown  = 20;		// ���������� �������� �� ������� ���� �����, ������� ��������� ��������
extern    int MagicKey      = 789;		// ���� ���������, ��� ������������� ����� �������

//+------------------------------------------------------------------+
//| block initialization Variables                                   |
//+------------------------------------------------------------------+
double DiffPrice; // ���������� ����� ��������� ������ � ������� �����
double NearPrice; // ���� ��������� � ������� ���� ��������� 
int    QntGrid;   // ���������� �������� �� ��������� �����
int    EdgeDist;
int    i;         // ��������


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
   DiffPrice = MathAbs(BaseBuyPrice-Ask); // ���������� � ������� ����� ������� ����� � BaseBuyPrice
   QntGrid = MathRound(DiffPrice/DistGrid); // ���������� �������� �� ��������� � ������� ���� ��������� �� BaseBuyPrice
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