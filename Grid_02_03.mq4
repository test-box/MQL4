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
extern double BasePrice = 1.3603; // ask-���� ����� �������
extern double Spread    = 0.0003; // �����
extern double StepGrid  = 0.0010; // ���������� ����� ����������� �����
extern    int StepUp    = 4;      // ���������� �������� �� ������� ���� �����, ������� ��������� ��������
extern    int StepDn    = 5;      // ���������� �������� �� ������� ���� �����, ������� ��������� ��������
extern    int MagicKey  = 789;    // ���� ���������, ��� ������������� ����� �������

//+------------------------------------------------------------------+
//| block initialization Variables                                   |
//+------------------------------------------------------------------+
double NewBalance; // ����������� ������ ��� ��������
double TakeMoney;  // 
string takemoney_GV; //
double DiffPrice;  // ���������� ����� ��������� ������ � ������� �����
double A1_Price;   // ���� ������ ������� ���������
double B1_Price;   // ���� ������ ������ ���������  
int    Grids;      // ���������� �������� �� ��������� �����
double lots;       // ������ ����
int    NormLot;    //
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
  double minlot = MarketInfo(Symbol(),MODE_MINLOT);
  if (minlot == 0.0001) NormLot = 4;
  else if (minlot == 0.001) NormLot = 3;
       else if (minlot == 0.01) NormLot = 2;
            else if (minlot == 0.1) NormLot = 1;
                 else if (minlot == 1) NormLot = 0;
                      else NormLot = 2;
  Print("��������� ���� (", minlot, ") : ", NormLot);
  if (IsTesting())
     {
      Print("������� �������� � �����. ������������ �������� ���������� ����������.");
      takemoney_GV="Grid-"+IntegerToString(MagicKey,4,'0')+"_TEST_"+Symbol()+"_TakeMoney";  //������������� �������� ���������� ����������
     }
   else if(IsDemo())
     {
      Print("������� �������� �� ����-�����. ������������ ����-���������� ����������.");
      takemoney_GV="Grid-"+IntegerToString(MagicKey,4,'0')+"_DEMO_"+Symbol()+"_TakeMoney";  //������������� �������� ���������� ����������
     }
   else
     {
      Print("������� �������� �� �������� �����. ������������ ���������� ���������� ��������� �����.");
      takemoney_GV="Grid-"+IntegerToString(MagicKey,4,'0')+"_"+Symbol()+"_TakeMoney";  //������������� �������� ���������� ���������� (Distance)
     }
   if (GlobalVariableCheck(takemoney_GV))
     {
      TakeMoney = GlobalVariableGet(takemoney_GV);
      Print("���������� ���������: �������� ������� ������� ��� ������ (", takemoney_GV, ")= ", TakeMoney);
     }
  count = CalcOurOrders();
  //Print(" �������������: ��������� ������");
  if (count == 0)
    {
    NewBalance = AccountBalance();
    Print(" �������������: ��������� ����� ������ = ", NewBalance, ", %= ", NewBalance*PrcProfit/100);
    ReCalculateLot();
    //Print(" �������������: ����������� ���");
    if (MnlProfit == 0)
      {
      TakeMoney = NewBalance + NewBalance*PrcProfit/100;
      SaveTakeMoney();
      Print(" �������������: ������� ����������� - % �������, TakeMoney= ", TakeMoney);
      }
    else
      {
      TakeMoney = NewBalance + MnlProfit;
      SaveTakeMoney();
      Print(" �������������: ������� ����������� - ������������� �����, TakeMoney= ", TakeMoney);
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
  //Print(" �������: TakeMoney= ", TakeMoney, ", AccountEquity= ", AccountEquity());
  if (TakeMoney < AccountEquity() && CalcOurOrders()!= 0) {ReBurn();}
  //Print("�������");
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
  int max = MathMax(StepUp, StepDn);
  for (i=1; i<=max; i++)  // ���������� �������� ������ ��� ����� �������
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

void SaveTakeMoney()
  {
   if (GlobalVariableSet(takemoney_GV, TakeMoney) == 0)
     {
      Print("��� ���������� ���������� ���������� takemoney_GV= ", takemoney_GV, "  �������� ������!");
      Print("������ #", GetLastError());
     }
  }


void ReBurn()
  {
  // �������� ����, ��������� ������, �������� ���� �������
  ReCalculateLot();
  //Print(" ReBurn: ����������� ���");
  NewBalance = AccountBalance();
  if (MnlProfit == 0)
    {
    TakeMoney = NewBalance + NewBalance*PrcProfit/100;
    SaveTakeMoney();
    Print(" ReBurn: ������� ����������� - % �������, TakeMoney= ", TakeMoney);
    }
  else
    {
    TakeMoney = NewBalance + MnlProfit;
    SaveTakeMoney();
    Print(" ReBurn: ������� ����������� - ������������� �����, TakeMoney= ", TakeMoney);
    }
  for (int j = 1; (CalcOurOrders() != 0) && (j<=10); j++) 
    {
    CloseAllOurOrders();
    Print(" ������� ��� ������, ��������...");
    }  
  }

bool CloseAllOurOrders()
  {
  // ��������� ��� ���� ������
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
  // ������������� ��� �� ����� ������
  if (LotsAuto == true) {lots = AccountEquity()/Deposit*Lots;}  // AccountBalance() - ��� ������� ������������ ������ ������ ������
  else {lots = Lots;}
  lots = NormalizeDouble(lots,NormLot);
  }

int CalcOurOrders()
  {
  // ������������ ���������� ����� �������
  int c = 0;
  for (int j=0; j<OrdersTotal(); j++)
    {
    if (OrderSelect(j, SELECT_BY_POS, MODE_TRADES) == false) {continue;} // ���������� ����
    if (OrderMagicNumber() == MagicKey && OrderSymbol() == Symbol()) { c++; }
    }
  return(c);
  }


void RefreshOrders()
  {
  // ��������������� ����� �������, ���� ���� �������� ������
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
  // ��������� ���� �� ��� ����� � ��������� �����
  bool result = false;
  if (OrdersTotal() < 1) return(result);
  for (int j=0; j<OrdersTotal(); j++)
    {
    if (OrderSelect(j, SELECT_BY_POS, MODE_TRADES) == false) {continue;} // ���������� ����
    //Print(Price, ", ������ ", ordersType[OrderType()], ", OrderTicket=", OrderTicket(),", ���� ���������� ������=  ", OrderOpenPrice(), ", Magic= ", OrderMagicNumber());
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
