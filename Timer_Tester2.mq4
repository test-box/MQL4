//+------------------------------------------------------------------+
//|                                                 Timer_Tester.mq4 |
//|                                           Copyright 2016, GlobuX |
//|                                              http://globux.ya.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, GlobuX"
#property link      "http://globux.ya.ru"
#property version   "1.00"
#property strict

extern uint srtPause = 3;  // �����, (���)
extern uint lngPause = 60;  // �����, (���)
extern uint numRepeats = 10; // ���������� �������� �� ������� �����

class UserTimer { //����� ���������������� ��������
//����������� ��������� �������� �������� � ��������
//����� set ��������� �������� �������� � ��������
//����� timeToWork ���������� ��������� bool, true - ���� ��������� ������ ������, false - ���� �� ������.
public:
   uint timerStart;
   uint waitPeriod;
// ����������� UserTimer ��������� �������� uint �����_�_��������
   void UserTimer(uint timer) {
      timerStart = 0;
      waitPeriod = timer * 1000; 
   }
// ����� (������) set ��������� �������� uint �����_�_�������� 
   void set(uint timer) {
      waitPeriod = timer * 1000;
   }
// ����� timeToWork ���������� ��������� bool   
   bool timeToWork() {
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


// ����� UserTwixTimer
class UserTwixTimer {
public:
	uint numRepeat;
	uint timer1Wait;
	uint timer2Wait;
	uint currPos;
   uint arrEvent[];
// ����������� ������ UserDoubleTimer
	void UserTwixTimer(uint shortT, uint longT, uint repeat) {
		timer1Wait = shortT * 1000;
		timer2Wait = longT * 1000;
		numRepeat = repeat;
		currPos = 0;
		ArrayResize(arrEvent,numRepeat);
	}
// ����� timeToWork ����������������� ������������� �� �������
   bool timeToWork() {
      bool result = false;
      uint oldest;
      uint currentTime = GetTickCount();
      if (currPos >= numRepeat-1) {oldest = 0;} else {oldest = currPos + 1;}
      uint deltaShort = currentTime - arrEvent[currPos];
      uint deltaLong = currentTime - arrEvent[oldest];
      //Print("�������� �����: ", deltaShort, ", ������� �����: ", deltaLong);
      if (deltaLong >= timer2Wait && deltaShort >= timer1Wait) {
         currPos++;
         if (currPos == numRepeat) {currPos = 0;}
         arrEvent[currPos] = currentTime;
         result = true;
      }
      return(result);
   }
// ����� (������) set ��������� �������� uint �����_�_�������� 
   void set(uint shortT, uint longT) {
      timer1Wait = shortT * 1000;
      timer2Wait = longT * 1000;
   }
};


//+------------------------------------------------------------------+
//| �������� ���������� ����������� �������                                     |
//+------------------------------------------------------------------+
UserTwixTimer* twixTimer = new UserTwixTimer(srtPause, lngPause, numRepeats);


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   EventSetTimer(1);
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   EventKillTimer();
   if ( UninitializeReason() != REASON_PARAMETERS) {
      delete twixTimer;
   }
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
   //Print("tick! :)");
   //if (timer1.timeToWork()==true) {Print("�������� ������ �1");}
   //if (timer2.timeToWork()==true) {Print("�������� ������ �2");}
   if (twixTimer.timeToWork() == true) {Print("������ Twix ��������");}
   //Print("�������� ����� EURJPY ������");
}
//+------------------------------------------------------------------+
