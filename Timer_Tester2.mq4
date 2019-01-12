//+------------------------------------------------------------------+
//|                                                 Timer_Tester.mq4 |
//|                                           Copyright 2016, GlobuX |
//|                                              http://globux.ya.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, GlobuX"
#property link      "http://globux.ya.ru"
#property version   "1.00"
#property strict

extern uint srtPause = 3;  // Пауза, (сек)
extern uint lngPause = 60;  // Пауза, (сек)
extern uint numRepeats = 10; // Количество повторов до длинной паузы

class UserTimer { //класс пользовательских таймеров
//Конструктор принимает параметр задержки в секундах
//Метод set принимает параметр задержки в секундах
//Метод timeToWork возвращает результат bool, true - если указанный период прошел, false - если не прошел.
public:
   uint timerStart;
   uint waitPeriod;
// Конструктор UserTimer принимает параметр uint Время_в_секундах
   void UserTimer(uint timer) {
      timerStart = 0;
      waitPeriod = timer * 1000; 
   }
// Метод (сеттер) set принимает параметр uint Время_в_секундах 
   void set(uint timer) {
      waitPeriod = timer * 1000;
   }
// Метод timeToWork возвращает результат bool   
   bool timeToWork() {
      uint timerCurrent = GetTickCount();
      uint timerDelta = timerCurrent - timerStart;
      //Print("Текущее время: ", timerCurrent, ", предыдущее время: ", timerStart, ", разница: ", timerDelta, ", контрольное время: ", waitPeriod);
      if (timerDelta >= waitPeriod) {
         timerStart = timerCurrent;
         return (true);
      }
      return (false);
   }
};


// Класс UserTwixTimer
class UserTwixTimer {
public:
	uint numRepeat;
	uint timer1Wait;
	uint timer2Wait;
	uint currPos;
   uint arrEvent[];
// Конструктор класса UserDoubleTimer
	void UserTwixTimer(uint shortT, uint longT, uint repeat) {
		timer1Wait = shortT * 1000;
		timer2Wait = longT * 1000;
		numRepeat = repeat;
		currPos = 0;
		ArrayResize(arrEvent,numRepeat);
	}
// Метод timeToWork дифференциального распределения по времени
   bool timeToWork() {
      bool result = false;
      uint oldest;
      uint currentTime = GetTickCount();
      if (currPos >= numRepeat-1) {oldest = 0;} else {oldest = currPos + 1;}
      uint deltaShort = currentTime - arrEvent[currPos];
      uint deltaLong = currentTime - arrEvent[oldest];
      //Print("Короткая пауза: ", deltaShort, ", Длинная пауза: ", deltaLong);
      if (deltaLong >= timer2Wait && deltaShort >= timer1Wait) {
         currPos++;
         if (currPos == numRepeat) {currPos = 0;}
         arrEvent[currPos] = currentTime;
         result = true;
      }
      return(result);
   }
// Метод (сеттер) set принимает параметр uint Время_в_секундах 
   void set(uint shortT, uint longT) {
      timer1Wait = shortT * 1000;
      timer2Wait = longT * 1000;
   }
};


//+------------------------------------------------------------------+
//| Создание глобальных экземпляров обектов                                     |
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
   //if (timer1.timeToWork()==true) {Print("Сработал таймер №1");}
   //if (timer2.timeToWork()==true) {Print("Сработал таймер №2");}
   if (twixTimer.timeToWork() == true) {Print("Таймер Twix сработал");}
   //Print("Тестовый ордер EURJPY открыт");
}
//+------------------------------------------------------------------+
