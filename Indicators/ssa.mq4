//+------------------------------------------------------------------+
//|                                                          ssa.mq4 |
//| SSA Trend                                 Copyright 2017, fxborg |
//| this is a c++ reimplementation of AutoSSA Matlab package         |
//| AutoSSA(http://www.pdmi.ras.ru/~theo/autossa/english/soft.htm)   |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.0"
#property strict

//---
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_level1     1.5

#property indicator_color1 clrRed   // 

#property indicator_type1 DRAW_LINE

#property indicator_width1 2

//--- input parameter
input int N = 1000;
input int L = 120;
input double omega0=0.01;
input int max_ET=32;
double c0step=0.05;

//--- buffers
//--- i, q, Hq, tq, dq, hq))
#import "ssa.dll"
int Create(int,int,double,int,double);
int Push(int,int,double,datetime,datetime);//
int Calculate(int); // 
void Destroy(int); // 
bool GetResults(int,int,double &v); // 
#import


//--- 
int instance;
double TREND[];
//---
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

   SetIndexBuffer(0,TREND);
   SetIndexEmptyValue(0,EMPTY_VALUE);
   instance=Create(N,L,omega0,max_ET,c0step); //インスタンスを生成
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| De-initialization                                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0);
   Destroy(instance); //インスタンスを破棄
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {

   if(ArrayGetAsSeries(close))ArraySetAsSeries(close,false);
   if(ArrayGetAsSeries(time))ArraySetAsSeries(time,false);
   if(ArrayGetAsSeries(TREND))ArraySetAsSeries(TREND,false);

   for(int i=(int)MathMax(prev_calculated-1,0);i<rates_total && !IsStopped();i++)
     {
      TREND[i]=EMPTY_VALUE;
      datetime prev=(i>0) ? time[i-1]: 0;
      int n= Push(instance,i,close[i],time[i],prev);
      if(n == -1 )continue;
      if(n == -9999)
        {
         Print(i," ",time[i]);
         Print(n," ------------- Reset --------------- ",time[i]);
         Destroy(instance); //インスタンスを破棄
         instance=Create(N,L,omega0,max_ET,c0step);  //インスタンスを生成
         return 0;
        }
      if(i<=rates_total-10)continue;
      if(i<=N)continue;
      int sz=Calculate(instance);
     
      for(int j=0;j<sz;j++)
        {
         double y;
         if(GetResults(instance,j,y)) TREND[i-(sz-j)]=y;
         else TREND[i-(sz-j)]=EMPTY_VALUE;
        }
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
