 //+------------------------------------------------------------------+
//|                                                     LotAlert.mq4 |
//|                                           Copyright 2016, GlobuX |
//|                                              http://globux.ya.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, GlobuX"
#property link      "http://globux.ya.ru"
#property version   "3.0"
#property strict

extern double Lot_Alert = 2; // Макс. лот для тревоги
extern int MessagePeriod = 120; // Интервал повтора сообщений, сек
extern bool PC_Alert = true; // Сообщения на ББ
extern bool MobileAlert = true; // Соообщения для PDA
extern uint shortTimer = 6; // Пауза для сообщений на PDA
//extern int ScanPeriod = 10; // Период обновления, сек


#define arrSize 7 // количество элементов второй размерности массива
const bool isActiveSymbol = true; // false - для поиска всех символов (включая активные)
const int onTiker = 1; //Период повторения события onTick
//const uint shortTimer = 10;
const uint longTimer = 61;
const uint buf_sz = 30;  // Буфер сообщений, количество частей
const int prt_sz = 255;  // Размер одной части сообщения, количество символов
const uint numRepeat = 10;  // Количество повторов до длинной паузы
bool isWorking = false;
 
// Блок объявления классов
class OrdersWatcher {
// поля класса OrdersWatcher
 public:
   double lotAlert;
   bool isExistActiveOrders;
   bool isChangeOrders;
   int totalSymbol; // Всего валют
   int totalOrders; // Всего ордеров
   string Message;
   double biggestBuyOrder;
   double biggestSelOrder;
   string arrSymbols[];
   //-------------------------------------------
   int arrCurrNumBuyOrders[]; // общее количество Buy ордеров, результат текущего сканирования
   int arrCurrNumSelOrders[]; // общее количество Sell ордеров, результат текущего сканирования
   int arrPreNumBuyOrders[]; // общее количество Buy ордеров, результат предыдущего сканирования
   int arrPreNumSelOrders[]; // общее количество Sell ордеров, результат предыдущего сканирования
   //-------------------------------------------
   int arrNumBigBuyOrders[]; // количество Buy ордеров с объемом больше LotAlert
   int arrNumBigSelOrders[]; // количество Sel ордеров с объемом больше LotAlert
   //-------------------------------------------
   double aBiggestCurBuyOrder[]; // объем наибольшего текущего Buy ордера
   double aBiggestCurSelOrder[]; // объем наибольшего текущего Sell ордера
   double aBiggestPreBuyOrder[]; // объем наибольшего предыдущего Buy ордера
   double aBiggestPreSelOrder[]; // объем наибольшего предыдущего Sell ордера
   //-------------------------------------------
   double arrVolBuyOrders[]; // общий объем Buy ордеров
   double arrVolSelOrders[]; // общий объем Sell ордеров
   //-------------------------------------------
   double arrBigVolBuyOrders[][3]; // ордера Buy с наибольшими лотами
   double arrBigVolSelOrders[][3]; // ордера Sell с наибольшими лотами

// Методы класса OrdersWatcher
// Конструктор класса OrdersWatcher
   void OrdersWatcher(double lotSize) { // конструктор класса
      lotAlert = lotSize;
      isChangeOrders = false;
      totalSymbol = SymbolsTotal(isActiveSymbol); // всего сканируемых валют
   // подготавливаем массивы для работы в соответствии с количеством активных валют
      ArrayResize(arrSymbols, totalSymbol);
      ArrayResize(arrCurrNumBuyOrders, totalSymbol); // (массив переданный по ссылке, новый размер массива, резервное значение размера (избыточное)
      ArrayResize(arrCurrNumSelOrders, totalSymbol);
      ArrayResize(arrPreNumBuyOrders, totalSymbol);
      ArrayResize(arrPreNumSelOrders, totalSymbol);
      ArrayResize(arrNumBigBuyOrders, totalSymbol);
      ArrayResize(arrNumBigSelOrders, totalSymbol);
      ArrayResize(arrVolBuyOrders, totalSymbol);
      ArrayResize(arrVolSelOrders, totalSymbol);
      ArrayResize(arrBigVolBuyOrders, totalSymbol);
      ArrayResize(arrBigVolSelOrders, totalSymbol);
      ArrayResize(aBiggestCurBuyOrder, totalSymbol);
      ArrayResize(aBiggestCurSelOrder, totalSymbol);
      ArrayResize(aBiggestPreBuyOrder, totalSymbol);
      ArrayResize(aBiggestPreSelOrder, totalSymbol);
   }
   /*
   // Деструктор класса OrdersWatcher
   void ~OrdersWatcher() {
   
   }
   */
// Метод SetLotAlert
   void SetLotAlert(double lot) {
      lotAlert = lot;
   }
// Метод Scan
   void Scan() {  // метод находит все ордера по активным символам и помещает в массив
      string symbol;// Валюта
      double lot = 0;
      isChangeOrders = false;
      isExistActiveOrders = false;
   // Перед сканированием запоминаем предыдущее состояние ордеров
      ArrayCopy(arrPreNumBuyOrders, arrCurrNumBuyOrders); // (куда копируем, откуда копируем)
      ArrayCopy(arrPreNumSelOrders, arrCurrNumSelOrders);
      ArrayCopy(aBiggestPreBuyOrder,aBiggestCurBuyOrder);
      ArrayCopy(aBiggestPreSelOrder,aBiggestCurSelOrder);
   //очищаем массивы
      //ArrayInitialize(arrSymbols, NULL);
      ArrayInitialize(arrCurrNumBuyOrders, 0);
      ArrayInitialize(arrCurrNumSelOrders, 0);
      ArrayInitialize(arrNumBigBuyOrders, 0);
      ArrayInitialize(arrNumBigSelOrders, 0);
      ArrayInitialize(arrVolBuyOrders, 0);
      ArrayInitialize(arrVolSelOrders, 0);
      ArrayInitialize(arrBigVolBuyOrders, 0);
      ArrayInitialize(arrBigVolSelOrders, 0);
      ArrayInitialize(aBiggestCurBuyOrder, 0);
      ArrayInitialize(aBiggestCurSelOrder, 0);
      
   //сканируем все открытые ордера и запоминаем состояние в массивы
      RefreshRates();
      totalOrders = OrdersTotal(); 
      for (int i = 0; i < totalSymbol; i++) {  // цикл по перебору каждого символа
         symbol = SymbolName(i, isActiveSymbol); // запоминаем символ текущей валюты
         arrSymbols[i] = symbol;// Запоминаем в массив название символа
      // подготавливаем рабочие переменные к очередному проходу
         lot = 0;
         for (int j = 0; j < totalOrders; j++) { // цикл по перебору всех ордеров и заполнению массивов
            if (OrderSelect(j, SELECT_BY_POS, MODE_TRADES) == false) {continue;}
            if (OrderSymbol() != symbol) {continue;}
            if (OrderType() == OP_BUY) {
               arrCurrNumBuyOrders[i]++; // увеличиваем счетчик открытых ордеров BUY
               isExistActiveOrders = true;
               lot = OrderLots();
               arrVolBuyOrders[i] = arrVolBuyOrders[i] + lot;//Общий объем BUY по валюте
               if (lot >= lotAlert) { // Если объем текущего ордера больше чем LotAlert увеличиваем счетчик
                  arrNumBigBuyOrders[i]++;
               }
               if (lot >= aBiggestCurBuyOrder[i]) { //Если объем текущего больше ордера с наибольшим объемом, то сохраняем как максимальный этот 
                  aBiggestCurBuyOrder[i] = lot;
                  arrBigVolBuyOrders[i][0] = arrBigVolBuyOrders[i][1];
                  arrBigVolBuyOrders[i][1] = arrBigVolBuyOrders[i][2];
                  arrBigVolBuyOrders[i][2] = aBiggestCurBuyOrder[i]; // Ордер BUY с максимальным лотом  
                  continue; // делаем следующий цикл «j»
               }
            } else if (OrderType() == OP_SELL) {
               arrCurrNumSelOrders[i]++; // увеличиваем счетчик открытых ордеров SELL
               isExistActiveOrders = true;
               lot = OrderLots();
               arrVolSelOrders[i] = arrVolSelOrders[i] + lot;//Общий объем SELL по валюте
               if (lot >= lotAlert) { // Если объем текущего ордера больше чем LotAlert увеличиваем счетчик
                  arrNumBigSelOrders[i]++;
               }
               if (lot >= aBiggestCurSelOrder[i]) { //Если объем текущего больше ордера с наибольшим объемом, то сохраняем как максимальный этот
                  aBiggestCurSelOrder[i] = lot;
                  arrBigVolSelOrders[i][0] = arrBigVolSelOrders[i][1];
                  arrBigVolSelOrders[i][1] = arrBigVolSelOrders[i][2];
                  arrBigVolSelOrders[i][2] = aBiggestCurSelOrder[i]; // Ордер SELL с максимальным лотом  
                  continue; // делаем следующий цикл «j»
               }
            } // end of for «j»
         } // end of for «i»
      } 
   } //end of method (Scan)

   void ViewComment() {
      string commentMessage = NULL;
      for (int i = 0; i < totalSymbol; i++) {
         if (arrPreNumBuyOrders[i]!=0 || arrCurrNumBuyOrders[i]!=0 ||
             arrPreNumSelOrders[i]!=0 || arrCurrNumSelOrders[i]!=0) {
         commentMessage = commentMessage // +
         + arrSymbols[i]
         + " Buy: Было("
         + IntegerToString(arrPreNumBuyOrders[i]) + "), стало("
         + IntegerToString(arrCurrNumBuyOrders[i]) + "), Lot>2: "
         + IntegerToString(arrNumBigBuyOrders[i]) + ", Сумм общ:"
         + DoubleToString(arrVolBuyOrders[i],2) + ", Макс орд:"
         + DoubleToString(aBiggestCurBuyOrder[i],2)
         + "); Sell: Было("
         + IntegerToString(arrPreNumSelOrders[i])  + "), стало("
         + IntegerToString(arrCurrNumSelOrders[i]) + "), Lot>2: "
         + IntegerToString(arrNumBigSelOrders[i]) + ", Сумм общ:"
         + DoubleToString(arrVolSelOrders[i],2) + ", Макс орд:"
         + DoubleToString(aBiggestCurSelOrder[i],2)
         + "\n";
         }
      }
      Comment(commentMessage);
   }

// Метод Report, возвращает true если были изменения в активных ордерах, иначе false
   bool Report() {  // Метод для 
      int size = ArrayRange(arrSymbols,0);
      string New = NULL;
      Message = NULL;
      bool modifedOrders = false;
      bool isBuyMsg;
      for (int i = 0; i < totalSymbol; i++) {  // цикл по перебору каждого символа
         isBuyMsg = false;
         if (arrCurrNumBuyOrders[i] == 0) {
            // ордеров = 0!
            if (arrCurrNumBuyOrders[i] != arrPreNumBuyOrders[i] && aBiggestPreBuyOrder[i] >= lotAlert) {
               // ордеров = 0, но в прошлый раз было больше, значит все закрылись, это событие!
               // отправляем сообщение с пометкой NEW! Orders (SYMBOL TYPE) CLOSED
               New = New + arrSymbols[i] + "-Buy: ALL CLOSED!; ";
               modifedOrders = true;
               isBuyMsg = true;
            } else {
               // ордеров нет = 0 - столько же сколько в прошлый раз, т.е. ничего не прибавилось
               // ничего не делаем, сообщение не отправляем
               //Message = Message + " " + arrSymbols[i] + "-Buy - ордеров нет; ";
            }
         } else {
            // ордера есть!
            if (aBiggestCurBuyOrder[i] >= lotAlert) {
               if (arrCurrNumBuyOrders[i] != arrPreNumBuyOrders[i]) {
                  // ордера есть и их количество изменилось!!!
                  // есть изменения, отправляем сообщение с пометкой NEW! и инфу о количестве
                  New = New + arrSymbols[i] + "-Buy: "
                        + DoubleToString(arrBigVolBuyOrders[i][1], 2) + "-"
                        + DoubleToString(arrBigVolBuyOrders[i][2], 2) + ", "  
                        + IntegerToString(arrNumBigBuyOrders[i]) + "("
                        + IntegerToString(arrCurrNumBuyOrders[i]) + "); ";
                  modifedOrders = true;
                  isBuyMsg = true;
               } else {
                  // ордера есть, но их количество с прошлого раза не изменилось
                  // изменений нет, отправляем простое сообщение о количестве ордеров
                  Message = Message + arrSymbols[i] + "-Buy: "
                        + DoubleToString(arrBigVolBuyOrders[i][1], 2) + "-"
                        + DoubleToString(arrBigVolBuyOrders[i][2], 2) + ", "  
                        + IntegerToString(arrNumBigBuyOrders[i]) + "("
                        + IntegerToString(arrCurrNumBuyOrders[i]) + "); ";
                  isBuyMsg = true;
               }
            }
         } // end BUY
         
         if (arrCurrNumSelOrders[i] == 0) {
            // ордеров = 0!
            if (arrCurrNumSelOrders[i] != arrPreNumSelOrders[i] && aBiggestPreSelOrder[i] >= lotAlert) {
               // ордеров = 0, но в прошлый раз было больше, значит все закрылись, это событие!
               // отправляем сообщение с пометкой NEW! Orders (SYMBOL TYPE) CLOSED
               if (isBuyMsg == true) {
                  New = New + " Sell: ALL CLOSED!; ";
               } else {
                  New = New + arrSymbols[i] + "-Sell: ALL CLOSED!; ";
               }
               modifedOrders = true;
            } else {
               // ордеров нет = 0 - столько же сколько в прошлый раз, т.е. ничего не прибавилось
               // ничего не делаем, сообщение не отправляем
               //Message = Message + " " + arrSymbols[i] + "-Sell - ордеров нет; ";
            }
         } else {
            // ордера есть!
            if (aBiggestCurSelOrder[i] >= lotAlert) {
               if (arrCurrNumSelOrders[i] != arrPreNumSelOrders[i]) {
                  // ордера есть и их количество изменилось!!!
                  // есть изменения, отправляем сообщение с пометкой NEW! и инфу о количестве
                  if (isBuyMsg == true) {
                     New = New + " Sell: ";
                  } else {
                     New = New + arrSymbols[i] + "-Sell: ";
                  }
                  New = New
                        + DoubleToString(arrBigVolSelOrders[i][1], 2) + "-"
                        + DoubleToString(arrBigVolSelOrders[i][2], 2) + ", "  
                        + IntegerToString(arrNumBigSelOrders[i]) + "("
                        + IntegerToString(arrCurrNumSelOrders[i]) + "); ";
                  modifedOrders = true;
               } else {
                  // ордера есть, но их количество с прошлого раза не изменилось
                  // изменений нет, отправляем простое сообщение о количестве ордеров
                  if (isBuyMsg == true) {
                     Message = Message + " Sell: ";
                  } else {
                     Message = Message + arrSymbols[i] + "-Sell: ";
                  }
                  Message = Message
                        + DoubleToString(arrBigVolSelOrders[i][1], 2) + "-"
                        + DoubleToString(arrBigVolSelOrders[i][2], 2) + ", "  
                        + IntegerToString(arrNumBigSelOrders[i]) + "("
                        + IntegerToString(arrCurrNumSelOrders[i]) + "); ";
               }
            }
         } // end SELL
      }
      if (New != NULL) {New = "New[" + New + "] ";}
      if (modifedOrders == true) {
         Message = New;
      } else {
         Message = New + Message;
      }
      if (Message != NULL) {Message = (string)lotAlert + "< " + Message;}
      return(modifedOrders);
   } //конец метода Report

// Метод GetMessage - возвращает подготовленную строку информационного сообщения
   string GetMessage() {
      return(Message);
   }
// Метод GetLength
   int GetLength() {
      return(StringLen(Message));
   }
// Метод GetChanges
   int GetChanges() {
      bool chg = isChangeOrders;
	  isChangeOrders = false;
	  return(chg);
   }   
}; //END OF CLASS "check"

class CachedAlert { //Класс CachedAlert - отправка кэшированных сообщений
public:
   uint posWriter;
   uint posReader;
   int partsize;
   uint bufSize;
   string aCachedMsg[];
// Конструктор CachedAlert, без параметров, не возвращает результат.
   void CachedAlert() {
      posWriter = 0;
      posReader = 0;
      partsize = 254;
      bufSize = 30;
      ArrayResize(aCachedMsg,bufSize,20);
   }
// Конструктор CachedAlert, с параметрами, не возвращает результат.
   void CachedAlert(uint bsize, int psize) {
      posWriter = 0;
      posReader = 0;
      bufSize = bsize;
      partsize = psize;
      ArrayResize(aCachedMsg,bufSize,20);
   }
// Метод sendDirectMsg - отправляет сообщение по частям, принимает параметр отправлять ли на комп
   void sendDirectMsg(bool toPC) {
      while (posReader != posWriter) {
         Print(aCachedMsg[posReader]);
         if (toPC == true) {
            PlaySound("C:\\Windows\\Media\\Alarm06.wav");
            Alert(aCachedMsg[posReader]);
         }
         posReader++;
         if (posReader >= bufSize) {posReader = 0;}
         //Print("XReader: поз.записи-", posWriter, ", поз.чтения-", posReader);
      }
   }
// Метод sendCachedMsg - отправляет по частям кешированное сообщение, принимает флаги отправлять на комп, отправлять на мобилу.
   bool sendCachedMsg(bool toPC, bool toPDA) {
      bool result = false;
      if (posReader == posWriter) return(result);
      Print(aCachedMsg[posReader]);
      //result = true; // Закомментировать строку, если нужно видеть сообщение при ошибке отправки на мобилу
      if (toPC == true) {
         PlaySound("C:\\Windows\\Media\\Alarm06.wav");
         Alert(aCachedMsg[posReader]);
      }
      if (toPDA == true) {
         if (SendNotification(aCachedMsg[posReader]) == false) {
            Print("Ошибка при отправке Push-сообщения на мобильное устройство");
         } else {
            result = true;
         }
      }
      posReader++;
      if (posReader >= bufSize) {posReader = 0;}
      //Print("Reader: поз.записи-", posWriter, ", поз.чтения-", posReader);
      return(result);
   }
// Метод saveToCache - принимает строку, разбивает ее на части и помещает в буферный массив
   void saveToCache(string str) {
      int pos = 0;
      int strLength = StringLen(str);
      if (strLength == 0) {return;}
      while (true) {
         if (pos + partsize <= strLength) {
            aCachedMsg[posWriter] = StringSubstr(str, pos, partsize);
            pos = pos + partsize;
            posWriter++;
            if (posWriter >= bufSize) {posWriter = 0;}
         } else {
            aCachedMsg[posWriter] = StringSubstr(str, pos, strLength-pos);
            posWriter++;
            if (posWriter >= bufSize) {posWriter = 0;}
            break;
         }
      }
      //Print("Write: поз.записи-", posWriter, ", поз.чтения-", posReader);
   }
};  //END OF CLASS "CachedAlert"

// Класс UserTimer
class UserTimer { //класс пользовательских таймеров
//Конструктор принимает параметр задержки в секундах
//Метод set принимает параметр задержки в секундах
//Метод doWork возвращает результат bool, true - если указанный период прошел, false - если не прошел.
public:
   uint timerStart;
   uint waitPeriod;
// Конструктор CanWork принимает параметр uint Время_в_секундах
   void UserTimer(uint timer) {
      timerStart = 0;
      waitPeriod = timer * 1000; 
   }
// Метод (сеттер) set принимает параметр uint Время_в_секундах 
   void set(uint timer) {
      waitPeriod = timer * 1000;
   }
// Метод  reset - сброс таймера в начало
   void reset() {
      timerStart = GetTickCount();
   }
// Метод forcedWork
   void forcedWork() {
      timerStart = GetTickCount() - waitPeriod;
   }
// Метод timeToWork возвращает результат bool   
   bool timeToWork() {
      uint timerCurrent = GetTickCount();
      uint timerDelta = timerCurrent - timerStart;
      //Print("До исполнения: ", timerDelta, ", контрольное время: ", waitPeriod);
      if (timerDelta >= waitPeriod) {
         timerStart = timerCurrent;
         return (true);
      }
      return (false);
   }
}; //END OF CLASS «UserTimer»


// Класс UserTwixTimer
class UserTwixTimer {
public:
	uint numRepeat;
	uint timerOne;
	uint timerTwo;
	uint currPos;
   uint aEvents[];
// Конструктор класса UserDoubleTimer
	void UserTwixTimer(uint shortT, uint longT, uint repeats) {
		timerOne = shortT * 1000;
		timerTwo = longT * 1000;
		numRepeat = repeats;
		currPos = 0;
		ArrayResize(aEvents,numRepeat);
	}
// Метод timeToWork дифференциального распределения по времени
   bool timeToWork() {
      bool result = false;
      uint oldest;
      uint currentTime = GetTickCount();
      if (currPos >= numRepeat-1) {oldest = 0;} else {oldest = currPos + 1;}
      uint deltaOne = currentTime - aEvents[currPos];
      uint deltaTwo = currentTime - aEvents[oldest];
      //Print("Первый счётчик: ", deltaOne, ", Второй счётчик: ", deltaTwo);
      if (deltaTwo >= timerTwo && deltaOne >= timerOne) {
         result = true;
      }
      return(result);
   }
// Метод workIsDone
   void workIsDone() {
      currPos++;
      if (currPos == numRepeat) {currPos = 0;}
      aEvents[currPos] = GetTickCount();
   }
// Метод (сеттер) set принимает параметр uint Время_в_секундах 
   void set(uint shortT, uint longT) {
      timerOne = shortT * 1000;
      timerTwo = longT * 1000;
   }
   // Метод setPdaPause
   void setPdaPause(uint shortT) {
      timerOne = shortT * 1000;
   }
}; // END OF CLASS «UserTwixTimer»


//+------------------------------------------------------------------+
//| Создание экземпляров обектов                                     |
//+------------------------------------------------------------------+
OrdersWatcher* watcher = new OrdersWatcher(Lot_Alert); // создаем объект класса OrdersWatcher
UserTimer* timer1 = new UserTimer(MessagePeriod);
UserTwixTimer* twixTimer = new UserTwixTimer(shortTimer, longTimer, numRepeat);
CachedAlert* buf = new CachedAlert(buf_sz, prt_sz);

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   EventSetTimer(onTiker); // Задаем интервал сканирования (по умолчанию 3 секунды)
   watcher.SetLotAlert(Lot_Alert);
   timer1.forcedWork();
   twixTimer.setPdaPause(shortTimer);
   if (isWorking == false) {
      SendNotification("Запущен советник LotAlert: " + (string)TimeCurrent());
      isWorking = true;
   }
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   //Уничтожение объектов
      if ( UninitializeReason() != REASON_PARAMETERS) {
      delete watcher;
      delete timer1;
      delete twixTimer;
      delete buf;
      SendNotification("Советник LotAlert завершил работу: " + (string)TimeCurrent());
      EventKillTimer();
      } else {
         SendNotification("LotAlert: параметры изменены: " + (string)TimeCurrent());
      }
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
   {

   }
//+------------------------------------------------------------------+
//| Expert onTimer function                                          |
//+------------------------------------------------------------------+
void OnTimer() {
   watcher.Scan();
   bool changes = watcher.Report();
   //Print("Главный таймер сработал");
   //отправка
   if (changes == true) {
      //Print("Условие выполнено: изменения в ордерах");
      watcher.ViewComment();
      buf.saveToCache(watcher.GetMessage());
      timer1.reset();
   }
   //отправка сообщений по таймеру
   if (timer1.timeToWork() == true) {
      //Print("Таймер повторной отправки сообщения сработал");
      watcher.ViewComment();
      buf.saveToCache(watcher.GetMessage());
      buf.sendDirectMsg(PC_Alert);
   }
   //отправка кэшированных сообщений
   if (twixTimer.timeToWork() == true) {
      //Print("Twix сработал (основное тело программы)");
      if (buf.sendCachedMsg(PC_Alert, MobileAlert) == true) {
         //Print("Соообщение на мобилу отправлено");
         twixTimer.workIsDone();
      }
   }
}
//+------------------------------------------------------------------+