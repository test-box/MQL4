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

extern   bool UseBalance= true // ������������ ��� ������� TakeMoney - Balance ���� Equity
extern double Lots      = 0.1;    // ����� ������ � �����
extern   bool LotsAuto  = false;   // �������������� ������ ����
extern double Deposit   = 10000;  // ������ ��������
extern double PrcProfit = 0.5;    // �������� ������� ��� ���������� ������� (������� �� ��������)
extern double MnlProfit = 3.77;       // ������� ������� ������� �������
extern double TP        = 0.0010; // ���������� ������� � �������
extern double BasePrice = 1.6701; // ask-���� ����� �������
extern double Spread    = 0.0003; // �����
extern double StepGrid  = 0.0013; // ���������� ����� ����������� �����
extern    int StepUp    = 8;      // ���������� �������� �� ������� ���� �����, ������� ��������� ��������
extern    int StepDn    = 8;      // ���������� �������� �� ������� ���� �����, ������� ��������� ��������
extern    int MagicKey  = 333;    // ���� ���������, ��� ������������� ����� �������

//+------------------------------------------------------------------+
//| block initialization Variables                                   |
//+------------------------------------------------------------------+
double NewBalance; // ����������� ������ ��� ��������
double TakeMoney;  // 
string takemoney_GV; //
string lot_GV;     // 
double DiffPrice;  // ���������� ����� ��������� ������ � ������� �����
double A1_Price;   // ���� ������ ������� ���������
double B1_Price;   // ���� ������ ������ ���������  
int    Grids;      // ���������� �������� �� ��������� �����
int    CountOrders; // ���������� ������� (���������� CalcOurOrders)
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
  Print("����������� ��� (", minlot, ") : ", NormLot);
  if (IsTesting())
     {
      Print("������� �������� � �����. ������������ �������� ���������� ����������.");
      takemoney_GV="Grid-"+IntegerToString(MagicKey,4,'0')+"_TEST_"+Symbol()+"_TakeMoney";  //������������� �������� ���������� ����������
      lot_GV="Grid-"+IntegerToString(MagicKey,4,'0')+"_TEST_"+Symbol()+"_Lot"; 
     }
   else if(IsDemo())
     {
      Print("������� �������� �� ����-�����. ������������ ����-���������� ����������.");
      takemoney_GV="Grid-"+IntegerToString(MagicKey,4,'0')+"_DEMO_"+Symbol()+"_TakeMoney";  //������������� �������� ���������� ����������
      lot_GV="Grid-"+IntegerToString(MagicKey,4,'0')+"_DEMO_"+Symbol()+"_Lot";
     }
   else
     {
      Print("������� �������� �� �������� �����. ������������ ���������� ���������� ��������� �����.");
      takemoney_GV="Grid-"+IntegerToString(MagicKey,4,'0')+"_"+Symbol()+"_TakeMoney";  //������������� �������� ���������� ���������� (Distance)
      lot_GV="Grid-"+IntegerToString(MagicKey,4,'0')+"_"+Symbol()+"_Lot";
     }
   if (GlobalVariableCheck(takemoney_GV)) {
      TakeMoney = GlobalVariableGet(takemoney_GV);
      Print("���������� ���������: �������� ������� ������� ��� ������ (", takemoney_GV, ")= ", TakeMoney);
     }
   if (GlobalVariableCheck(lot_GV)) {
      lots = GlobalVariableGet(lot_GV);
      Print("���������� ���������: Lot (", lot_GV, ")= ", lots);
     }
  count = CalcOurOrders();
  Print(" �������������: ��������� ������ = ", count);
  if (count == 0)
    {
    NewBalance = AccountBalance();
    Print(" �������������: ��������� ����� ������ = ", NewBalance, ", %= ", NewBalance*PrcProfit/100);
    ReCalculateLot();
    if (lots < minlot) {Print(" ������-�� ��� ��� ���� ������ ", minlot, ", �������� �� = ", minlot); lots = minlot;}
    Print(" �������������: ����������� ��� = ", lots);
    if (MnlProfit == 0)
      {
      TakeMoney = NewBalance + NewBalance*PrcProfit/100;
      SaveSettings();
      Print(" �������������: ������� ����������� - % �������, TakeMoney= ", TakeMoney);
      }
    else
      {
      TakeMoney = NewBalance + MnlProfit;
      SaveSettings();
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
  //double minlot = MarketInfo(Symbol(),MODE_MINLOT);
  //if (lots < minlot) {Print(" ������-�� ��� ��� ���� ������ ", minlot, ", �������� �� = ", Lots); lots = Lots;}
  //lots = Lots;
  //SaveSettings();
  TakeMoney = GlobalVariableGet(takemoney_GV);
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

void SaveSettings()
  {
   if (GlobalVariableSet(takemoney_GV, TakeMoney) == 0) {
      Print("��� ���������� ���������� ���������� takemoney_GV= ", takemoney_GV, "  �������� ������!");
      Print("������ #", GetLastError());
      }
   if (GlobalVariableSet(lot_GV, lots) == 0) {
      Print("��� ���������� ���������� ���������� lot_GV= ", lot_GV, "  �������� ������!");
      Print("������ #", GetLastError());
      }
  }


void ReBurn()
  {
  // �������� ����, ��������� ������, �������� ���� �������
  Print(" ReBurn ������ ���: TakeMoney= ", TakeMoney, ", AccountEquity= ", AccountEquity(), ", �������= ", CountOrders);
  CloseAllOurOrders();
  Print(" ������� ��� ������, ��������...");
  double minlot = MarketInfo(Symbol(),MODE_MINLOT);
  ReCalculateLot();
  if (lots < minlot) {Print(" ������-�� ��� ��� ���� ������ ", minlot, ", �������� �� = ", minlot); lots = minlot;}
  NewBalance = AccountBalance();
  Print(" ReBurn: NewBalance= ", NewBalance);
  if (MnlProfit == 0)
    {
    TakeMoney = NewBalance + NewBalance*PrcProfit/100;
    SaveSettings();
    Print(" ReBurn: ������� ����������� - ", PrcProfit,"% �������, TakeMoney= ", TakeMoney);
    }
  else
    {
    TakeMoney = NewBalance + MnlProfit;
    SaveSettings();
    Print(" ReBurn: ������� ����������� - ������������� �����, TakeMoney= ", TakeMoney);
    }
  }


void CloseAllOurOrders()
  {
   Print("-= ������� �������� ���� ���������� ������� =-");
   int count;
   int k = 0;
   int OrderTicketMassive[200];
   ArrayInitialize(OrderTicketMassive,0);
   for (int t=0; t<OrdersTotal(); t++)  //���� ������ ������� ���������, ������� ������ ������� �������
     {
      if (OrderSelect(t, SELECT_BY_POS, MODE_TRADES) == false) {Print("1-� ��������: ������, (OrderSelect)"); continue;}
      if (OrderMagicNumber() != MagicKey) {Print("2-� ��������: ������, (OrderMagicNumber)"); continue;}
      if (OrderSymbol() != Symbol()) {Print("3-� ��������: ������, (OrderSymbol)"); continue;}
      Print("������ �����, ����� = ", OrderTicket());
      count++;
      OrderTicketMassive[count] = OrderTicket();
     }
   for (int i=1; i <= count; i++)      //���� �������� ��������� �������
     {
      OrderSelect(OrderTicketMassive[i],SELECT_BY_TICKET);
      Print("�����: ����� #", OrderTicket(), ", ��� ������=", OrderType(), ", ������=", OrderSymbol(),
            ", ���� ��������=", OrderOpenPrice(), ", ������� ��=",OrderTakeProfit(), ", ����� �����=", OrderLots(),
            ", idNum=", OrderMagicNumber(), ", �����������=", OrderComment()); 
      switch(OrderType())                       // �� ���� ������
        {
        case OP_BUY:       Print(" CloseOrders: ��������� BUY");
                           ResetLastError();
                           while (OrderClose(OrderTicket(),OrderLots(),Bid,3,clrNONE) != true) {
                             if (_LastError == ERR_INVALID_TICKET || _LastError == ERR_TRADE_NOT_ALLOWED) break; 
                             }
                           break;
        case OP_SELL:      Print(" CloseOrders: ��������� SELL");
                           ResetLastError();
                           while (OrderClose(OrderTicket(),OrderLots(),Ask,3,clrNONE) != true) {
                             if (_LastError == ERR_INVALID_TICKET || _LastError == ERR_TRADE_NOT_ALLOWED) break; 
                             }
                           break;
        case OP_BUYSTOP:   Print(" CloseOrders: ��������� BUYSTOP");
                           ResetLastError();
                           while (OrderDelete(OrderTicket(), clrNONE) != true) {
                             if (_LastError == ERR_INVALID_TICKET || _LastError == ERR_TRADE_NOT_ALLOWED) break; 
                             }
                           break;
        case OP_BUYLIMIT:  Print(" CloseOrders: ��������� BUYLIMIT");
                           ResetLastError();
                           while (OrderDelete(OrderTicket(), clrNONE) != true) {
                             if (_LastError == ERR_INVALID_TICKET || _LastError == ERR_TRADE_NOT_ALLOWED) break; 
                             }
                           break;
        case OP_SELLSTOP:  Print(" CloseOrders: ��������� SELLSTOP");
                           ResetLastError();
                           while (OrderDelete(OrderTicket(), clrNONE) != true) {
                             if (_LastError == ERR_INVALID_TICKET || _LastError == ERR_TRADE_NOT_ALLOWED) break; 
                             }
                           break;
        case OP_SELLLIMIT: Print(" CloseOrders: ��������� SELLLIMIT");
                           ResetLastError();
                           while (OrderDelete(OrderTicket(), clrNONE) != true) {
                             if (_LastError == ERR_INVALID_TICKET || _LastError == ERR_TRADE_NOT_ALLOWED) break; 
                             }
                           break;
      }
     }
   Print("���������� ��������� �������: ", count);
  }


void ReCalculateLot()
  {
  // ������������� ��� �� ����� ������
  if (LotsAuto == true) {
     Print(" Autolot: �������");
     lots = AccountEquity()/Deposit*Lots; // AccountBalance() - ��� ������� ������������ ������ ������ ������
     Print("  ���:", lots, " = AccountEquity:", AccountEquity(), " / Deposit:", Deposit, " * Lots:", Lots);}  
  else {
     lots = Lots;
     Print("  ��� ���������� �������: ", lots, "(", Lots, ")");}
  lots = NormalizeDouble(lots,NormLot);
  Print("  ����������� �������� ���� �� ", NormLot, " ������ ����� �������, ���������� = ", lots);
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
  CountOrders = c;
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
