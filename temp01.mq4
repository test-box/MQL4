//+------------------------------------------------------------------+
//|                                                       temp01.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
  }
//+------------------------------------------------------------------+




// ����� Report, ���������� true ���� ���� ��������� � �������� �������, ����� false
   bool Report() {  // ����� ��� 
      int size = ArrayRange(arrCurBuyOrd,0);  //������ �������
      bool modifedOrders = false;   // ���� ��������� ���������� �������
      string Header = ">" + (string) lotAlert + ": ";
      Message = "";
      string NewEvent = "";
      string Body = "";
      string Booter = " " + (string) TimeCurrent();
      for (int i = 0; i < size; i++) {
         if (arrCurBuyOrd[i][1] != arrPreBuyOrd[i][1] && arrCurBuyOrd[i][1] == "") {
			   NewEvent = NewEvent + "!New[" + arrCurBuyOrd[i][0] + "-BUY:CLOSED!] ";
            isExistActiveOrders = true;
         }
         if (arrCurSelOrd[i][1] != arrPreSelOrd[i][1] && arrCurSelOrd[i][1] == "") {
            isChangeOrders = true;
			   NewEvent = NewEvent + "!New[" + arrCurSelOrd[i][0] + "-SELL:CLOSED!] ";
            isExistActiveOrders = true;
         }
         if (symbolMaxLotBuy[i] >= lotAlert) { 
            if (arrCurBuyOrd[i][1] != arrPreBuyOrd[i][1]) {
               Print("������: ", arrCurBuyOrd[i][0], ", ������� ������� BUY:", arrCurBuyOrd[i][1], ", ���������� ��������� BUY:", arrPreBuyOrd[i][1]);
               modifedOrders = true; // ���� ��������� � �������� ��������
               isChangeOrders = true;
               NewEvent = NewEvent + "!New[" + arrCurBuyOrd[i][0] + " BUY: ...+" + arrCurBuyOrd[i][4] + "+" + arrCurBuyOrd[i][5]
                              + "+" + arrCurBuyOrd[i][6] + "=" + arrCurBuyOrd[i][3] + " " + arrCurBuyOrd[i][1] + "("
                              + arrCurBuyOrd[i][2] + ")]* ";
            } else {
               Body = Body + " " + arrCurBuyOrd[i][0] + " BUY: ...+" + arrCurBuyOrd[i][4] + "+" + arrCurBuyOrd[i][5]
                              + "+" + arrCurBuyOrd[i][6] + "=" + arrCurBuyOrd[i][3] + " " + arrCurBuyOrd[i][1] + "("
                              + arrCurBuyOrd[i][2] + ");";
            }
         }
         if (symbolMaxLotSell[i] >= lotAlert) {
            if (arrCurSelOrd[i][1] != arrPreSelOrd[i][1]) {
               Print("������: ", arrCurSelOrd[i][0], ", ������� ������� SELL:", arrCurSelOrd[i][1], ", ���������� ��������� SELL:", arrPreSelOrd[i][1]);
               modifedOrders = true; // ���� ��������� � �������� ��������
			      isChangeOrders = true;
               NewEvent = NewEvent + "!New[" + arrCurSelOrd[i][0] + " SELL: ...+" + arrCurSelOrd[i][4] + "+" + arrCurSelOrd[i][5]
                              + "+" + arrCurSelOrd[i][6] + "=" + arrCurSelOrd[i][3] + " " + arrCurSelOrd[i][1] + "("
                              + arrCurBuyOrd[i][2] + ")] ";
            } else {
               Body = Body + " " + arrCurSelOrd[i][0] + " SELL: ...+" + arrCurSelOrd[i][4] + "+" + arrCurSelOrd[i][5]
                              + "+" + arrCurSelOrd[i][6] + "=" + arrCurSelOrd[i][3] + " " + arrCurSelOrd[i][1] + "("
                              + arrCurSelOrd[i][2] + ");";
            }
         }
      }
      if (isExistActiveOrders == true) {
         if (modifedOrders == true) {
            Message = Header + NewEvent + Body + Booter;
            //PlaySound("C:\\Windows\\Media\\Alarm06.wav"); Alert(Message);
            //Print("���� ������� - ����� ����� > ", lotAlert, " ", modifedOrders);
            //Print(Message); 
         }
      } else {
         Message = Header + NewEvent + Body + Booter;
         //PlaySound("C:\\Windows\\Media\\Alarm06.wav"); Alert(Message);
         //Print("������� - ������, ����� ��� > ", lotAlert);
         //Print(Message); 
      }
      return(modifedOrders);
   } //����� ������ Report
   
   
   
   
   
         double lot = 0;
   // ���������� �������� ������� �� ���� (Buy/Sell)
      int numBuyOrders;
      int numSellOrders;
   // ���������� ������� � ������ > Lot_Alert �� ���� (Buy/Sell)
      int numBigBuyOrders;
      int numBigSellOrders;
   // ����� ����� �������� ������� �� ���� (Buy/Sell)
      double volumeBuy; 
      double volumeSell;
   // ����� ������ � ���������� ������� �� ���� (Buy/Sell)
      double mostBuyOrder;
      double MaxLotSell; // ����� ������ � ���������� �������









      string Header = ">" + (string) lotAlert + ": ";
      string NewEvent = "";
      string Body = "";
      string Booter = " " + (string) TimeCurrent();
      for (int i = 0; i < size; i++) {
         if (arrCurrNumBuyOrders[i][1] != arrPreBuyOrd[i][1] && arrCurrNumBuyOrders[i][1] == "") {
            isChangeOrders = true;
			   NewEvent = NewEvent + "!New[" + arrCurBuyOrd[i][0] + "-BUY:CLOSED!] ";
            isExistActiveOrders = true;
         }
         if (arrCurSelOrd[i][1] != arrPreSelOrd[i][1] && arrCurSelOrd[i][1] == "") {
            isChangeOrders = true;
			   NewEvent = NewEvent + "!New[" + arrCurSelOrd[i][0] + "-SELL:CLOSED!] ";
            isExistActiveOrders = true;
         }
         if (symbolMaxLotBuy[i] >= lotAlert) { 
            if (arrCurBuyOrd[i][1] != arrPreBuyOrd[i][1]) {
               Print("������: ", arrCurBuyOrd[i][0], ", ������� ������� BUY:", arrCurBuyOrd[i][1], ", ���������� ��������� BUY:", arrPreBuyOrd[i][1]);
               modifedOrders = true; // ���� ��������� � �������� ��������
               isChangeOrders = true;
               NewEvent = NewEvent + "!New[" + arrCurBuyOrd[i][0] + " BUY: ...+" + arrCurBuyOrd[i][4] + "+" + arrCurBuyOrd[i][5]
                              + "+" + arrCurBuyOrd[i][6] + "=" + arrCurBuyOrd[i][3] + " " + arrCurBuyOrd[i][1] + "("
                              + arrCurBuyOrd[i][2] + ")]* ";
            } else {
               Body = Body + " " + arrCurBuyOrd[i][0] + " BUY: ...+" + arrCurBuyOrd[i][4] + "+" + arrCurBuyOrd[i][5]
                              + "+" + arrCurBuyOrd[i][6] + "=" + arrCurBuyOrd[i][3] + " " + arrCurBuyOrd[i][1] + "("
                              + arrCurBuyOrd[i][2] + ");";
            }
         }
         if (symbolMaxLotSell[i] >= lotAlert) {
            if (arrCurSelOrd[i][1] != arrPreSelOrd[i][1]) {
               Print("������: ", arrCurSelOrd[i][0], ", ������� ������� SELL:", arrCurSelOrd[i][1], ", ���������� ��������� SELL:", arrPreSelOrd[i][1]);
               modifedOrders = true; // ���� ��������� � �������� ��������
			      isChangeOrders = true;
               NewEvent = NewEvent + "!New[" + arrCurSelOrd[i][0] + " SELL: ...+" + arrCurSelOrd[i][4] + "+" + arrCurSelOrd[i][5]
                              + "+" + arrCurSelOrd[i][6] + "=" + arrCurSelOrd[i][3] + " " + arrCurSelOrd[i][1] + "("
                              + arrCurBuyOrd[i][2] + ")] ";
            } else {
               Body = Body + " " + arrCurSelOrd[i][0] + " SELL: ...+" + arrCurSelOrd[i][4] + "+" + arrCurSelOrd[i][5]
                              + "+" + arrCurSelOrd[i][6] + "=" + arrCurSelOrd[i][3] + " " + arrCurSelOrd[i][1] + "("
                              + arrCurSelOrd[i][2] + ");";
            }
         }
      }
      if (isExistActiveOrders == true) {
         if (modifedOrders == true) {
            Message = Header + NewEvent + Body + Booter;
            //PlaySound("C:\\Windows\\Media\\Alarm06.wav"); Alert(Message);
            //Print("���� ������� - ����� ����� > ", lotAlert, " ", modifedOrders);
            //Print(Message); 
         }
      } else {
         Message = Header + NewEvent + Body + Booter;
         //PlaySound("C:\\Windows\\Media\\Alarm06.wav"); Alert(Message);
         //Print("������� - ������, ����� ��� > ", lotAlert);
         //Print(Message); 
      }
      return(modifedOrders);