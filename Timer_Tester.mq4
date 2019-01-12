//+------------------------------------------------------------------+
//|                                                 Timer_Tester.mq4 |
//|                                           Copyright 2016, GlobuX |
//|                                              http://globux.ya.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, GlobuX"
#property link      "http://globux.ya.ru"
#property version   "1.00"
#property strict

extern uint pause1 = 5; // �����, (���)
extern uint pause2 = 15; // �����, (���)

class CanWork { //����� ���������������� ��������
//����������� ��������� �������� �������� � ��������
//����� set ��������� �������� �������� � ��������
//����� doWork ���������� ��������� bool, true - ���� ��������� ������ ������, false - ���� �� ������.
public:
   uint timerStart;
   uint waitPeriod;
// ����������� CanWork ��������� �������� uint �����_�_��������
   void CanWork(uint timer) {
      timerStart = 0;
      waitPeriod = timer * 1000; 
   }
// ����� (������) set ��������� �������� uint �����_�_�������� 
   void set(uint timer) {
      waitPeriod = timer * 1000;
   }
// ����� doWork ���������� ��������� bool   
   bool doWork() {
      uint timerCurrent = GetTickCount();
      uint timerDelta = timerCurrent - timerStart;
      //Print("������� �����: ", timerCurrent, ", ���������� �����: ", timerStart, ", �������: ", timerDelta, ", ����������� �����: ", waitPeriod);
      if (timerDelta >= waitPeriod) {
         timerStart = timerCurrent;
         return (true);
      }
      return (false);
   }
};

//+------------------------------------------------------------------+
//| �������� ���������� ����������� �������                                     |
//+------------------------------------------------------------------+
CanWork* timer1 = new CanWork(pause1);
CanWork* timer2 = new CanWork(pause2);

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   EventSetTimer(3);
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   EventKillTimer();
   delete timer1;
   delete timer2;
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){
   
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
   Print("tick! :)");
   if (timer1.doWork()==true) {Print("�������� ������ �1");}
   if (timer2.doWork()==true) {Print("�������� ������ �2");}
   //Print("�������� ����� EURJPY ������");
}
//+------------------------------------------------------------------+
