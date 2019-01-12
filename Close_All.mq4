//+------------------------------------------------------------------+
//|                                       Modify_Order_Set_SL_TP.mq4 |
//|                                           Copyright � 2008,  Max |
//|                                               http://gbxfiles.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright � 2008,  Max"
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
   Print("-= ������� �������� ���� ���������� ������� =-");
   Print("���������� ���������� �������(OrdersTotal) = ", OrdersTotal());
   bool err;
   int error;
   int count = 0;
   int count2 = 0;
   int k = 0;
   int OrderTicketMassive[50];
   int StopOrderTicketMassive[50];
   ArrayInitialize(OrderTicketMassive,0);
   ArrayInitialize(StopOrderTicketMassive,0);
   for (int t=0; t<OrdersTotal(); t++)  //���� ������ ������� ���������, ������� ������ �������
     {
      if (OrderSelect(t, SELECT_BY_POS, MODE_TRADES) == false) {Print("1-� ��������: ������, (OrderSelect)"); continue;}
      if (OrderMagicNumber() != IdNum) {Print("2-� ��������: ������, (OrderMagicNumber)"); continue;}
      if (OrderSymbol() != Symbol()) {Print("3-� ��������: ������, (OrderSymbol)"); continue;}
      if (OrderType() == OP_BUYSTOP || OrderType() == OP_SELLSTOP)
      {
       count2++;
       StopOrderTicketMassive[count2] = OrderTicket();
       Print("������ stop-�����: ����� = ", OrderTicket());
      }
      else
      {
       count++;
       OrderTicketMassive[count] = OrderTicket();
       Print("������ �����: ����� = ", OrderTicket());
      }
     }
   for (int i=1; i <= count; i++)      //���� �������� ��������� �������
     {
      OrderSelect(OrderTicketMassive[i],SELECT_BY_TICKET);
      Print("�����: ����� #", OrderTicket(), ", ��� ������=", OrderType(), ", ������=", OrderSymbol(),
            ", ���� ��������=", OrderOpenPrice(), ", ������� ��=",OrderTakeProfit(), ", ����� �����=", OrderLots(),
            ", idNum=", OrderMagicNumber(), ", �����������=", OrderComment()); 
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
        if (error == 0) {err = false; k++; Print("������ �������."); break;}
        if (error == ERR_INVALID_TICKET) break;
        else Sleep(5000);
       }
     }
   Print("���������� ��������� �������: ", k);
   for (int j=1; j <= count2; j++)      //���� �������� stop-�������
     {
      OrderSelect(StopOrderTicketMassive[j],SELECT_BY_TICKET);
      Print("����-�����: ����� #", OrderTicket(), ", ������"); 
      err = true;
      while (err == true)
       {
        OrderDelete(OrderTicket());
        error = CheckError();
        if (error == 0) {err = false; Print("������ �������."); break;}
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
       /*Print("��� ������."); */ break;
     case ERR_NO_RESULT:
       Print("��� ������, �� ��������� ���������� (��������� �� ��������)"); break;
     case ERR_COMMON_ERROR:
       Print("����� ������"); break;
     case ERR_INVALID_TRADE_PARAMETERS:
       Print("������: ������������ ���������"); break;
     case ERR_SERVER_BUSY:
       Print("������: �������� ������ �����"); break;
     case ERR_OLD_VERSION:
       Print("������: ������ ������ ����������� ���������"); break;
     case ERR_NO_CONNECTION:
       Print("������: ��� ����� � �������� ��������"); break;
     case ERR_NOT_ENOUGH_RIGHTS:
       Print("������: ������������ ����"); break;
     case ERR_TOO_FREQUENT_REQUESTS:
       Print("������: ������� ������ �������"); break;
     case ERR_MALFUNCTIONAL_TRADE:
       Print("������: ������������ �������� ���������� ���������������� �������"); break;
     case ERR_ACCOUNT_DISABLED:
       Print("������: ���� ������������"); break;
     case ERR_INVALID_ACCOUNT:
       Print("������: ������������ ����� �����"); break;
     case ERR_TRADE_TIMEOUT:
       Print("������: ����� ���� �������� ���������� ������"); break;
     case ERR_INVALID_PRICE:
       Print("������: ������������ ����"); break;
     case ERR_INVALID_STOPS:
       Print("������: ������������ �����"); break;
     case ERR_INVALID_TRADE_VOLUME:
       Print("������: ������������ �����"); break;
     case ERR_MARKET_CLOSED:
       Print("������: ����� ������"); break;
     case ERR_TRADE_DISABLED:
       Print("������: �������� ���������"); break;
     case ERR_NOT_ENOUGH_MONEY:
       Print("������: ������������ ����� ��� ���������� ��������"); break;
     case ERR_PRICE_CHANGED:
       Print("������: ���� ����������"); break;
     case ERR_OFF_QUOTES:
       Print("������: ��� ���"); break;
     case ERR_BROKER_BUSY:
       Print("������: ������ �����"); break;
     case ERR_REQUOTE:
       Print("������: ����� ����"); break;
     case ERR_ORDER_LOCKED:
       Print("������: ����� ������������ � ��� ��������������"); break;
     case ERR_LONG_POSITIONS_ONLY_ALLOWED:
       Print("������: ��������� ������ �������"); break;
     case ERR_TOO_MANY_REQUESTS:
       Print("������: ������� ����� ��������"); break;
     case ERR_TRADE_MODIFY_DENIED:
       Print("������: ����������� ���������, ��� ��� ����� ������� ������ � �����"); break;
     case ERR_TRADE_CONTEXT_BUSY:
       Print("������: ���������� �������� ������"); break;
     case ERR_TRADE_EXPIRATION_DENIED:
       Print("������: ������������� ���� ��������� ������ ��������� ��������"); break;
     case ERR_TRADE_TOO_MANY_ORDERS:
       Print("������: ���������� �������� � ���������� ������� �������� �������, �������������� ��������"); break;
     case ERR_TRADE_HEDGE_PROHIBITED:
       Print("������: ������� ������� ��������������� ������� � ��� ������������ � ������, ���� ������������ ���������"); break;
     case ERR_TRADE_PROHIBITED_BY_FIFO:
       Print("������: ������� ������� ������� �� ����������� � ������������ � �������� FIFO."); break;
     case ERR_NO_MQLERROR:
       /*Print("������: ��� ������");*/ break;
     case ERR_WRONG_FUNCTION_POINTER:
       Print("������: ������������ ��������� �������"); break;
     case ERR_ARRAY_INDEX_OUT_OF_RANGE:
       Print("������: ������ ������� - ��� ���������"); break;
     case ERR_NO_MEMORY_FOR_CALL_STACK:
       Print("������: ��� ������ ��� ����� �������"); break;
     case ERR_RECURSIVE_STACK_OVERFLOW:
       Print("������: ������������ ����� ����� ������������ ������"); break;
     case ERR_NOT_ENOUGH_STACK_FOR_PARAM:
       Print("������: �� ����� ��� ������ ��� �������� ����������"); break;
     case ERR_NO_MEMORY_FOR_PARAM_STRING:
       Print("������: ��� ������ ��� ���������� ���������"); break;
     case ERR_NO_MEMORY_FOR_TEMP_STRING:
       Print("������: ��� ������ ��� ��������� ������"); break;
     case ERR_NOT_INITIALIZED_STRING:
       Print("������: �������������������� ������"); break;
     case ERR_NOT_INITIALIZED_ARRAYSTRING:
       Print("������: �������������������� ������ � �������"); break;
     case ERR_NO_MEMORY_FOR_ARRAYSTRING:
       Print("������: ��� ������ ��� ���������� �������"); break;
     case ERR_TOO_LONG_STRING:
       Print("������: ������� ������� ������"); break;
     case ERR_REMAINDER_FROM_ZERO_DIVIDE:
       Print("������: ������� �� ������� �� ����"); break;
     case ERR_ZERO_DIVIDE:
       Print("������: ������� �� ����"); break;
     case ERR_UNKNOWN_COMMAND:
       Print("������: ����������� �������"); break;
     case ERR_WRONG_JUMP:
       Print("������: ������������ �������"); break;
     case ERR_NOT_INITIALIZED_ARRAY:
       Print("������: �������������������� ������"); break;
     case ERR_DLL_CALLS_NOT_ALLOWED:
       Print("������: ������ DLL �� ���������"); break;
     case ERR_CANNOT_LOAD_LIBRARY:
       Print("������: ���������� ��������� ����������"); break;
     case ERR_CANNOT_CALL_FUNCTION:
       Print("������: ���������� ������� �������"); break;
     case ERR_EXTERNAL_CALLS_NOT_ALLOWED:
       Print("������: ������ ������� ������������ ������� �� ���������"); break;
     case ERR_NO_MEMORY_FOR_RETURNED_STR:
       Print("������: ������������ ������ ��� ������, ������������ �� �������"); break;
     case ERR_SYSTEM_BUSY:
       Print("������: ������� ������"); break;
     case ERR_INVALID_FUNCTION_PARAMSCNT:
       Print("������: ������������ ���������� ���������� �������"); break;
     case ERR_INVALID_FUNCTION_PARAMVALUE:
       Print("������: ������������ �������� ��������� �������"); break;
     case ERR_STRING_FUNCTION_INTERNAL:
       Print("������: ���������� ������ ��������� �������"); break;
     case ERR_SOME_ARRAY_ERROR:
       Print("������: ������ �������"); break;
     case ERR_INCORRECT_SERIESARRAY_USING:
       Print("������: ������������ ������������� �������-���������"); break;
     case ERR_CUSTOM_INDICATOR_ERROR:
       Print("������: ������ ����������������� ����������"); break;
     case ERR_INCOMPATIBLE_ARRAYS:
       Print("������: ������� ������������"); break;
     case ERR_GLOBAL_VARIABLES_PROCESSING:
       Print("������: ������ ��������� ����������� ����������"); break;
     case ERR_GLOBAL_VARIABLE_NOT_FOUND:
       Print("������: ���������� ���������� �� ����������"); break;
     case ERR_FUNC_NOT_ALLOWED_IN_TESTING:
       Print("������: ������� �� ��������� � �������� ������"); break;
     case ERR_FUNCTION_NOT_CONFIRMED:
       Print("������: ������� �� ���������"); break;
     case ERR_SEND_MAIL_ERROR:
       Print("������: ������ �������� �����"); break;
     case ERR_STRING_PARAMETER_EXPECTED:
       Print("������: ��������� �������� ���� string"); break;
     case ERR_INTEGER_PARAMETER_EXPECTED:
       Print("������: ��������� �������� ���� integer"); break;
     case ERR_DOUBLE_PARAMETER_EXPECTED:
       Print("������: ��������� �������� ���� double"); break;
     case ERR_ARRAY_AS_PARAMETER_EXPECTED:
       Print("������: � �������� ��������� ��������� ������"); break;
     case ERR_HISTORY_WILL_UPDATED:
       Print("������: ����������� ������������ ������ � ��������� ����������"); break;
     case ERR_TRADE_ERROR:
       Print("������: ������ ��� ���������� �������� ��������"); break;
     case ERR_END_OF_FILE:
       Print("������: ����� �����"); break;
     case ERR_SOME_FILE_ERROR:
       Print("������: ������ ��� ������ � ������"); break;
     case ERR_WRONG_FILE_NAME:
       Print("������: ������������ ��� �����"); break;
     case ERR_TOO_MANY_OPENED_FILES:
       Print("������: ������� ����� �������� ������"); break;
     case ERR_CANNOT_OPEN_FILE:
       Print("������: ���������� ������� ����"); break;
     case ERR_INCOMPATIBLE_FILEACCESS:
       Print("������: ������������� ����� ������� � �����"); break;
     case ERR_NO_ORDER_SELECTED:
       Print("������: �� ���� ����� �� ������"); break;
     case ERR_UNKNOWN_SYMBOL:
       Print("������: ����������� ������"); break;
     case ERR_INVALID_PRICE_PARAM:
       Print("������: ������������ �������� ���� ��� �������� �������"); break;
     case ERR_INVALID_TICKET:
       Print("������: �������� ����� ������"); break;
     case ERR_TRADE_NOT_ALLOWED:
       Print("������: �������� �� ���������. ���������� �������� ����� /��������� ��������� ���������/ � ��������� ��������."); break;
     case ERR_LONGS_NOT_ALLOWED:
       Print("������: ������� ������� �� ���������. ���������� ��������� �������� ��������."); break;
     case ERR_SHORTS_NOT_ALLOWED:
       Print("������: �������� ������� �� ���������. ���������� ��������� �������� ��������."); break;
     case ERR_OBJECT_ALREADY_EXISTS:
       Print("������: ������ ��� ����������"); break;
     case ERR_UNKNOWN_OBJECT_PROPERTY:
       Print("������: ��������� ����������� �������� �������"); break;
     case ERR_OBJECT_DOES_NOT_EXIST:
       Print("������: ������ �� ����������"); break;
     case ERR_UNKNOWN_OBJECT_TYPE:
       Print("������: ����������� ��� �������"); break;
     case ERR_NO_OBJECT_NAME:
       Print("������: ��� ����� �������"); break;
     case ERR_OBJECT_COORDINATES_ERROR:
       Print("������: ������ ��������� �������"); break;
     case ERR_NO_SPECIFIED_SUBWINDOW:
       Print("������: �� ������� ��������� �������"); break;
     case ERR_SOME_OBJECT_ERROR:
       Print("������: ������ ��� ������ � ��������"); break;
     case 4250: //ERR_NOTIFICATION_SEND_ERROR
       Print("������: ������ ���������� ����������� � ������� �� �������"); break;
     case 4251:  //ERR_NOTIFICATION_WRONG_PARAMETER
       Print("������: �������� �������� - � ������� SendNotification() �������� ������ ������"); break;
     case 4252:  //ERR_NOTIFICATION_WRONG_SETTINGS
       Print("������: �������� ��������� ��� �������� ����������� (�� ������ ID ��� �� ���������� ����������"); break;
     case 4253:  //ERR_NOTIFICATION_TOO_FREQUENT
       Print("������: ������� ������ �������� �����������"); break;
     default:
       Print("������: �� ��������, ���������� �� ��������, #", Error); break;
    }
   return(Error); 
  }

