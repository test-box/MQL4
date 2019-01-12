//+------------------------------------------------------------------+
//|                                                  CachedAlert.mq4 |
//|                                           Copyright 2016, GlobuX |
//|                                              http://globux.ya.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, GlobuX"
#property link      "http://globux.ya.ru"
#property version   "1.00"
#property strict


class CachedAlert { //����� CachedAlert - �������� ������������ ���������
public:
   uint posWriter;
   uint posReader;
   //uint t;
   string arrMsg[];
   int bufSize;
// ����������� CachedAlert, ��� ����������, �� ���������� ���������.
   void CachedAlert() {
      ArrayResize(arrMsg,30,20);
      posWriter = 0;
      posReader = 0;
      //t = 0;
      bufSize = 30;
   }
/*// ����� beginTimer - ����� ���������� �������
   void beginTimer() {
      t = 0;
   }*/
// ����� sendCachedMsg - ���������� ������������ ���������, ��������� ���������� ��������� - ���� ���������� ��� ���.
   void sendCachedMsg(bool toPC, bool toPDA) {
      if (posReader == posWriter) return;
      if (toPC == true) {
         //PlaySound("C:\\Windows\\Media\\Alarm06.wav");
         Alert(arrMsg[posReader]);
      }
      if (toPDA == true) {
         if (SendNotification(arrMsg[posReader]) == false) {
            Print("������ ��� �������� Push-��������� �� ��������� ����������");
         }
      }
      posReader++;
      if (posReader >= (uint)bufSize) {posReader = 0;}
   }
// ����� saveToCacheMsg - ��������� ��������� ����� � �������� � �������� ������
   void saveToCacheMsg(string str) {
      int pos = 0;
      int partsize = 255;
      int strLength = StringLen(str);
      if (strLength == 0) {return;}
      while (true) {
         if (pos + partsize <= strLength) {
            arrMsg[posWriter] = StringSubstr(str, pos, partsize);
            pos = pos + partsize;
            posWriter++;
            if (posWriter >= (uint)bufSize) {posWriter = 0;}
         } else if (strLength > 0) {
            arrMsg[posWriter] = StringSubstr(str, pos, strLength-pos);
            posWriter++;
            if (posWriter >= (uint)bufSize) {posWriter = 0;}
            break;
         } else {
            break;
         }
      }
   }
};


CachedAlert* buf = new CachedAlert();


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   EventSetTimer(1);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   delete buf;
   EventKillTimer();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){
   string str;
   for (int i = 0; i < 40; i++) {
      str = str + "qwertyuip" + "asdfghjklz" + "xcvbnmqwer" + "1234567890" + "!@#$%^&*()";
   }
   buf.saveToCacheMsg(str);
   //buf.readCache();
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
    buf.sendCachedMsg(true, false);
}
//+------------------------------------------------------------------+
