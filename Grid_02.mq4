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
extern double Lots      = 0.1;    // ����� ������ � �����
extern double TP        = 0.0013; // ���������� ������� � �������
extern double BasePrice = 1.3603; // ���� ask ����� �������
extern double Spread    = 0.0003; // �����
extern double StepGrid  = 0.0010; // ���������� ����� ����������� �����
extern    int StepUp    = 4;      // ���������� �������� �� ������� ���� �����, ������� ��������� ��������
extern    int StepDn    = 5;      // ���������� �������� �� ������� ���� �����, ������� ��������� ��������
extern    int MagicKey  = 789;    // ���� ���������, ��� ������������� ����� �������

//+------------------------------------------------------------------+
//| block initialization Variables                                   |
//+------------------------------------------------------------------+
double DiffPrice; // ���������� ����� ��������� ������ � ������� �����
double NearPrice; // ���� ��������� ��������� � ������� ����
double A1_Price;  // ���� ������ ������� ���������
double B1_Price;  // ���� ������ ������ ���������  
int    Grids;     // ���������� �������� �� ��������� �����
int    EdgeStep;  // ���������� �� �������� ������
int    i;         // �������
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
  DiffPrice = MathAbs(BasePrice-Ask); // ���������� � ������� ����� ������� ����� � BasePrice
  Print("DiffPrice= ", "BasePrice(", BasePrice, ") - ASK(", Ask, ") = ", DiffPrice*10000);
  if (BasePrice > Ask)
    {
    Grids = MathFloor(DiffPrice/StepGrid); // ���������� �������� �� BasePrice �� ��������� � ������� ���� ��������� 
    A1_Price = BasePrice - Grids*StepGrid; //���� ������ ������� ���������
    B1_Price = A1_Price - StepGrid;        //���� ������ ������ ���������
    Print("BasePrice > Ask", ", Grids= ", Grids, ", A1_Price= ", A1_Price, ", B1_Price= ", B1_Price);
    }
  if (BasePrice < Ask)
    {
    Grids = MathFloor(DiffPrice/StepGrid); // ���������� �������� �� BasePrice �� ��������� � ������� ���� ���������
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
    if (OrderSelect(j, SELECT_BY_POS, MODE_TRADES) == false) {Print("������ �������, ���������� ����, �������� ������"); continue; }
    Print("������", ordersType[OrderType()], ", OrderTicket=", OrderTicket(),", ���� ���������� ������=  ", OrderOpenPrice(), "Magic= ", OrderMagicNumber());
    Print("��������� ��� ��� ���");
    if (OrderMagicNumber() != MagicKey) { Print("������ �����"); continue;}
    if (OrderOpenPrice()!= Price) { Print("������ ����"); continue;}
    Print("���� � ����� �� �������. ����� ������� �����, �� ���� =", Price);
    return(false);
    }   Print("��� ������ ���������, ���������� �� �������. ����� ������� �����, �� ����= ", Price);
  Print("����� ����� ��� ����, ������� ����� �� �����");   
  return(true); 
  } */


bool CheckOrder(double Price)
  {
  bool result = false;
  if (OrdersTotal() < 1) return(result);
  for (int j=0; j<OrdersTotal(); j++)
    {
    if (OrderSelect(j, SELECT_BY_POS, MODE_TRADES) == false) {continue;} // ���������� ����
    Print(Price, ", ������ ", ordersType[OrderType()], ", OrderTicket=", OrderTicket(),", ���� ���������� ������=  ", OrderOpenPrice(), ", Magic= ", OrderMagicNumber());
    if ((OrderMagicNumber() == MagicKey) && (NormalizeDouble(OrderOpenPrice(),_Digits) == NormalizeDouble(Price,_Digits)))
       { Print("���� � ����� �������! ������ �� ��������� ������ ������!"); result = true; return(result);  }
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
