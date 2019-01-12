//+------------------------------------------------------------------+
//|                                                   Marketinfo.mq4 |
//|                                           Copyright 2013, GlobuX |
//|                                              http://globux.ya.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, GlobuX"
#property link      "http://globux.ya.ru"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   Print("Symbol=",Symbol());
   Print("����������� ������� ����=",MarketInfo(Symbol(),MODE_LOW));
   Print("������������ ������� ����=",MarketInfo(Symbol(),MODE_HIGH));
   Print("����� ����������� ��������� ���������=",(MarketInfo(Symbol(),MODE_TIME)));
   Print("��������� ����������� ���� �����������=",MarketInfo(Symbol(),MODE_BID));
   Print("��������� ����������� ���� �������=",MarketInfo(Symbol(),MODE_ASK));
   Print("������ ������ � ������ ���������=",MarketInfo(Symbol(),MODE_POINT));
   Print("���������� ���� ����� ������� � ���� �����������=",MarketInfo(Symbol(),MODE_DIGITS));
   Print("����� � �������=",MarketInfo(Symbol(),MODE_SPREAD));
   Print("���������� ���������� ������� ����-�����/����-������� � �������=",MarketInfo(Symbol(),MODE_STOPLEVEL));
   Print("������ ��������� � ������� ������ �����������=",MarketInfo(Symbol(),MODE_LOTSIZE));
   Print("������ ������������ ��������� ���� ����������� � ������ ��������=",MarketInfo(Symbol(),MODE_TICKVALUE));
   Print("����������� ��� ��������� ���� ����������� � �������=",MarketInfo(Symbol(),MODE_TICKSIZE)); 
   Print("������ ����� ��� ������� �������=",MarketInfo(Symbol(),MODE_SWAPLONG));
   Print("������ ����� ��� �������� �������=",MarketInfo(Symbol(),MODE_SWAPSHORT));
   Print("����������� ���� ������ ������ (��������)=",MarketInfo(Symbol(),MODE_STARTING));
   Print("����������� ���� ��������� ������ (��������)=",MarketInfo(Symbol(),MODE_EXPIRATION));
   Print("���������� ������ �� ���������� �����������=",MarketInfo(Symbol(),MODE_TRADEALLOWED));
   Print("����������� ������ ����=",MarketInfo(Symbol(),MODE_MINLOT));
   Print("��� ��������� ������� ����=",MarketInfo(Symbol(),MODE_LOTSTEP));
   Print("������������ ������ ����=",MarketInfo(Symbol(),MODE_MAXLOT));
   Print("����� ���������� ������=",MarketInfo(Symbol(),MODE_SWAPTYPE));
   Print("������ ������� �������=",MarketInfo(Symbol(),MODE_PROFITCALCMODE));
   Print("������ ������� ��������� �������=",MarketInfo(Symbol(),MODE_MARGINCALCMODE));
   Print("��������� ��������� ���������� ��� 1 ����=",MarketInfo(Symbol(),MODE_MARGININIT));
   Print("������ ��������� ������� ��� ��������� �������� ������� � ������� �� 1 ���=",MarketInfo(Symbol(),MODE_MARGINMAINTENANCE));
   Print("�����, ��������� � ���������� ������� � ������� �� 1 ���=",MarketInfo(Symbol(),MODE_MARGINHEDGED));
   Print("������ ��������� �������, ����������� ��� �������� 1 ���� �� �������=",MarketInfo(Symbol(),MODE_MARGINREQUIRED));
   Print("������� ��������� ������� � �������=",MarketInfo(Symbol(),MODE_FREEZELEVEL)); 
  }
//+------------------------------------------------------------------+
