//+------------------------------------------------------------------+
//|                                                DepoPushAlert.mq4 |
//|                                           Copyright 2016, GlobuX |
//|                                              http://globux.ya.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, GlobuX"
#property link      "http://globux.ya.ru"
#property version   "1.00"
#property strict

    extern double DepoHi = 5000; //Верхний порог Депо
    extern double DepoLo = 4800; //Нижний порог Депо
    extern ushort RepeatTime = 2; //Период повтора (минуты)
    extern ushort MinRepeatTime = 1; //Миним. период повт. (ошибка отправки)
    uint PrevTime, CurrentTime, minPrevTime;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   string Text;
   PrevTime = 0;
   minPrevTime = 0;
   if (MinRepeatTime < 1) {
      MinRepeatTime = 1;
   }
   if (MinRepeatTime > RepeatTime) {
      RepeatTime = MinRepeatTime;
   }
   Text = "Тестовое сообщение, начата работа советника. СРЕДСТВА: " + DoubleToString(AccountEquity(), 2) + ", Время: " + (string) TimeCurrent() +
            ", Прибыль: " + DoubleToString(AccountProfit(), 2) + ", Баланс: " + DoubleToString(AccountBalance(), 2) +
            ", Свободная маржа: " + DoubleToString(AccountFreeMargin(), 2) + ", Маржа: " + DoubleToString(AccountMargin(), 2);
   SendNotification(Text);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   string Text;
   Text = "Этот советник ЗАВЕРШИЛ работу, больше сообшений не будет. СРЕДСТВА: " + DoubleToString(AccountEquity(), 2) + ", Время: " + (string) TimeCurrent() +
            ", Прибыль: " + DoubleToString(AccountProfit(), 2) + ", Баланс: " + DoubleToString(AccountBalance(), 2) +
            ", Свободная маржа: " + DoubleToString(AccountFreeMargin(), 2) + ", Маржа: " + DoubleToString(AccountMargin(), 2);
   SendNotification(Text);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   uint deltaTime, minDeltaTime;
   string Text;
   CurrentTime = GetTickCount();
   deltaTime = CurrentTime - PrevTime;
   minDeltaTime = CurrentTime - minPrevTime;
   //Print("Произошел ТИК, Delta: ", deltaTime, ", MinDelta: ", minDeltaTime);
   if (((DepoHi <= AccountEquity()) || (DepoLo >= AccountEquity())) && (deltaTime > (uint) RepeatTime*60000)) {
      //Print(deltaTime);
      //Print(TimeCurrent());
      Print("Достигнут минимум/максимум, и указанная пауза прошла, Delta: ", deltaTime, ", MinDelta: ", minDeltaTime);
      if (minDeltaTime > (uint) MinRepeatTime*60000) {
         Text = "СРЕДСТВА: " + DoubleToString(AccountEquity(), 2) + ", Время: " + (string) TimeCurrent() +
            ", Прибыль: " + DoubleToString(AccountProfit(), 2) + ", Баланс: " + DoubleToString(AccountBalance(), 2) +
            ", Свободная маржа: " + DoubleToString(AccountFreeMargin(), 2) + ", Маржа: " + DoubleToString(AccountMargin(), 2);
            //Print("Минимальная пауза выдержана, Delta: ", deltaTime, ", MinDelta: ", minDeltaTime);
         if (SendNotification(Text) == true) {
            PrevTime = CurrentTime;
            minPrevTime = CurrentTime;
            Print("Отправили сообщение, Delta: ", deltaTime, ", MinDelta: ", minDeltaTime);
         }
         else {
            minPrevTime = CurrentTime;
            Print("НЕ ОТПРАВЛЕНО, минимальная пауза не прошла, Delta: ", deltaTime, ", MinDelta: ", minDeltaTime);
         }
      }
   }
   
/*   if (deltaTime > (uint) MinRepeatTime*60000) {
      PrevTime = CurrentTime;
      Print(deltaTime);
      Print(TimeCurrent());
      }
  Print("AccountBalance: ", AccountBalance(), ", AccountEquity: ", AccountEquity());
  Print("AccountFreeMargin: ", AccountFreeMargin(), ", AccountMargin: ", AccountMargin());
  Print("AccountProfit: ", AccountProfit(), ", AccountCredit: ", AccountCredit());
  Print(" ");*/
  }
//+------------------------------------------------------------------+
