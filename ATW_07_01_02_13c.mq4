//+------------------------------------------------------------------+
//|                                                    ATW_07_00.mq4 |
//|                                         Copyright © 2012, GlobuX |
//|                                                 globuq@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2012, GlobuX"
#property link      "globuq@gmail.com"
#include <stderror.mqh>

//---------Переменные-параметры-эксперта---------//
extern bool    Trade = true;            // продолжать торговлю или нет после закрытия всех сделок
extern int     correctTP = 26;          // корректировка ТЕЙКПРОФИТА
extern int     correctDistance = 12;    // корректировка ДИСТАНЦИИ
extern bool    AutoLot = true;          // автоматический расчет лотов, если TRUE
extern double  minLot = 0.01;           // минимальный лот, который допускает брокер
extern double  firstlot = 0.07;         // количестов лотов для первого ордера в расчете на DEPOSIT
extern double  deposit = 1000;          // DEPOSIT для расчета лотов первого ордера
extern int     maxQOrders = 7;          // максимальное количество установленных ордеров
extern int     PeriodMV = 10;           // Период для расчета дистанции между ордерами
extern int     ManualTP = 0;            // Жесткий не регулируемый ТЕЙКПРОФИТ, если не 0, то будет установлен он.
extern double  DefaultLots = 0.05;      // количество лотов для первого ордера, если не установлен АВТОЛОТ
extern bool    calcLastWeek = false;    // подсчет ДИСТАНЦИИ по периоду PeriodMV не включая текущую неделю, если TRUE
extern int     IdNum = 700;             // идентификатор советника, необходим для распознования советником своих ордеров
extern string  CommentOrder = "ATW_v7.0";   // комментарий к устанавливаемым ордерам, для визуального опознования ордеров советника
extern bool    enable_min_distance = false; // задействовать минимальную дистанцию, если TRUE
extern int     minDistance = 50;        // минимальная дистанция между ордерами, возможно отключить
extern int     SafeDistance = 50;       // минимальная дистанция между ордерами, НЕЛЬЗЯ отключить.

//--------Глобальные переменные терминала----------//
double Distance;
string dist_GV;
int    LastOrderTicket;
string lastticket_GV;

//--------Глобальные переменные эксперта----------//
int    calcDay;
double MedianATW;
double TP;
double CurrentTP;
double calcTP;  //Берется с уже установленных ордеров 
int    ticket;
int    tickets[50];
int    quantityOrders;
double Lots;
double LastLots;
int    nextOrder=6;
double POINT;
bool mess_printed = false;



//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
   Print("Советник: ATWv07, инициализация. ", "IdNum: ", IdNum, ", CommentOrder: ", CommentOrder);
   if (Point < 0.0001) POINT = Point*10;
   else POINT = Point;
   ArrayInitialize(tickets,0);
   dist_GV="ATW_"+Symbol()+"_dist";  //Устанавливаем название глобальной переменной (Distance)
   Print("dist_GV=", dist_GV);
   if (GlobalVariableCheck(dist_GV))
     {
      Distance = GlobalVariableGet(dist_GV);
      Print("Предыдущие настройки: дистанция между ордерами: ", Distance);
     }
   lastticket_GV="ATW_"+Symbol()+"_lastticket";  //Устанавливаем название глобальной переменной (lastticket)
   Print("lastticket_GV=", lastticket_GV);
   if (GlobalVariableCheck(lastticket_GV))
     {
      LastOrderTicket = GlobalVariableGet(lastticket_GV);
      Print("Предыдущие настройки: тикет последнего ордера: ", LastOrderTicket);
     }
   FindOrders(); //Поиск существующих ордеров
  }

//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+ 
/*
int deinit()
  {
   return(0);
  } */

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
   if (ExistHistory() == false) return; 
   if (TimeDay(TimeCurrent())!= calcDay) {calcDistance();} //если наступил следующий день, пересчитываем ТейкПрофит.
   if (quantityOrders==0) {SetFirstOrder(); return(0);} //Если нет установленных ордеров, устанавливаем первый.
   if (LastOrderClosed()==true) {ClosedAllOrders(); return(0);} //Если крайний ордер закрыт, то закрываем остальные ордера.
   if (AllowSetNextOrder()==true) SetNextOrder(); //Если условия позвояют устанавливаем следующий ордер с удвоеенным лотом.
  }


//+------------------------------------------------------------------+


bool ExistHistory()
  {
   if (iBars(NULL,PERIOD_D1) == 0 || GetLastError() == 4066)
     {
      Print("Загружается история...");
      Sleep(15000);
      RefreshRates();
      return(false);
     }
   else return(true);
  }

void SaveLastOrderTicket(int ticket)
  {
   if (GlobalVariableSet(lastticket_GV, ticket) == 0)
     {
      Print("При установке глобальной переменной lastticket_GV возникла ошибка");
      Print("Ошибка #", GetLastError());
     }
  }

void FindOrders()
  {
   double absTP = 0;
   double preTime = 0;
   quantityOrders = 0;
   Lots = 0;
   ArrayInitialize(tickets,0);
   for (int i=0; i<OrdersTotal(); i++)
     {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) continue;
      if (OrderMagicNumber() != IdNum) continue;
      if (OrderSymbol() != Symbol()) continue;
      // if (StringFind(OrderComment(), CommentOrder, 0) == -1) continue;
      tickets[quantityOrders] = OrderTicket();
      quantityOrders++;
      if (OrderOpenTime() > preTime)
        {
         preTime = OrderOpenTime();
         int LastTicket = OrderTicket();
         CurrentTP = MathAbs(OrderOpenPrice()-OrderTakeProfit());
         absTP = OrderTakeProfit();
         Lots = OrderLots();
        }
     }
   Print("Найдено ордеров:", quantityOrders, "; последний ордер: лоты=", Lots, ", тикет=", LastTicket, ", относительный ТП=", CurrentTP, ", абсолютный ТП=", absTP);
  }


bool DetectSettedNewOrder()
  {
   Print("# Функция поиска неучтенных ордеров #");
   double preTime = 0;
   int orders = 0;
   int LastTicket;
   RefreshRates();
   for (int i=0; i<OrdersTotal(); i++)
     {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) continue;
      if (OrderMagicNumber() != IdNum) continue;
      if (OrderSymbol() != Symbol()) continue;
      // if (StringFind(OrderComment(), CommentOrder, 0) == -1) continue;
      orders++;
      if (OrderOpenTime() > preTime)
        {
         preTime = OrderOpenTime();
         LastTicket = OrderTicket();
        }
     }
   if (orders > quantityOrders && LastTicket != LastOrderTicket)
     {
      Print("Найден новый ордер, тикет=", LastTicket, ", всего ордеров = ", orders, "; ранее было ордеров = ", quantityOrders, ", старый тикет", LastOrderTicket);
      ticket = LastTicket;
      LastOrderTicket = ticket;
      SaveLastOrderTicket(ticket);
      tickets[quantityOrders]=ticket;
      quantityOrders = orders;
      return(true);
     }
   Print("Найдено ордеров = ", orders, ", тикет последнего = ", LastTicket, ", ", LastOrderTicket);
   return(false);
  }


void SetFirstOrder()
  {
   if (Trade == false) return;
   Print("-+Функция установки первого ордера+-");
   Distance = calcTP + correctDistance*POINT;
   if (enable_min_distance == true && Distance < minDistance) Distance = minDistance*POINT; //если минимальная дистанция активна
   if (Distance == 0) Distance = SafeDistance*POINT; //если все же дистанция ноль, то исправляем дистанцию на safedistance
   Print("Дистанция между ордерами установлена: ", Distance);
   //Print("Название глобальной переменной - ", dist_GV);
   if (GlobalVariableSet(dist_GV,Distance) == 0) {Print("При установке глобальной переменной возникла ошибка"); Print("Ошибка #", GetLastError());}
   CurrentTP = Distance + correctTP*POINT;
   if (AutoLot == true) Lots = AccountBalance()/(deposit/firstlot);
   else Lots = DefaultLots;
   if (Lots < minLot) Lots = minLot;
   /* */
   if (nextOrder == OP_BUY) {Print("Отправлен ордер Бай "); SendOrder(OP_BUY); nextOrder = OP_SELL;} 
   else if (nextOrder == OP_SELL) {Print("Отправлен ордер Селл "); SendOrder(OP_SELL); nextOrder = OP_BUY;}
   else /* */ if (iClose(Symbol(),PERIOD_D1,1) > iOpen(Symbol(),PERIOD_D1,1)) {Print("Отправлен ордер Бай "); SendOrder(OP_BUY); nextOrder = OP_SELL;} //Если цена закрытия выше цены открытия предыдущего дня то покупаем BUY
              else {Print("Отправлен ордер Селл "); SendOrder(OP_SELL); nextOrder = OP_BUY;} //Иначе, продаем SELL
   if (GetLastError()==0)
     {
      LastOrderTicket = ticket; //Запоминаем тикет крайнего ордера
      SaveLastOrderTicket(ticket);
      tickets[quantityOrders] = ticket;
      quantityOrders++; //Если ошибок не было, увеличиваем счетчик ордеров на 1.
      Print("Ордер установлен успешно.");
     }
   else {Print("Установка первого ордера - ОШИБКА!"); nextOrder = 6;}
  }


bool LastOrderClosed()
  {
   if (OrderSelect(LastOrderTicket, SELECT_BY_TICKET)==false)
      {Print("-%Функция проверки существования крайнего ордера%- ", "Ошибка при выборе ордера: ", GetLastError()); return(true);}
   if (OrderCloseTime()==0) return(false);
   Print("Крайний ордер был закрыт, тикет # ", LastOrderTicket, ", количество ордеров было: ", quantityOrders);
   quantityOrders--;
   tickets[quantityOrders] = 0;
   return(true);
  }


void ClosedAllOrders()
  {
   Print("-= Функция закрытия всех оставшихся ордеров =-");
   Print("Количество оставшихся ордеров: по вычислениям советника=", quantityOrders, ", по функции (OrdersTotal)=", OrdersTotal());
   int count = 0;
   int k = 0;
   int OrderTicketMassive[30];
   ArrayInitialize(OrderTicketMassive,0);
   for (int t=0; t<OrdersTotal(); t++)  //Цикл поиска ордеров советника, создает массив тикетов
     {
      if (OrderSelect(t, SELECT_BY_POS, MODE_TRADES) == false) {Print("1-я проверка: ошибка, (OrderSelect)"); continue;}
      if (OrderMagicNumber() != IdNum) {Print("2-я проверка: ошибка, (OrderMagicNumber)"); continue;}
      if (OrderSymbol() != Symbol()) {Print("3-я проверка: ошибка, (OrderSymbol)"); continue;}
      count++;
      OrderTicketMassive[count] = OrderTicket();
      Print("Найден ордер: тикет = ", OrderTicket());
     }
   for (int i=1; i <= count; i++)      //Цикл удаления найденных ордеров
     {
      OrderSelect(OrderTicketMassive[i],SELECT_BY_TICKET);
      Print("Ордер: тикет #", OrderTicket(), ", тип ордера=", OrderType(), ", валюта=", OrderSymbol(),
            ", цена открытия=", OrderOpenPrice(), ", уровень ТП=",OrderTakeProfit(), ", объем лотов=", OrderLots(),
            ", idNum=", OrderMagicNumber(), ", комментарий=", OrderComment()); 
      bool err = true;
      while (err == true)
       {
        RefreshRates();
        switch(OrderType())
         {
          case OP_BUY:
            OrderClose(OrderTicket(),OrderLots(),Bid,3,Blue);
            break;   
          case OP_SELL:
            OrderClose(OrderTicket(),OrderLots(),Ask,3,Red);
            break;
         }
        int error = CheckError();
        if (error == 0) {err = false; k++; Print("Удален успешно."); break;}
        if (error == ERR_INVALID_TICKET) break;
        else Sleep(15000);
       }
     }
   Print("Количество удаленных ордеров: ", k);
   ArrayInitialize(tickets,0);
   quantityOrders = 0;
  } 


bool AllowSetNextOrder()
  {
   if (quantityOrders < 1) return(false); // Если ордеров меньше 1, выходим, возвращаем false
   if (OrderSelect(LastOrderTicket,SELECT_BY_TICKET)==false) return(false);
   switch(OrderType())
     {
      case OP_BUY:
        if (OrderOpenPrice()-Distance >= Ask) return(true);
        break;   
      case OP_SELL:
        if (OrderOpenPrice()+Distance <= Bid) return(true);
        break;
     }
   return(false);
  }


void SetNextOrder()
  {
   if (quantityOrders >= maxQOrders) return(2);
   if ((AccountFreeMarginCheck(Symbol(),OrderType(),OrderLots()*2)<=0) || (GetLastError()==134))
     {
      if (mess_printed == false)
        {
         Print("Не достаточно маржи для установки следующего ордера.");
         bool mess_printed = true;
        }
      return(-1); //Не достаточно маржи для установки следующего ордера
     }
   int ototal = OrdersTotal();
   Print("-@Функция установки следующего ордера@-");
   Lots = OrderLots()*2;
   switch(OrderType())
     {
      case OP_BUY:
        Print("Отправлен ордер Бай ");
        SendOrder(OP_BUY);
        nextOrder = OP_SELL;
        break;   
      case OP_SELL:
        Print("Отправлен ордер Селл ");
        SendOrder(OP_SELL);
        nextOrder = OP_BUY;
        break;
     }
   int error = CheckError();
   switch (error)
     {
      case 0: //ERR_NO_ERROR; Нет ошибки
       LastOrderTicket = ticket;
       SaveLastOrderTicket(ticket);
       tickets[quantityOrders]=ticket;
       quantityOrders++;
       Print("Ордер успешно установлен, тикет=", ticket);
       return(0);
      case 1: //ERR_NO_RESULT;  Нет ошибки, но результат неизвестен
       Print("Проверяем установлен ли все-таки ордер");
       RefreshRates();
       if (ototal < OrdersTotal() && DetectSettedNewOrder()==true) return(0);
      default:
       ticket = LastOrderTicket;
       Print("Тикет не изменен.");
       Print("Делаем паузу 15 сек.");
       Sleep(15000);
     }
  }


void SendOrder(int command)
  {
   TP = CurrentTP;
   RefreshRates();
   switch (command)
     {
      case OP_BUY: 
        Print("Ордер Покупки /\: ", "цена аск=", Ask, ", уровень ТП=", Ask+TP, ", относительный ТП=", TP, ", лотов=", Lots, ", distance=", Distance);
        ticket = OrderSend(Symbol(),OP_BUY,Lots,Ask,1,0,Ask+TP,CommentOrder,IdNum,0,Blue); 
        break;
      case OP_SELL: 
        Print("Ордер Продажи \/: ", "цена бид=", Bid, ", уровень ТП=", Bid-TP, ", относительный ТП=", TP, ", лотов=", Lots, ", distance=", Distance);
        ticket = OrderSend(Symbol(),OP_SELL,Lots,Bid,1,0,Bid-TP,CommentOrder,IdNum,0,Red);
        break;
     }
  }


double CalcMV()
  {
   double val;
   val=0;
   for (int i=1;i<PeriodMV+1;i++)
     {
      val=val+iHigh(NULL,PERIOD_D1,i)-iLow(NULL,PERIOD_D1,i);
     }
   val=val/PeriodMV;
   return(val);
  }


double CalcMVLastWeek()
  {
   double val;
   val=0;
   for (int i=TimeDayOfWeek(TimeCurrent());i<PeriodMV+1;i++)
     {
      val=val+iHigh(NULL,PERIOD_D1,i)-iLow(NULL,PERIOD_D1,i);
     }
   val=val/PeriodMV;
   return(val);
  }


double MedATW()
  {
   if (calcLastWeek == true) MedianATW = CalcMVLastWeek();
   else MedianATW = CalcMV(); // Print("MedianATW=", MedianATW);
   return(MedianATW);
  }


double calcDistance()
  {
   calcDay = Day(); //Запоминаем день подсчета.
   if (ManualTP == 0) calcTP = MedATW() / 2;
   else calcTP = ManualTP * POINT;
   Print("Базовая дистанция пересчитана: ", calcTP);
   return(calcTP);
  }


int CheckError()
  {
  int Error = GetLastError();
  switch (Error)
    {
     case ERR_NO_ERROR:
       /*Print("Нет ошибки."); */ break;
     case ERR_NO_RESULT:
       Print("Нет ошибки, но результат неизвестен (параметры не изменены)"); break;
     case ERR_COMMON_ERROR:
       Print("Общая ошибка"); break;
     case ERR_INVALID_TRADE_PARAMETERS:
       Print("Ошибка: Неправильные параметры"); break;
     case ERR_SERVER_BUSY:
       Print("Ошибка: Торговый сервер занят"); break;
     case ERR_OLD_VERSION:
       Print("Ошибка: Старая версия клиентского терминала"); break;
     case ERR_NO_CONNECTION:
       Print("Ошибка: Нет связи с торговым сервером"); break;
     case ERR_NOT_ENOUGH_RIGHTS:
       Print("Ошибка: Недостаточно прав"); break;
     case ERR_TOO_FREQUENT_REQUESTS:
       Print("Ошибка: Слишком частые запросы"); break;
     case ERR_MALFUNCTIONAL_TRADE:
       Print("Ошибка: Недопустимая операция нарушающая функционирование сервера"); break;
     case ERR_ACCOUNT_DISABLED:
       Print("Ошибка: Счет заблокирован"); break;
     case ERR_INVALID_ACCOUNT:
       Print("Ошибка: Неправильный номер счета"); break;
     case ERR_TRADE_TIMEOUT:
       Print("Ошибка: Истек срок ожидания совершения сделки"); break;
     case ERR_INVALID_PRICE:
       Print("Ошибка: Неправильная цена"); break;
     case ERR_INVALID_STOPS:
       Print("Ошибка: Неправильные стопы"); break;
     case ERR_INVALID_TRADE_VOLUME:
       Print("Ошибка: Неправильный объем"); break;
     case ERR_MARKET_CLOSED:
       Print("Ошибка: Рынок закрыт"); break;
     case ERR_TRADE_DISABLED:
       Print("Ошибка: Торговля запрещена"); break;
     case ERR_NOT_ENOUGH_MONEY:
       Print("Ошибка: Недостаточно денег для совершения операции"); break;
     case ERR_PRICE_CHANGED:
       Print("Ошибка: Цена изменилась"); break;
     case ERR_OFF_QUOTES:
       Print("Ошибка: Нет цен"); break;
     case ERR_BROKER_BUSY:
       Print("Ошибка: Брокер занят"); break;
     case ERR_REQUOTE:
       Print("Ошибка: Новые цены"); break;
     case ERR_ORDER_LOCKED:
       Print("Ошибка: Ордер заблокирован и уже обрабатывается"); break;
     case ERR_LONG_POSITIONS_ONLY_ALLOWED:
       Print("Ошибка: Разрешена только покупка"); break;
     case ERR_TOO_MANY_REQUESTS:
       Print("Ошибка: Слишком много запросов"); break;
     case ERR_TRADE_MODIFY_DENIED:
       Print("Ошибка: Модификация запрещена, так как ордер слишком близок к рынку"); break;
     case ERR_TRADE_CONTEXT_BUSY:
       Print("Ошибка: Подсистема торговли занята"); break;
     case ERR_TRADE_EXPIRATION_DENIED:
       Print("Ошибка: Использование даты истечения ордера запрещено брокером"); break;
     case ERR_TRADE_TOO_MANY_ORDERS:
       Print("Ошибка: Количество открытых и отложенных ордеров достигло предела, установленного брокером"); break;
     case ERR_TRADE_HEDGE_PROHIBITED:
       Print("Ошибка: Попытка открыть противоположную позицию к уже существующей в случае, если хеджирование запрещено"); break;
     case ERR_TRADE_PROHIBITED_BY_FIFO:
       Print("Ошибка: Попытка закрыть позицию по инструменту в противоречии с правилом FIFO."); break;
     case ERR_NO_MQLERROR:
       /*Print("Ошибка: Нет ошибки");*/ break;
     case ERR_WRONG_FUNCTION_POINTER:
       Print("Ошибка: Неправильный указатель функции"); break;
     case ERR_ARRAY_INDEX_OUT_OF_RANGE:
       Print("Ошибка: Индекс массива - вне диапазона"); break;
     case ERR_NO_MEMORY_FOR_CALL_STACK:
       Print("Ошибка: Нет памяти для стека функций"); break;
     case ERR_RECURSIVE_STACK_OVERFLOW:
       Print("Ошибка: Переполнение стека после рекурсивного вызова"); break;
     case ERR_NOT_ENOUGH_STACK_FOR_PARAM:
       Print("Ошибка: На стеке нет памяти для передачи параметров"); break;
     case ERR_NO_MEMORY_FOR_PARAM_STRING:
       Print("Ошибка: Нет памяти для строкового параметра"); break;
     case ERR_NO_MEMORY_FOR_TEMP_STRING:
       Print("Ошибка: Нет памяти для временной строки"); break;
     case ERR_NOT_INITIALIZED_STRING:
       Print("Ошибка: Неинициализированная строка"); break;
     case ERR_NOT_INITIALIZED_ARRAYSTRING:
       Print("Ошибка: Неинициализированная строка в массиве"); break;
     case ERR_NO_MEMORY_FOR_ARRAYSTRING:
       Print("Ошибка: Нет памяти для строкового массива"); break;
     case ERR_TOO_LONG_STRING:
       Print("Ошибка: Слишком длинная строка"); break;
     case ERR_REMAINDER_FROM_ZERO_DIVIDE:
       Print("Ошибка: Остаток от деления на ноль"); break;
     case ERR_ZERO_DIVIDE:
       Print("Ошибка: Деление на ноль"); break;
     case ERR_UNKNOWN_COMMAND:
       Print("Ошибка: Неизвестная команда"); break;
     case ERR_WRONG_JUMP:
       Print("Ошибка: Неправильный переход"); break;
     case ERR_NOT_INITIALIZED_ARRAY:
       Print("Ошибка: Неинициализированный массив"); break;
     case ERR_DLL_CALLS_NOT_ALLOWED:
       Print("Ошибка: Вызовы DLL не разрешены"); break;
     case ERR_CANNOT_LOAD_LIBRARY:
       Print("Ошибка: Невозможно загрузить библиотеку"); break;
     case ERR_CANNOT_CALL_FUNCTION:
       Print("Ошибка: Невозможно вызвать функцию"); break;
     case ERR_EXTERNAL_CALLS_NOT_ALLOWED:
       Print("Ошибка: Вызовы внешних библиотечных функций не разрешены"); break;
     case ERR_NO_MEMORY_FOR_RETURNED_STR:
       Print("Ошибка: Недостаточно памяти для строки, возвращаемой из функции"); break;
     case ERR_SYSTEM_BUSY:
       Print("Ошибка: Система занята"); break;
     case ERR_INVALID_FUNCTION_PARAMSCNT:
       Print("Ошибка: Неправильное количество параметров функции"); break;
     case ERR_INVALID_FUNCTION_PARAMVALUE:
       Print("Ошибка: Недопустимое значение параметра функции"); break;
     case ERR_STRING_FUNCTION_INTERNAL:
       Print("Ошибка: Внутренняя ошибка строковой функции"); break;
     case ERR_SOME_ARRAY_ERROR:
       Print("Ошибка: Ошибка массива"); break;
     case ERR_INCORRECT_SERIESARRAY_USING:
       Print("Ошибка: Неправильное использование массива-таймсерии"); break;
     case ERR_CUSTOM_INDICATOR_ERROR:
       Print("Ошибка: Ошибка пользовательского индикатора"); break;
     case ERR_INCOMPATIBLE_ARRAYS:
       Print("Ошибка: Массивы несовместимы"); break;
     case ERR_GLOBAL_VARIABLES_PROCESSING:
       Print("Ошибка: Ошибка обработки глобальныех переменных"); break;
     case ERR_GLOBAL_VARIABLE_NOT_FOUND:
       Print("Ошибка: Глобальная переменная не обнаружена"); break;
     case ERR_FUNC_NOT_ALLOWED_IN_TESTING:
       Print("Ошибка: Функция не разрешена в тестовом режиме"); break;
     case ERR_FUNCTION_NOT_CONFIRMED:
       Print("Ошибка: Функция не разрешена"); break;
     case ERR_SEND_MAIL_ERROR:
       Print("Ошибка: Ошибка отправки почты"); break;
     case ERR_STRING_PARAMETER_EXPECTED:
       Print("Ошибка: Ожидается параметр типа string"); break;
     case ERR_INTEGER_PARAMETER_EXPECTED:
       Print("Ошибка: Ожидается параметр типа integer"); break;
     case ERR_DOUBLE_PARAMETER_EXPECTED:
       Print("Ошибка: Ожидается параметр типа double"); break;
     case ERR_ARRAY_AS_PARAMETER_EXPECTED:
       Print("Ошибка: В качестве параметра ожидается массив"); break;
     case ERR_HISTORY_WILL_UPDATED:
       Print("Ошибка: Запрошенные исторические данные в состоянии обновления"); break;
     case ERR_TRADE_ERROR:
       Print("Ошибка: Ошибка при выполнении торговой операции"); break;
     case ERR_END_OF_FILE:
       Print("Ошибка: Конец файла"); break;
     case ERR_SOME_FILE_ERROR:
       Print("Ошибка: Ошибка при работе с файлом"); break;
     case ERR_WRONG_FILE_NAME:
       Print("Ошибка: Неправильное имя файла"); break;
     case ERR_TOO_MANY_OPENED_FILES:
       Print("Ошибка: Слишком много открытых файлов"); break;
     case ERR_CANNOT_OPEN_FILE:
       Print("Ошибка: Невозможно открыть файл"); break;
     case ERR_INCOMPATIBLE_FILEACCESS:
       Print("Ошибка: Несовместимый режим доступа к файлу"); break;
     case ERR_NO_ORDER_SELECTED:
       Print("Ошибка: Ни один ордер не выбран"); break;
     case ERR_UNKNOWN_SYMBOL:
       Print("Ошибка: Неизвестный символ"); break;
     case ERR_INVALID_PRICE_PARAM:
       Print("Ошибка: Неправильный параметр цены для торговой функции"); break;
     case ERR_INVALID_TICKET:
       Print("Ошибка: Неверный номер тикета"); break;
     case ERR_TRADE_NOT_ALLOWED:
       Print("Ошибка: Торговля не разрешена. Необходимо включить опцию /Разрешить советнику торговать/ в свойствах эксперта."); break;
     case ERR_LONGS_NOT_ALLOWED:
       Print("Ошибка: Длинные позиции не разрешены. Необходимо проверить свойства эксперта."); break;
     case ERR_SHORTS_NOT_ALLOWED:
       Print("Ошибка: Короткие позиции не разрешены. Необходимо проверить свойства эксперта."); break;
     case ERR_OBJECT_ALREADY_EXISTS:
       Print("Ошибка: Объект уже существует"); break;
     case ERR_UNKNOWN_OBJECT_PROPERTY:
       Print("Ошибка: Запрошено неизвестное свойство объекта"); break;
     case ERR_OBJECT_DOES_NOT_EXIST:
       Print("Ошибка: Объект не существует"); break;
     case ERR_UNKNOWN_OBJECT_TYPE:
       Print("Ошибка: Неизвестный тип объекта"); break;
     case ERR_NO_OBJECT_NAME:
       Print("Ошибка: Нет имени объекта"); break;
     case ERR_OBJECT_COORDINATES_ERROR:
       Print("Ошибка: Ошибка координат объекта"); break;
     case ERR_NO_SPECIFIED_SUBWINDOW:
       Print("Ошибка: Не найдено указанное подокно"); break;
     case ERR_SOME_OBJECT_ERROR:
       Print("Ошибка: Ошибка при работе с объектом"); break;
     case 4250: //ERR_NOTIFICATION_SEND_ERROR
       Print("Ошибка: Ошибка постановки уведомления в очередь на отсылку"); break;
     case 4251:  //ERR_NOTIFICATION_WRONG_PARAMETER
       Print("Ошибка: Неверный параметр - в функцию SendNotification() передали пустую строку"); break;
     case 4252:  //ERR_NOTIFICATION_WRONG_SETTINGS
       Print("Ошибка: Неверные настройки для отправки уведомлений (не указан ID или не выставлено разрешение"); break;
     case 4253:  //ERR_NOTIFICATION_TOO_FREQUENT
       Print("Ошибка: Слишком частая отправка уведомлений"); break;
     default:
       Print("Ошибка: не опознана, посмотрите по каталогу, #", Error); break;
    }
   return(Error); 
  }




