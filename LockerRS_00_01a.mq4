//+------------------------------------------------------------------+
//|                                            LockResetStrategy.mq4 |
//|                                           Copyright 2013, GlobuX |
//|                                                 globuq@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, GlobuX."
#property link      "globuq@gmail.com"

#define TICKET   1
#define PRICE    2
#define LOTS     3

//---------���������� ��������� ���������----------//
extern double firstlot = 0.01;
extern double inclot   = 0.01;
extern double multidist = 4;
extern double multiin = 5;
extern double multiout = 1;
extern int    maxQorders = 20;
extern double maxDDpercent = 60;
extern int    DistancePips = 20;
extern int    IdNum = 900;               // ������������� ���������, ��������� ��� ������������� ���������� ����� �������
extern string CommentOrder = "LRS v0.1"; // ����������� � ��������������� �������, ��� ����������� ����������� ������� ���������

//--------���������� ���������� ���������----------//
string GV_Bticket, GV_Sticket, GV_BSticket, GV_SLticket, GV_BLticket, GV_SSticket;
//string GV_BuyPrice, GV_SellPrice, GV_BuyStopPrice, GV_SellLimitPrice, GV_BuyLimitPrice, GV_SellStopPrice;
//string GV_BuyTP, GV_SellTP, GV_BuyStopTP, GV_SellLimitTP, GV_BuyLimitTP, GV_SellStopTP;

//--------���������� ���������� ��������----------//
int    Bticket, Sticket, BSticket, SLticket, BLticket, SSticket;
double BP, SP, BSP, SLP, BLP, SSP;               // ���� ������� �������
double BTP, STP, BSTP, SLTP, BLTP, SSTP;         // ����������� ������� �������
double B_lot, S_lot, BSlot, SLlot, BLlot, SSlot; // ���� ������� �������
double BSPsumlots, SSPsumlots;                   // ����� ����� ������� �� ������� ����
int    BuyOrdersCurrentPrice, SellOrdersCurrentPrice;
bool   BS_activated, SL_activated, BL_activated, SS_activated;
bool   NoOrders, StopOrdersActivated;
double TP, distance;
double SumLotsBuy, SumLotsSell;
int    pipsTP;
double POINT;
int    OrdersCount;
int    buyMassive[3][100];
int    sellMassive[3][100];

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
   Print("��������: ATWv07, �������������. ", "IdNum: ", IdNum, ", CommentOrder: ", CommentOrder);
   if (Point < 0.0001) POINT = Point*10;
   else POINT = Point;
   distance = DistancePips * POINT;
   TP = distance*multidist - (Ask - Bid);
   pipsTP = TP/POINT;
   initCheckOrders();
   Print("����� ����������� ���������: ");
   GV_Bticket = "LRS_" + Symbol() + "_Buy_Ticket";
   if (GlobalVariableCheck(GV_Bticket))
     { Bticket = GlobalVariableGet(GV_Bticket); Print(GV_Bticket, " = ", Bticket); }
   GV_Sticket = "LRS_" + Symbol() + "_Sell_Ticket";
   if (GlobalVariableCheck(GV_Sticket))
     { Sticket = GlobalVariableGet(GV_Sticket); Print(GV_Sticket, " = ", Sticket); }
   GV_BSticket = "LRS_" + Symbol() + "_BuyStop_Ticket";
   if (GlobalVariableCheck(GV_BSticket))
     { BSticket = GlobalVariableGet(GV_BSticket); Print(GV_BSticket, " = ", BSticket); }
   GV_SLticket = "LRS_" + Symbol() + "_SellLimit_Ticket";
   if (GlobalVariableCheck(GV_SLticket))
     { SLticket = GlobalVariableGet(GV_SLticket); Print(GV_SLticket, " = ", SLticket); }
   GV_BLticket = "LRS_" + Symbol() + "_BuyLimit_Ticket";
   if (GlobalVariableCheck(GV_BLticket))
     { BLticket = GlobalVariableGet(GV_BLticket); Print(GV_BLticket, " = ", BLticket); }
   GV_SSticket = "LRS_" + Symbol() + "_SellStop_Ticket";
   if (GlobalVariableCheck(GV_SSticket))
     { SSticket = GlobalVariableGet(GV_SSticket); Print(GV_SSticket, " = ", SSticket); }
  }
  
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
   GlobalVariableSet(GV_Bticket,  Bticket );
   GlobalVariableSet(GV_Sticket,  Sticket );
   GlobalVariableSet(GV_BSticket, BSticket);
   GlobalVariableSet(GV_SLticket, SLticket);
   GlobalVariableSet(GV_BLticket, BLticket);
   GlobalVariableSet(GV_SSticket, SSticket);
  }
  
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
   CheckExistOrders();
   // ������� Reset();
   if (OrdersCount == 0) {InitOrdersSet(); return(0);}
   if (StopOrdersActivated == true) {DeleteNotActivatedStopOrders(); SetLockers(); StopOrdersActivated = false;}
  }
//+------------------------------------------------------------------+


void initCheckOrders()
  {
   int countBuy = 0; int countSell = 0; int countBuyStop = 0; int countSellLimit = 0; int countBuyLimit = 0; int countSellStop = 0;
   for (int i=0; i<OrdersTotal(); i++)
     {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) continue;
      if (OrderMagicNumber() != IdNum) continue;
      if (OrderSymbol() != Symbol()) continue;
      // if (StringFind(OrderComment(), CommentOrder, 0) == -1) continue;
      switch(OrderType()) {
      case OP_BUY:       countBuy++;       break;   
      case OP_SELL:      countSell++;      break; 
      case OP_BUYSTOP:   countBuyStop++;   break;
      case OP_SELLLIMIT: countSellLimit++; break;
      case OP_BUYLIMIT:  countBuyLimit++;  break;
      case OP_SELLSTOP:  countSellStop++;  break; }
     }
   OrdersCount = countBuy + countSell + countBuyStop + countSellLimit + countBuyLimit + countSellStop;
  }


void DeleteNotActivatedStopOrders()
  {
   Print("����������� ������� DeleteNotActivatedStopOrders");
   if (BS_activated == true && SL_activated == true) {OrderDelete(BLticket); OrderDelete(SSticket);}
   if (BL_activated == true && SS_activated == true) {OrderDelete(BSticket); OrderDelete(SLticket);}
   Print("������� DeleteNotActivatedStopOrders ���������");
  }


void CheckExistOrders()
  {
   ArrayInitialize(buyMassive  ,0);
   ArrayInitialize(sellMassive ,0);
   BS_activated = false; SL_activated = false; BL_activated = false; SS_activated = false;
   // ����� ����������� ���������� �������
   if (OrderSelect(BSticket, SELECT_BY_TICKET) == true && OrderType() == OP_BUY)  {BS_activated = true; Bticket = OrderTicket(); BP = OrderOpenPrice(); B_lot = OrderLots(); StopOrdersActivated = true;}
   if (OrderSelect(SLticket, SELECT_BY_TICKET) == true && OrderType() == OP_SELL) {SL_activated = true; Sticket = OrderTicket(); SP = OrderOpenPrice(); S_lot = OrderLots(); StopOrdersActivated = true;}
   if (OrderSelect(BLticket, SELECT_BY_TICKET) == true && OrderType() == OP_BUY)  {BL_activated = true; Bticket = OrderTicket(); BP = OrderOpenPrice(); B_lot = OrderLots(); StopOrdersActivated = true;}
   if (OrderSelect(SSticket, SELECT_BY_TICKET) == true && OrderType() == OP_SELL) {SS_activated = true; Sticket = OrderTicket(); SP = OrderOpenPrice(); S_lot = OrderLots(); StopOrdersActivated = true;}
   //if (BS_activated == false && SL_activated == false && BL_activated == false && SS_activated == false) return(0);
   // ����� ������� � ������� ����� �����
   int countBuy = 0; int countSell = 0; int countBuyStop = 0; int countSellLimit = 0; int countBuyLimit = 0; int countSellStop = 0;
   SumLotsBuy = 0; SumLotsSell = 0;
   BSPsumlots = 0; SSPsumlots = 0;
   BuyOrdersCurrentPrice = 0; SellOrdersCurrentPrice = 0;
   OrdersCount = 0;
   for (int i=0; i<OrdersTotal(); i++)
     {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) continue;
      if (OrderMagicNumber() != IdNum) continue;
      if (OrderSymbol() != Symbol()) continue;
      // if (StringFind(OrderComment(), CommentOrder, 0) == -1) continue;
      switch(OrderType()) {
      case OP_BUY:
        countBuy++;
        SumLotsBuy  = SumLotsBuy  + OrderLots();
        buyMassive[TICKET][countBuy] = OrderTicket();
        buyMassive[PRICE][countBuy] = OrderOpenPrice();
        buyMassive[LOTS][countBuy] = OrderLots();
        if (OrderOpenPrice() == BP) {BSPsumlots = BSPsumlots + OrderLots(); BuyOrdersCurrentPrice++;}
        break;
      case OP_SELL:
        countSell++;
        SumLotsSell = SumLotsSell + OrderLots();
        buyMassive[TICKET][countSell] = OrderTicket();
        buyMassive[PRICE][countSell] = OrderOpenPrice();
        buyMassive[LOTS][countSell] = OrderLots();
        if (OrderOpenPrice() == SP) {SSPsumlots = SSPsumlots + OrderLots(); SellOrdersCurrentPrice++;}
        break;
      case OP_BUYSTOP:
        countBuyStop++;
        break;
      case OP_SELLLIMIT:
        countSellLimit++;
        break;
      case OP_BUYLIMIT:
        countBuyLimit++;
        break;
      case OP_SELLSTOP:
        countSellStop++;
        break; }
     }
   OrdersCount = countBuy + countSell + countBuyStop + countSellLimit + countBuyLimit + countSellStop;
   Comment("������� = ", AccountProfit(), " \r\n",
           "������ = ", AccountBalance(), " \r\n",
           "�������� = ", AccountEquity(), " \r\n",
           "��������� �������� = ", AccountFreeMargin(), " \r\n",
           "��������� ����� = ", AccountMargin(), " \r\n",
           "������� ����-��� = ", AccountStopoutLevel(), " \r\n",
           "BUY ���� = ", SumLotsBuy, ", ����� ������� = ", countBuy, ", ������� ��� = ", B_lot, ", ������� BUY = ", BuyOrdersCurrentPrice, ", ������� ����� = ", BSPsumlots, " \r\n",
           "SELL ���� = ", SumLotsSell, ", ����� ������� = ", countSell, ", ������� ��� = ", S_lot, ", ������� SELL = ", SellOrdersCurrentPrice, ", ������� ����� = ", SSPsumlots, " \r\n",
           "BUYSTOP = ", DoubleToStr(SumLotsSell,2), " + ", DoubleToStr(inclot,2), " - (", DoubleToStr(SumLotsBuy,2), " - ", DoubleToStr(B_lot,2), ") = ", SumLotsSell + inclot - (SumLotsBuy - B_lot), " \r\n",
           "SELLSTOP = ", DoubleToStr(SumLotsBuy,2), " + ", DoubleToStr(inclot,2), " - (", DoubleToStr(SumLotsSell,2), " - ", DoubleToStr(S_lot,2), ") = ", SumLotsBuy + inclot - (SumLotsSell - S_lot), " \r\n");
           // SumLotsSell + inclot - (SumLotsBuy - B_lot)
   /*Print("OrdersCount = ", OrdersCount);
   Print("BUY = ", countBuy, ", SELL = ", countSell);
   Print("BUYSTOP = ", countBuyStop, ", SELLLIMIT = ", countSellLimit);
   Print("BUYLIMIT = ", countBuyLimit, ", SELLSTOP = ", countSellStop);
   Print("����� �����: BUY = ", SumLotsBuy, ", SELL = ", SumLotsSell); */
  }


void SetLockers()
  {
   Print("����������� ������� SetLockers");
   // Price stop & limit orders
   BSP = BP + distance; // 1 BuyStop   price
   SLP = SP + distance; // 2 SellLimit price
   BLP = BP - distance; // 3 BuyLimit  price 
   SSP = SP - distance; // 4 SellStop  price
   // TakeProfit stop & limit orders
   BSTP = BSP+TP; // 1 BuyStop   takeprofit
   SLTP = SLP-TP; // 2 SellLimit takeprofit
   BLTP = BLP+TP; // 3 BuyLimit  takeprofit 
   SSTP = SSP-TP; // 4 SellStop  takeprofit
   // lots stop & limit orders
   /*
   BSlot = SumLotsSell + multiout*inclot - (SumLotsBuy - B_lot);  // 1 BuyStop   lot
   if (BSlot <= 0) BSlot = 0.01;
   SLlot = multiin*inclot;                                            // 2 SellLimit lot
   BLlot = multiin*inclot;                                            // 3 BuyLimit  lot
   SSlot = SumLotsBuy + multiout*inclot - (SumLotsSell - S_lot);  // 4 SellStop  lot
   if (SSlot <= 0) SSlot = 0.01;
   */
   
   BSlot = SumLotsSell + inclot;               // 1 BuyStop   lot
   SLlot = inclot; // 2 SellLimit lot
   BLlot = inclot;  // 3 BuyLimit  lot
   SSlot = SumLotsBuy + inclot;               // 4 SellStop  lot

   // buystop order
   Print("BUYSTOP: ", "���� ���=", BSP, ", ���� ��=", BSTP, ", �� ������ =", pipsTP, ", ����� = ", BSlot, ", ��������� = ", distance);
   BSticket = OrderSend(Symbol(),OP_BUYSTOP,BSlot,BSP,1,0,BSTP,CommentOrder,IdNum,0,CLR_NONE);
   // selllimit order
   Print("SELLLIMIT: ", "���� ���=", SLP, ", ���� ��=", SLTP, ", �� ������ =", pipsTP, ", ����� = ", SLlot, ", ��������� = ", distance);
   SLticket = OrderSend(Symbol(),OP_SELLLIMIT,SLlot,SLP,1,0,SLTP,CommentOrder,IdNum,0,CLR_NONE);
   // buylimit order
   Print("BUYLIMIT: ", "���� ���=", BLP, ", ���� ��=", BLTP, ", �� ������ =", pipsTP, ", ����� = ", BLlot, ", ��������� = ", distance);
   BLticket = OrderSend(Symbol(),OP_BUYLIMIT,BLlot,BLP,1,0,BLTP,CommentOrder,IdNum,0,CLR_NONE);
   // sellstop order
   Print("SELLSTOP: ", "���� ���=", SSP, ", ���� ��=", SSTP, ", �� ������ =", pipsTP, ", ����� = ", SSlot, ", ��������� = ", distance);
   SSticket = OrderSend(Symbol(),OP_SELLSTOP,SSlot,SSP,1,0,SSTP,CommentOrder,IdNum,0,CLR_NONE);
   Print("������� SetLockers ���������");
  }


void InitOrdersSet()
  {
   Print("����������� ������� InitOrdersSet");
   RefreshRates();
   // Price all orders   
   BP  = Ask;
   SP  = Bid;
   BSP = BP + distance; // 1 BuyStop   price
   SLP = SP + distance; // 2 SellLimit price
   BLP = BP - distance; // 3 BuyLimit  price 
   SSP = SP - distance; // 4 SellStop  price
   // TakeProfit all orders
   BTP  = BP+TP;
   STP  = SP-TP;
   BSTP = BSP+TP; // 1 BuyStop   takeprofit
   SLTP = SLP-TP; // 2 SellLimit takeprofit
   BLTP = BLP+TP; // 3 BuyLimit  takeprofit 
   SSTP = SSP-TP; // 4 SellStop  takeprofit
   // lots stop & limit orders
   B_lot = firstlot;
   S_lot = firstlot;
   BSlot = firstlot + inclot;            // 1 BuyStop   lot
   SLlot = inclot; // 2 SellLimit lot
   BLlot = inclot; // 3 BuyLimit  lot
   SSlot = firstlot + inclot;            // 4 SellStop  lot
   // buy order
   Print("inclot = ", inclot, ", BSlot = ", BSlot, ", SLlot = ", SLlot, ", BLlot = ", BLlot, ", SSlot = ", SSlot);
   Print("BUY:       ", "���� ���=", BP, ", ���� ��=", BP+TP, ", �� ������ =", pipsTP, ", ����� = ", firstlot, ", ��������� = ", distance);
   Bticket  = OrderSend(Symbol(),OP_BUY,B_lot,BP,1,0,BP+TP,CommentOrder,IdNum,0,Blue);
   // sell order
   Print("SELL:      ", "���� ���=", SP, ", ���� ��=", SP-TP, ", �� ������ =", pipsTP, ", ����� = ", firstlot, ", ��������� = ", distance);
   Sticket  = OrderSend(Symbol(),OP_SELL,S_lot,SP,1,0,SP-TP,CommentOrder,IdNum,0,Red);
   // buystop order
   Print("BUYSTOP:   ", "���� ���=", BSP, ", ���� ��=", BSP+TP, ", �� ������ =", pipsTP, ", ����� = ", BSlot, ", ��������� = ", distance);
   BSticket = OrderSend(Symbol(),OP_BUYSTOP,BSlot,BSP,1,0,BSP+TP,CommentOrder,IdNum,0,CLR_NONE);
   // selllimit order
   Print("SELLLIMIT: ", "���� ���=", SLP, ", ���� ��=", SLP-TP, ", �� ������ =", pipsTP, ", ����� = ", SLlot, ", ��������� = ", distance);
   SLticket = OrderSend(Symbol(),OP_SELLLIMIT,SLlot,SLP,1,0,SLP-TP,CommentOrder,IdNum,0,CLR_NONE);
   // buylimit order
   Print("BUYLIMIT:  ", "���� ���=", BLP, ", ���� ��=", BLP+TP, ", �� ������ =", pipsTP, ", ����� = ", BLlot, ", ��������� = ", distance);
   BLticket = OrderSend(Symbol(),OP_BUYLIMIT,BLlot,BLP,1,0,BLP+TP,CommentOrder,IdNum,0,CLR_NONE);
   // sellstop order
   Print("SELLSTOP:  ", "���� ���=", SSP, ", ���� ��=", SSP-TP, ", �� ������ =", pipsTP, ", ����� = ", SSlot, ", ��������� = ", distance);
   SSticket = OrderSend(Symbol(),OP_SELLSTOP,SSlot,SSP,1,0,SSP-TP,CommentOrder,IdNum,0,CLR_NONE);
   Print("������� InitOrdersSet ���������");
  }

