//+------------------------------------------------------------------+
//|                                            SimpleAutoTL_v2_3.mq4 |
//|SimpleAutoTL v2.3                          Copyright 2017, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "2.3"
#property strict
#include <Arrays\ArrayInt.mqh>

#property indicator_chart_window
#property indicator_buffers 11
#property indicator_plots   2
//--- plot Label1

#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrRed
#property indicator_width1  2

#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrDodgerBlue
#property indicator_width2  2


CArrayInt *HighCache[];
CArrayInt *LowCache[];

//---

#define WK_BUFF_SZ 8
#define WK_UP_SIG 0
#define WK_DN_SIG 1
#define WK_UP_A 2
#define WK_UP_B 3
#define WK_DN_A 4
#define WK_DN_B 5
#define WK_DN_BTM 6
#define WK_UP_TOP 7

//---
double wk[][WK_BUFF_SZ];
//---

//--- input parameters
input int InpFastPeriod=20;           // Fast Period
input int InpHiLoPeriod=60;           // HiLo Period
input double InpLimitSize=1.0;        // Limit Size 
double InpXScale=0.3;           //   X Scale
double InpYScale=0.15;           //   Y Scale
int InpMaxBars=1000;            // MaxBars
//---

datetime BarTime=0;
//--- indicator buffers
double ZZ[];
double UP[];
double DN[];
double HI[];
double LO[];
double HI2[];
double LO2[];

double UPPER_X[];
double LOWER_X[];
double UPPER[];
double LOWER[];

double LATR[];
int LAtrPeriod=100;
double LAtrAlpha=2.0/(LAtrPeriod+1.0);

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   IndicatorBuffers(11);
//--- indicator buffers mapping
   SetIndexBuffer(0,UP);
   SetIndexBuffer(1,DN);
   SetIndexBuffer(2,LATR);
   SetIndexBuffer(3,HI);
   SetIndexBuffer(4,LO);
   SetIndexBuffer(5,UPPER_X);
   SetIndexBuffer(6,LOWER_X);
   SetIndexBuffer(7,HI2);
   SetIndexBuffer(8,LO2);
   SetIndexBuffer(9,UPPER);
   SetIndexBuffer(10,LOWER);

   SetIndexArrow(0,158);
   SetIndexArrow(1,158);

   SetIndexEmptyValue(0,EMPTY_VALUE);
   SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexEmptyValue(2,0.0);

//---
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| De-initialization                                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   int sz1=ArraySize(HighCache);
   for(int i=0;i<sz1;i++) delete HighCache[i];
   int sz2=ArraySize(LowCache);
   for(int i=0;i<sz2;i++) delete LowCache[i];


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

   if(ArrayGetAsSeries(UP))ArraySetAsSeries(UP,false);
   if(ArrayGetAsSeries(DN))ArraySetAsSeries(DN,false);
   if(ArrayGetAsSeries(ZZ))ArraySetAsSeries(ZZ,false);
   if(ArrayGetAsSeries(LATR))ArraySetAsSeries(LATR,false);
   if(ArrayGetAsSeries(high))ArraySetAsSeries(high,false);
   if(ArrayGetAsSeries(low))ArraySetAsSeries(low,false);
   if(ArrayGetAsSeries(close))ArraySetAsSeries(close,false);

   if(ArrayGetAsSeries(HI))ArraySetAsSeries(HI,false);
   if(ArrayGetAsSeries(LO))ArraySetAsSeries(LO,false);
   if(ArrayGetAsSeries(HI2))ArraySetAsSeries(HI2,false);
   if(ArrayGetAsSeries(LO2))ArraySetAsSeries(LO2,false);
   if(ArrayGetAsSeries(UPPER_X))ArraySetAsSeries(UPPER_X,false);
   if(ArrayGetAsSeries(LOWER_X))ArraySetAsSeries(LOWER_X,false);
   if(ArrayGetAsSeries(UPPER))ArraySetAsSeries(UPPER,false);
   if(ArrayGetAsSeries(LOWER))ArraySetAsSeries(LOWER,false);

//---

   if(ArrayRange(wk,0)!=rates_total)ArrayResize(wk,rates_total);
   else return (rates_total);
   if(ArraySize(HighCache)!=rates_total) ArrayResize(HighCache,rates_total);
   if(ArraySize(LowCache)!=rates_total) ArrayResize(LowCache,rates_total);

//---
   if(prev_calculated==0)
   {
      ArrayInitialize(LATR,0.0);
   }
//---
   for(int i=(int)MathMax(prev_calculated-1,0); i<rates_total && !IsStopped(); i++)
     {
      //---
      UP[i]=EMPTY_VALUE;
      DN[i]=EMPTY_VALUE;
      LATR[i]=0;
      double atr0 = (i==0) ? high[i]-low[i] : fmax(high[i],close[i-1])-fmin(low[i],close[i-1]);
      double atr1 = (i==0 || LATR[i-1]==0.0||LATR[i-1]==EMPTY_VALUE) ? atr0 :LATR[i-1];
      atr0=fmax(atr1*0.667,fmin(atr0,atr1*1.333));
      LATR[i]=LAtrAlpha*atr0+(1.0-LAtrAlpha)*atr1;

      if(rates_total-1==i) continue;
      //---
      if(HighCache[i]==NULL)HighCache[i]=new CArrayInt();
      if(LowCache[i]==NULL)LowCache[i]=new CArrayInt();
      if(i>0)
        {
         HighCache[i].AssignArray(HighCache[i-1]);
         LowCache[i].AssignArray(LowCache[i-1]);
         copyFowardWK(i);

        }
      
      //---
      if(i<=fmax(InpHiLoPeriod,InpFastPeriod)+1)continue;
      //---
      LO[i]=low[ArrayMinimum(low,InpHiLoPeriod,i-(InpHiLoPeriod-1))];
      HI[i]=high[ArrayMaximum(high,InpHiLoPeriod,i-(InpHiLoPeriod-1))];

      LO2[i]=low[ArrayMinimum(low,InpFastPeriod,i-(InpFastPeriod-1))];
      HI2[i]=high[ArrayMaximum(high,InpFastPeriod,i-(InpFastPeriod-1))];

      if(HI[i-1]==EMPTY_VALUE)continue;

      UPPER[i]=(HI[i]>HI[i-1])? HI[i]:UPPER[i-1];
      LOWER[i]=(LO[i]<LO[i-1])? LO[i]:LOWER[i-1];
      UPPER_X[i]=(HI[i]>HI[i-1])? i:UPPER_X[i-1];
      LOWER_X[i]=(LO[i]<LO[i-1])? i:LOWER_X[i-1];

      //---
      if(HI[i]>HI[i-1]) HighCache[i].Clear();
      HighCache[i].Add(i);
      //---
      if(LO[i]<LO[i-1]) LowCache[i].Clear();
      LowCache[i].Add(i);
      //---
      if(i<rates_total-InpMaxBars)continue;

      //---


      //---
      double xScale=LATR[i]*InpXScale;
      double yScale=LATR[i]*InpYScale;
               
      double limitSize=InpLimitSize*LATR[i];
      int upper_x=(int)UPPER_X[i];
      int lower_x=(int)LOWER_X[i];
      if(i==lower_x)
      {
        wk[i][WK_UP_SIG]=0.0;
      }
      if(i==upper_x)
      {
        wk[i][WK_DN_SIG]=0.0;
      }


      if(i-lower_x>3 )
        {
         if(HI2[i]==high[i])
           {
            double lower[][2];
            //update
            convex_lower(lower,low,LowCache[i]);

            int sz=int(ArraySize(lower)*0.5);
            if(sz>1)
              {
               //---
               LowCache[i].Clear();
               for(int j=0;j<sz;j++) LowCache[i].Add((int)lower[j][0]);
               //---
               double best_d=0;
               int best=0;
               
               for(int j=0;j<sz-1;j++)
                 {
                  double d=dimension_up(lower[j][0],lower[j][1],lower[j+1][0],lower[j+1][1],LOWER[i],i,xScale);
                  if(d>best_d ) {  best=j; best_d=d; }
                 }
               if(best_d>0)
                 {

                  double x1=lower[best][0];
                  double y1=lower[best][1];
                  double x2=lower[best+1][0];
                  double y2=lower[best+1][1];
                  double a= (y2-y1)/(x2-x1);
                  if(a > yScale)a=yScale;
                  double b=y1-a*x1;   //b=y-ax			
                  wk[i][WK_UP_A]=a;
                  wk[i][WK_UP_B]=b;
                  wk[i][WK_UP_TOP]=i;
                  wk[i][WK_UP_SIG]=1.0;
                                 
                  DN[i]=y2;
                 }
               //---
              }

           }

         if(wk[i][WK_UP_SIG]==1.0 )
           {
   
            double top=high[(int)wk[i][WK_UP_TOP]];
            double a=wk[i][WK_UP_A];
            double b=wk[i][WK_UP_B];
            double tl=a*i+b;
            if(close[i-2]>top || tl-limitSize>close[i-2]) 
            {
             wk[i][WK_UP_SIG]=0.0;
             wk[i][WK_UP_A]=0.0;
            }
            else DN[i]=tl;   
            
           }

        }

   
      if(i-upper_x>3)
        {
         if(LO2[i]==low[i])
           {
            double upper[][2];

            // update tl
            convex_upper(upper,high,HighCache[i]);
            int sz=int(ArraySize(upper)*0.5);
            if(sz>1)
              {
               //---
               HighCache[i].Clear();
               for(int j=0;j<sz;j++)HighCache[i].Add((int)upper[j][0]);

               //---
               double best_d=0;
               int best=0;
               for(int j=0;j<sz-1;j++)
                 {
                  double d=dimension_dn(upper[j][0],upper[j][1],upper[j+1][0],upper[j+1][1],UPPER[i],i,xScale);
                  if(d>best_d ) { best=j;best_d=d;   }
                 }
               if( best_d>0)
                 {
                  double x1=upper[best][0];
                  double y1=upper[best][1];
                  double x2=upper[best+1][0];
                  double y2=upper[best+1][1];
                  double a= (y2-y1)/(x2-x1);
                  if(a < -yScale)a=-yScale;
                  double b=y1-a*x1;   //b=y-ax			
                  wk[i][WK_DN_A]=a;
                  wk[i][WK_DN_B]=b;
                  wk[i][WK_DN_SIG]=1.0;
                  wk[i][WK_DN_BTM]=i;
                  UP[i]=y2;
                 }
              }

           }

         if(wk[i][WK_DN_SIG]==1.0 &&wk[i][WK_DN_A]<0.0)
        {
         double btm=low[(int)wk[i][WK_DN_BTM]];
         double a=wk[i][WK_DN_A];
         double b=wk[i][WK_DN_B];
         double tl=a*i+b;
         if(close[i-2]<btm || tl+limitSize<close[i-2])
         {
           wk[i][WK_DN_SIG]=0.0;
           wk[i][WK_DN_A]=0.0;
         }
         else UP[i]=tl;
        }

     }
      //---

     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void copyFowardWK(const int i)
  {
   if(i<1)return;
   for(int j=0;j<WK_BUFF_SZ;j++) wk[i][j]=wk[i-1][j];
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double alpha(double x1,double y1,double x2,double  y2)
  {
   if(x1>=x2 )return 0.0;
   return (y2-y1)/(x2-x1);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double dimension_dn(double x1,double y1,double x2,double  y2,double top,double i,double xfacter)
  {
   if(x1>=x2 || y1<=y2)return 0.0;
   double a= (y2-y1)/(x2-x1);
   double b=y1-a*x1;   //b=y-ax
   double x0=(top-b)/a;  //x=(y-b)/a
   double y3 = a*i+b;    //y=ax+b  
   return xfacter*(i-x0)*(top-y3);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double dimension_up(double x1,double y1,double x2,double  y2,double btm,double i,double xfacter)
  {
   if(x1>=x2 || y1>=y2)return 0.0;
   double a= (y2-y1)/(x2-x1);
   double b=y1-a*x1;   //b=y-ax
   double x0=(btm-b)/a;  //x=(y-b)/a
   double y3 = a*i+b;    //y=ax+b  
   return xfacter*(i-x0)*(y3-btm);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void convex_upper(double &upper[][2],const double &high[],CArrayInt *arr)
  {
   int len=arr.Total();

   ArrayResize(upper,len,len);
   int k=0;
   for(int j=0;j<len;j++)
     {

      while(k>=2 && 
            (
            cross(
            upper[k-2][0],upper[k-2][1],
            upper[k-1][0],upper[k-1][1],
            arr.At(j),high[arr.At(j)])
            )>=0)
        {
         k--;
        }

      upper[k][0]= arr.At(j);
      upper[k][1]= high[arr.At(j)];
      k++;
     }
   ArrayResize(upper,k,len);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void convex_lower(double &lower[][2],const double &low[],CArrayInt *arr)
  {
   int len=arr.Total();
   ArrayResize(lower,len,len);
   int k=0;
   for(int j=0;j<len;j++)
     {
      while(k>=2 && 
            (
            cross(
            lower[k-2][0],lower[k-2][1],
            lower[k-1][0],lower[k-1][1],
            arr.At(j),low[arr.At(j)]))<=0)
        {
         k--;
        }

      lower[k][0]= arr.At(j);
      lower[k][1]= low[arr.At(j)];
      k++;
     }
   ArrayResize(lower,k,len);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double cross(const double ox,double oy,
             const double ax,double ay,
             const double bx,double by)
  {
   return ((ax - ox) * (by - oy) - (ay - oy) * (bx - ox));
  }
//+------------------------------------------------------------------+
