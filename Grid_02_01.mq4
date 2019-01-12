//+------------------------------------------------------------------+
//|                                                   grid_02_01.mq4 |
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
extern   bool LotsAuto  = true;   // �������������� ������ ����
extern double Deposit   = 10000;  // ������ ��������
extern double PrcProfit = 0.5;    // �������� ������� ��� ���������� ������� (������� �� ��������)
extern double MnlProfit = 0;       // ������� ������� ������� �������
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
bool   ReBurnFlag = true; // ���� ������������
double NewBalance; // ����������� ������ ��� ��������
double TakeMoney;  // 
double DiffPrice;  // ���������� ����� ��������� ������ � ������� �����
double A1_Price;   // ���� ������ ������� ���������
double B1_Price;   // ���� ������ ������ ���������  
int    Grids;      // ���������� �������� �� ��������� �����
double lots;       // ������ ����
double count;      // ������� ����� ������� (MagicKey)
double A_PriceAsk[21], A_PriceBid[21]; // ������� � ������ ������� ���� �������� ����
double B_PriceAsk[21], B_PriceBid[21]; // ������� � ������ ������� ���� �������� ����
int    i;          // �������
//string ordersType[6] = {"BUY", "SELL", "BUYLIMIT", "SELLLIMIT", "BUYSTOP", "SELLSTOP"};


//+------------------------------------------------------------------+
//| expert initialization and deinitialization function              |
//+------------------------------------------------------------------+
int init()
  {
  //
  //if (ReBurnFlag == true) ReCalculateLot(); 
  count = CalcOurOrders();
  Print(" �������������: ��������� ������");
  if (count == 0)
    {
    NewBalance = AccountBalance();
    Print(" �������������: ��������� ����� ������ = ", NewBalance, ", %= ", NewBalance*PrcProfit/100);
    ReCalculateLot();
    Print(" �������������: ����������� ���");
    if (MnlProfit = 0) {TakeMoney = NewBalance + NewBalance*PrcProfit/100; Print(" �������������: ��������� ������� ����������� - % �������");}
    else {TakeMoney = NewBalance + MnlProfit; Print(" �������������: ��������� ������� ����������� - ������������� �����");}
    }
  return(0);
  }
int deinit() {return(0);}


//+------------------------------------------------------------------+
//|                     Expert Start function                        |
//+------------------------------------------------------------------+
int start()
  {
  Print(" �������: TakeMoney= ", TakeMoney, ", AccountEquity= ", AccountEquity());
  if (TakeMoney < AccountEquity() && CalcOurOrders()!= 0) {ReBurn();}
  Print("�������");
  DiffPrice = MathAbs(BasePrice-Ask); // ���������� � ������� ����� ������� ����� � BasePrice
  //Print("DiffPrice= ", "BasePrice(", BasePrice, ") - ASK(", Ask, ") = ", DiffPrice*10000);
  if (BasePrice > Ask)
    {
    Grids = MathFloor(DiffPrice/StepGrid); // ���������� �������� �� BasePrice �� ��������� � ������� ���� ��������� 
    A1_Price = BasePrice - Grids*StepGrid; //���� ������ ������� ���������
    B1_Price = A1_Price - StepGrid;        //���� ������ ������ ���������
    }
  if (BasePrice < Ask)
    {
    Grids = MathFloor(DiffPrice/StepGrid); // ���������� �������� �� BasePrice �� ��������� � ������� ���� ���������
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
  // �������� ����, ��������� ������, �������� ���� �������
  ReCalculateLot();
  Print(" ReBurn: ����������� ���");
  NewBalance = AccountBalance();
  if (MnlProfit = 0) {TakeMoney = NewBalance + NewBalance*PrcProfit/100; Print(" ReBurn: ��������� ������� ����������� - % �������");}
    else {TakeMoney = NewBalance + MnlProfit; Print(" ReBurn: ��������� ������� ����������� - ������������� �����");}
  for (int j = 1; (CalcOurOrders() != 0) && (j<=5); j++) 
    {
    CloseAllOurOrders();
    Print(" ������� ��� ������, ��������...");
    }  
  }

bool CloseAllOurOrders()
  {
  Print(" CloseAllOurOrders: ��������� ��� ���� ������");
  bool err = false;
  for (int j=0; j<OrdersTotal(); j++)
    {
    if (OrderSelect(j, SELECT_BY_POS, MODE_TRADES) == false) {continue;} // �� ������ ������� ����� - ���������� ����
    if (OrderMagicNumber() != MagicKey) {continue;} // �� ��� ������ - ���������� ����
    if (OrderSymbol() != Symbol()) {continue;}      // �� ��� ���������� - ���������� ����
    switch(OrderType())                       // �� ���� ������
      {
      case OP_BUY:       OrderClose(OrderTicket(),OrderLots(),Bid,3,clrNONE); Print(" CloseOrders: ������� BUY"); break;
      case OP_SELL:      OrderClose(OrderTicket(),OrderLots(),Ask,3,clrNONE); Print(" CloseOrders: ������� SELL"); break;   
      case OP_BUYSTOP:   OrderDelete(OrderTicket(), clrNONE); Print(" CloseOrders: ������� BUYSTOP"); break;
      case OP_BUYLIMIT:  OrderDelete(OrderTicket(), clrNONE); Print(" CloseOrders: ������� BUYLIMIT"); break;
      case OP_SELLSTOP:  OrderDelete(OrderTicket(), clrNONE); Print(" CloseOrders: ������� SELLSTOP"); break;
      case OP_SELLLIMIT: OrderDelete(OrderTicket(), clrNONE); Print(" CloseOrders: ������� SELLLIMIT"); break;
      }
    }
  return(err);
  }

void ReCalculateLot()
  {
  if (LotsAuto == true) {lots = AccountEquity()/Deposit*Lots;}  // AccountBalance() - ��� ������� ������������ ������ ������ ������
  else {lots = Lots;}
  }

int CalcOurOrders()
  {
  int c = 0;
  for (int j=0; j<OrdersTotal(); j++)
    {
    if (OrderSelect(j, SELECT_BY_POS, MODE_TRADES) == false) {continue;} // ���������� ����
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
    if (OrderSelect(j, SELECT_BY_POS, MODE_TRADES) == false) {continue;} // ���������� ����
    //Print(Price, ", ������ ", ordersType[OrderType()], ", OrderTicket=", OrderTicket(),", ���� ���������� ������=  ", OrderOpenPrice(), ", Magic= ", OrderMagicNumber());
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
