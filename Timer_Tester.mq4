//+------------------------------------------------------------------+
//|                                                 Timer_Tester.mq4 |
//|                                           Copyright 2016, GlobuX |
//|                                              http://globux.ya.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, GlobuX"
#property link      "http://globux.ya.ru"
#property version   "1.00"
#property strict

extern uint pause1 = 5; // Пауза, (сек)
extern uint pause2 = 15; // Пауза, (сек)

class CanWork { //класс пользовательских таймеров
//Конструктор принимает параметр задержки в секундах
//Метод set принимает параметр задержки в секундах
//Метод doWork возвращает результат bool, true - если указанный период прошел, false - если не прошел.
public:
   uint timerStart;
   uint waitPeriod;
// Конструктор CanWork принимает параметр uint Время_в_секундах
   void CanWork(uint timer) {
      timerStart = 0;
      waitPeriod = timer * 1000; 
   }
// Метод (сеттер) set принимает параметр uint Время_в_секундах 
   void set(uint timer) {
      waitPeriod = timer * 1000;
   }
// Метод doWork возвращает результат bool   
   bool doWork() {
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

//+------------------------------------------------------------------+
//| Создание глобальных экземпляров обектов                                     |
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
   if (timer1.doWork()==true) {Print("Сработал таймер №1");}
   if (timer2.doWork()==true) {Print("Сработал таймер №2");}
   //Print("Тестовый ордер EURJPY открыт");
}
//+------------------------------------------------------------------+
