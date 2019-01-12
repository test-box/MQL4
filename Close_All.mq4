//+------------------------------------------------------------------+
//|                                       Modify_Order_Set_SL_TP.mq4 |
//|                                           Copyright © 2008,  Max |
//|                                               http://gbxfiles.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2008,  Max"
#property link      "http://gbxfiles.ru"
#include <stderror.mqh>

extern int IdNum = 900;

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start()
  {
   if (OrdersTotal() != 0) ClosedAllOrders();
   else return(0);
  }
//+------------------------------------------------------------------+

void ClosedAllOrders()
  {
   Print("-= Функция закрытия всех оставшихся ордеров =-");
   Print("Количество оставшихся ордеров(OrdersTotal) = ", OrdersTotal());
   bool err;
   int error;
   int count = 0;
   int count2 = 0;
   int k = 0;
   int OrderTicketMassive[50];
   int StopOrderTicketMassive[50];
   ArrayInitialize(OrderTicketMassive,0);
   ArrayInitialize(StopOrderTicketMassive,0);
   for (int t=0; t<OrdersTotal(); t++)  //Цикл поиска ордеров советника, создает массив тикетов
     {
      if (OrderSelect(t, SELECT_BY_POS, MODE_TRADES) == false) {Print("1-я проверка: ошибка, (OrderSelect)"); continue;}
      if (OrderMagicNumber() != IdNum) {Print("2-я проверка: ошибка, (OrderMagicNumber)"); continue;}
      if (OrderSymbol() != Symbol()) {Print("3-я проверка: ошибка, (OrderSymbol)"); continue;}
      if (OrderType() == OP_BUYSTOP || OrderType() == OP_SELLSTOP)
      {
       count2++;
       StopOrderTicketMassive[count2] = OrderTicket();
       Print("Найден stop-ордер: тикет = ", OrderTicket());
      }
      else
      {
       count++;
       OrderTicketMassive[count] = OrderTicket();
       Print("Найден ордер: тикет = ", OrderTicket());
      }
     }
   for (int i=1; i <= count; i++)      //Цикл удаления найденных ордеров
     {
      OrderSelect(OrderTicketMassive[i],SELECT_BY_TICKET);
      Print("Ордер: тикет #", OrderTicket(), ", тип ордера=", OrderType(), ", валюта=", OrderSymbol(),
            ", цена открытия=", OrderOpenPrice(), ", уровень ТП=",OrderTakeProfit(), ", объем лотов=", OrderLots(),
            ", idNum=", OrderMagicNumber(), ", комментарий=", OrderComment()); 
      err = true;
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
        error = CheckError();
        if (error == 0) {err = false; k++; Print("Удален успешно."); break;}
        if (error == ERR_INVALID_TICKET) break;
        else Sleep(5000);
       }
     }
   Print("Количество удаленных ордеров: ", k);
   for (int j=1; j <= count2; j++)      //Цикл удаления stop-ордеров
     {
      OrderSelect(StopOrderTicketMassive[j],SELECT_BY_TICKET);
      Print("Стоп-Ордер: тикет #", OrderTicket(), ", удален"); 
      err = true;
      while (err == true)
       {
        OrderDelete(OrderTicket());
        error = CheckError();
        if (error == 0) {err = false; Print("Удален успешно."); break;}
        if (error == ERR_INVALID_TICKET) break;
        else Sleep(2000);
       }
     }
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

