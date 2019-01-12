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
   Print("Минимальная дневная цена=",MarketInfo(Symbol(),MODE_LOW));
   Print("Максимальная дневная цена=",MarketInfo(Symbol(),MODE_HIGH));
   Print("Время поступления последней котировки=",(MarketInfo(Symbol(),MODE_TIME)));
   Print("Последняя поступившая цена предложения=",MarketInfo(Symbol(),MODE_BID));
   Print("Последняя поступившая цена продажи=",MarketInfo(Symbol(),MODE_ASK));
   Print("Размер пункта в валюте котировки=",MarketInfo(Symbol(),MODE_POINT));
   Print("Количество цифр после запятой в цене инструмента=",MarketInfo(Symbol(),MODE_DIGITS));
   Print("Спрэд в пунктах=",MarketInfo(Symbol(),MODE_SPREAD));
   Print("Минимально допустимый уровень стоп-лосса/тейк-профита в пунктах=",MarketInfo(Symbol(),MODE_STOPLEVEL));
   Print("Размер контракта в базовой валюте инструмента=",MarketInfo(Symbol(),MODE_LOTSIZE));
   Print("Размер минимального изменения цены инструмента в валюте депозита=",MarketInfo(Symbol(),MODE_TICKVALUE));
   Print("Минимальный шаг изменения цены инструмента в пунктах=",MarketInfo(Symbol(),MODE_TICKSIZE)); 
   Print("Размер свопа для длинных позиций=",MarketInfo(Symbol(),MODE_SWAPLONG));
   Print("Размер свопа для коротких позиций=",MarketInfo(Symbol(),MODE_SWAPSHORT));
   Print("Календарная дата начала торгов (фьючерсы)=",MarketInfo(Symbol(),MODE_STARTING));
   Print("Календарная дата окончания торгов (фьючерсы)=",MarketInfo(Symbol(),MODE_EXPIRATION));
   Print("Разрешение торгов по указанному инструменту=",MarketInfo(Symbol(),MODE_TRADEALLOWED));
   Print("Минимальный размер лота=",MarketInfo(Symbol(),MODE_MINLOT));
   Print("Шаг изменения размера лота=",MarketInfo(Symbol(),MODE_LOTSTEP));
   Print("Максимальный размер лота=",MarketInfo(Symbol(),MODE_MAXLOT));
   Print("Метод вычисления свопов=",MarketInfo(Symbol(),MODE_SWAPTYPE));
   Print("Способ расчета прибыли=",MarketInfo(Symbol(),MODE_PROFITCALCMODE));
   Print("Способ расчета залоговых средств=",MarketInfo(Symbol(),MODE_MARGINCALCMODE));
   Print("Начальные залоговые требования для 1 лота=",MarketInfo(Symbol(),MODE_MARGININIT));
   Print("Размер залоговых средств для поддержки открытых позиций в расчете на 1 лот=",MarketInfo(Symbol(),MODE_MARGINMAINTENANCE));
   Print("Маржа, взимаемая с перекрытых позиций в расчете на 1 лот=",MarketInfo(Symbol(),MODE_MARGINHEDGED));
   Print("Размер свободных средств, необходимых для открытия 1 лота на покупку=",MarketInfo(Symbol(),MODE_MARGINREQUIRED));
   Print("Уровень заморозки ордеров в пунктах=",MarketInfo(Symbol(),MODE_FREEZELEVEL)); 
  }
//+------------------------------------------------------------------+
