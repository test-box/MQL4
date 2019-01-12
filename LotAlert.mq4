//+------------------------------------------------------------------+
//|                                                     LotAlert.mq4 |
//|                                           Copyright 2016, GlobuX |
//|                                              http://globux.ya.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, GlobuX"
#property link      "http://globux.ya.ru"
#property version   "1.1"
#property strict

extern double Lot_Alert = 2;

class LotWaveAlert {
   public:
   void check(double lotAlert) {
      for (int i=0; i<OrdersTotal(); i++) {
         if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) {continue;}
         //if (OrderSymbol() != Symbol()) continue;   //действует на текущей валюте
         if (OrderLots() >= lotAlert) {
            PlaySound("C:\\Windows\\Media\\Alarm06.wav"); Alert("ЛОТ=", lotAlert, ", ", OrderSymbol());
         }
      }
   }
};


class PushAlert {
 private:
   bool act;
   string arrayPreOrd[][5];
   string arrayCurrOrd[][5];
   int symTotal;
   int ordTotal;
   void arrayClear() {
      int size = ArrayRange(arrayCurrOrd,0);
      for (int i = 0; i < size; i++) {
         for (int j = 0; j < 5; j++) {
            arrayCurrOrd[i][j] = "";
         }
      }
   }
 public:
   void PushAlert() {
      act = true;
      symTotal = SymbolsTotal(act);
      ArrayResize(arrayCurrOrd, symTotal); //Параметры: массив, переданный по ссылке / новый размер массива / резервное значение размера (избыточное)
      ArrayResize(arrayPreOrd, symTotal);
   }
   /*
   void ~PushAlert() {
   }
   */
   void check(double lotAlert) {
      string symbol;
      int openSymOrders;
      ordTotal = OrdersTotal();
      ArrayCopy(arrayPreOrd, arrayCurrOrd); // куда копируем / откуда копируем
      arrayClear();
      Print("Массив очищен");
      for (int i = 0; i < symTotal; i++) {
         symbol = SymbolName(i, act);
         openSymOrders = 0;
         arrayCurrOrd[i][0] = symbol;
         Print("Символ №", i, ": ", symbol);
         for (int j = 0; j < ordTotal; j++) {
            if (OrderSelect(j, SELECT_BY_POS, MODE_TRADES) == false) {continue;}
            
            if (OrderSymbol() != symbol) {continue;}
            openSymOrders++;
            arrayCurrOrd[i][1] = IntegerToString(openSymOrders);
            if (OrderLots() > StringToDouble(arrayCurrOrd[i][2])) {
               arrayCurrOrd[i][2] = DoubleToString(OrderLots(), 2);
               arrayCurrOrd[i][3] = (string) OrderOpenTime();
            }
            Print(arrayCurrOrd[i][0], ", ордеров: ", arrayCurrOrd[i][1], ", макс. лот: ", arrayCurrOrd[i][2], ", время откр.: ", arrayCurrOrd[i][3], "");
         }
      } 
   }
   void test() {
      int size = ArrayRange(arrayCurrOrd,0);
      for (int i = 0; i < size; i++) {
         if (arrayCurrOrd[i][1] != "") {
            Print(arrayCurrOrd[i][0], ", ордеров: ", arrayCurrOrd[i][1], ", макс. лот: ", arrayCurrOrd[i][2], ", время откр.: ", arrayCurrOrd[i][3], ""); 
         }
      }
      Print("Всего символов: ", symTotal);
   }

};

   //Создание обектов
   LotWaveAlert* lAlert = new LotWaveAlert();
   PushAlert* pAlert = new PushAlert();

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   //Уничтожение объектов
   delete lAlert;
   delete pAlert;
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
   {
      //lAlert.check(Lot_Alert);
      pAlert.check(Lot_Alert);
      pAlert.test();
   }
//+------------------------------------------------------------------+

/*
int GetSymbols(string &SymbolsList[])
{
// Открываем файл  symbols.raw
   
   int hFile = FileOpenHistory("symbols.raw", FILE_BIN|FILE_READ);
   if(hFile < 0) return(-1);

// Определяем количество символов, зарегистрированных в файле
   
   int SymbolsNumber = FileSize(hFile) / 1936;
   ArrayResize(SymbolsList, SymbolsNumber);

// Считываем символы из файла
   
   for(int i = 0; i < SymbolsNumber; i++)
   {
      SymbolsList[i] = FileReadString(hFile, 12);
      FileSeek(hFile, 1924, SEEK_CUR);
   }
   
// Возвращаем общее количество инструментов
   
   return(SymbolsNumber);
}

*/