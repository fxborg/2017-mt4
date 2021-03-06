//+------------------------------------------------------------------+
//|                                                    ssa_slope.mq4 |
//| SSA Slope                                 Copyright 2017, fxborg |
//| this is a c++ reimplementation of AutoSSA Matlab package         |
//| AutoSSA(http://www.pdmi.ras.ru/~theo/autossa/english/soft.htm)   |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.0"
#property strict

//---
#property indicator_separate_window
#property indicator_buffers 2

#property indicator_color1 clrDodgerBlue 
#property indicator_color2 clrRed 

#property indicator_type1 DRAW_HISTOGRAM
#property indicator_type2 DRAW_HISTOGRAM

#property indicator_width1 2
#property indicator_width2 2

//--- input parameter
input int Slope_Period = 8;
input int N = 400;
input int L = 120;
input double omega0=0.01;
input int max_ET=32;
double c0step=0.01;

//--- buffers
//--- i, q, Hq, tq, dq, hq))
#import "ssa.dll"
int Create(int,int,double,int,double);
int Push(int,int,double,datetime,datetime);//
int Calculate(int); // 
void Destroy(int); // 
bool GetResults(int,int,double &v); // 
double Slope(int,int); // 
#import


//--- 
int instance;
double SLOPE_P[];
double SLOPE_N[];
//---
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

   SetIndexBuffer(0,SLOPE_P);
   SetIndexBuffer(1,SLOPE_N);
   SetIndexEmptyValue(0,EMPTY_VALUE);
   SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexEmptyValue(2,EMPTY_VALUE);
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
   if(ArrayGetAsSeries(SLOPE_P))ArraySetAsSeries(SLOPE_P,false);
   if(ArrayGetAsSeries(SLOPE_N))ArraySetAsSeries(SLOPE_N,false);

   for(int i=(int)MathMax(prev_calculated-1,0);i<rates_total && !IsStopped();i++)
     {
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

      if(i<=rates_total-(Slope_Period))continue;
      if(i<=N)continue;
      int sz=Calculate(instance);
         
      double slope=Slope(instance,Slope_Period);
      
    
           
      SLOPE_P[i-1]= slope>=0 ? slope :EMPTY_VALUE;
      SLOPE_N[i-1]= slope<0 ? slope :EMPTY_VALUE;
      
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
