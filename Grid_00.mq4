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
extern double BasePrice	 = 1.3603;	// ���� ask ����� �������
extern double Spread        = 0.0003;	// �����
extern double StepGrid      = 0.0010;	// ���������� ����� ����������� �����
extern    int StepUp    = 5;		// ���������� �������� �� ������� ���� �����, ������� ��������� ��������
extern    int StepDn    = 5;		// ���������� �������� �� ������� ���� �����, ������� ��������� ��������
extern    int MagicKey      = 789;		// ���� ���������, ��� ������������� ����� �������
extern string CommentOrder = "Grid";   // ����������� � ��������������� �������, ��� ����������� ����������� ������� ���������
//+------------------------------------------------------------------+
//| block initialization Variables                                   |
//+------------------------------------------------------------------+
string version = "Grid v0.04";
double DiffPrice; // ���������� ����� ��������� ������ � ������� �����
double NearPrice; // ���� ��������� � ������� ���� ��������� 
int    Grids;   // ���������� �������� �� ��������� �����
int    EdgeDist;  // ���������� �� �������� ������
int    i;         // �������
bool   fresh = true;     // ���� ������� ����������
string tiketsUP[21];
string tiketsDN[21];
int OrdersUp[22][9];
int OrdersDn[22][9];
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
  Print("��������: ", version, ", �������������... ", "MagicKey: ", MagicKey, ", CommentOrder: ", CommentOrder);
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
  
  DiffPrice = MathAbs(BasePrice-Ask); // ���������� � ������� ����� ������� ����� � BasePrice
  Grids = MathRound(DiffPrice/StepGrid); // ���������� �������� �� ��������� � ������� ���� ��������� �� BasePrice
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
  DiffPrice = MathAbs(BasePrice-Ask); // ���������� � ������� ����� ������� ����� � BasePrice
  Grids = MathRound(DiffPrice/StepGrid); // ���������� �������� �� ��������� � ������� ���� ��������� �� BasePrice
  if (BasePrice > Ask) {NearPrice = BasePrice - Grids*StepGrid;}
  else if (BasePrice < Ask) {NearPrice = BasePrice + Grids*StepGrid;}
       else {NearPrice = BasePrice;}
  double HiPrice = NearPrice - StepDn*StepGrid; // ���� ������� ������
  int TotalSteps = StepDn + StepUp; // ����� ��������������� �������� �������
  for (i = 1; i <= TotalSteps; i++)    // ���� ��������� ����� ������� (������ ������ ��������)                                         
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
        OrdersUp[i][1]=OrderOpenPrice();    // ���� �������� ������
        OrdersUp[i][2]=OrderStopLoss();     // ���� SL
        OrdersUp[i][3]=OrderTakeProfit();   // ���� ��
        //OrdersUp[i][4]=OrderTicket();       // ����� ������
        OrdersUp[i][5]=OrderLots();         // ���������� �����
        OrdersUp[i][6]=OrderType();         // ��� ������
        OrdersUp[i][7]=OrderMagicNumber();  // ���������� ����� 
        if (OrderComment()=="") OrdersUp[i][8]=0; // ���� ��� �������
        else OrdersUp[i][8]=1;                // ���� ���� �������
        }
      else OrdersUp[i][4] = -1;
      }
    }
    if(i <= StepDn)
      {
      if(OrderSelect(OrdersDn[i][4],SELECT_BY_TICKET)==true)
        {
        OrdersDn[i][1]=OrderOpenPrice();    // ���� �������� ������
        OrdersDn[i][2]=OrderStopLoss();     // ���� SL
        OrdersDn[i][3]=OrderTakeProfit();   // ���� ��
        //OrdersDn[i][4]=OrderTicket();       // ����� ������
        OrdersDn[i][5]=OrderLots();         // ���������� �����
        OrdersDn[i][6]=OrderType();         // ��� ������
        OrdersDn[i][7]=OrderMagicNumber();  // ���������� ����� 
        if (OrderComment()=="") OrdersDn[i][8]=0; // ���� ��� �������a
        else OrdersDn[i][8]=1;                // ���� ���� �������
        }
      else OrdersDn[i][4] = -1;
      }
    }
  }