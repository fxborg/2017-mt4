//+------------------------------------------------------------------+
//|                                                          SnR.mq4 |
//| Support & Registance                      Copyright 2017, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.0"
#property strict

#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   2
//--- plot Label1

#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrRed
#property indicator_width1  1

#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrDodgerBlue
#property indicator_width2  1

input double InpSize1=0.4;             // Damashi Size
input double InpSize2=1.0;             // Modoshi Size
input double InpSize3=2.0;             // Minimum Range Size
input double InpSize4=6.0;             // Maximum Range Size
input int InpPeriod=30;                // Channel Period
input int InpLookBack=120;             // LookBack
double SUP[];
double REG[];
double ATR[];
int AtrPeriod=50;
double AtrAlpha=2.0/(AtrPeriod+1.0);
//---


#define WK_BUFF_SZ 8
#define WK_H 0
#define WK_L 1
#define WK_C 2
#define WK_UP 3
#define WK_DN 4
#define WK_UP2 5
#define WK_DN2 6
#define WK_FLG 7

//---
double wk[][WK_BUFF_SZ];
//---
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

   SetIndexBuffer(0,REG);
   SetIndexBuffer(1,SUP);
   SetIndexBuffer(2,ATR);

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


   if(ArrayGetAsSeries(SUP))ArraySetAsSeries(SUP,false);
   if(ArrayGetAsSeries(REG))ArraySetAsSeries(REG,false);
   if(ArrayGetAsSeries(ATR))ArraySetAsSeries(ATR,false);
   if(ArrayGetAsSeries(close))ArraySetAsSeries(close,false);
   if(ArrayGetAsSeries(open))ArraySetAsSeries(open,false);
   if(ArrayGetAsSeries(high))ArraySetAsSeries(high,false);
   if(ArrayGetAsSeries(low))ArraySetAsSeries(low,false);

//---

   if(ArrayRange(wk,0)!=rates_total)ArrayResize(wk,rates_total);
   else return (rates_total);

//---
   if(prev_calculated==0)
   {
      ArrayInitialize(ATR,0.0);
   }
//---
   for(int i=(int)MathMax(prev_calculated-1,0); i<rates_total && !IsStopped(); i++)
     {
      SUP[i]=EMPTY_VALUE;
      REG[i]=EMPTY_VALUE;
      ATR[i]=0;
      double atr0 = (i==0) ? high[i]-low[i] : fmax(high[i],close[i-1])-fmin(low[i],close[i-1]);
      double atr1 = (i==0 || ATR[i-1]==0.0||ATR[i-1]==EMPTY_VALUE) ? atr0 :ATR[i-1];
      atr0=fmax(atr1*0.667,fmin(atr0,atr1*1.333));
      ATR[i]=AtrAlpha*atr0+(1.0-AtrAlpha)*atr1;

      if(i<=InpPeriod)continue;
      double hmax=high[ArrayMaximum(high,i-(InpPeriod-1),InpPeriod)];
      double lmin=low[ArrayMinimum(low,i-(InpPeriod-1),InpPeriod)];
      double size1 = InpSize1*ATR[i];
      double size2 = InpSize2*ATR[i];
      double size3 = InpSize3*ATR[i];
      double size4 = InpSize4*ATR[i];

      calcSnR(REG,SUP,high[i],low[i],close[i],hmax,lmin,
              size1,size2,size3,size4,InpPeriod,InpLookBack,i,rates_total);


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
void calcSnR(double &reg[],double &sup[],double h0,double l0,double c0,double max0,double min0,
             double size1,double size2,double size3,double size4,int period,int lookback,int r,int bars)
  {

   if(ArrayRange(wk,0)!=bars) ArrayResize(wk,bars);
   wk[r][WK_H]=h0;
   wk[r][WK_L]=l0;
   wk[r][WK_C]=c0;
   if(r<=period+1)
     {
      wk[r][WK_FLG]=0.0;
      wk[r][WK_UP ]=max0;
      wk[r][WK_DN ]=min0;
      wk[r][WK_UP2]=max0;
      wk[r][WK_DN2]=min0;
     }
   else
     {
      wk[r][WK_FLG]=wk[r-1][WK_FLG];
      wk[r][WK_UP ]=wk[r-1][WK_UP ];
      wk[r][WK_DN ]=wk[r-1][WK_DN ];
      wk[r][WK_UP2]=wk[r-1][WK_UP2];
      wk[r][WK_DN2]=wk[r-1][WK_DN2];
     }
   int back=fmin(lookback,r-1);
   double c1=wk[r-1][WK_C];
   double flg=wk[r][WK_FLG];
   double up =  wk[r][WK_UP];
   double dn =  wk[r][WK_DN];
   double up2 =  wk[r][WK_UP2];
   double dn2 =  wk[r][WK_DN2];
//+-------------------------------------------------+
//| update range 
//+-------------------------------------------------+
   if(h0 > up2)               { wk[r][WK_UP2] = h0;}
   if(l0 < dn2)               { wk[r][WK_DN2] = l0;}
//+-------------------------------------------------+
//| expand
//+-------------------------------------------------+
   if(flg==-1.0 && c0>dn2+size2)
     {
      wk[r][WK_FLG]=0.0;
      if(up-dn2>size4)
        {
         if(dn-dn2>size3 && dn>fmax(h0,c1))
           {
            wk[r][WK_UP]=dn;
            wk[r][WK_UP2]=dn;
           }
         else
           {
            double y=h0;

            for(int j=0;j<back;j++)
              {
               if(wk[r-j][WK_H]>y) y=wk[r-j][WK_H];
               if(up<y)break;
               if(y-dn2>size2 && wk[r-j][WK_H]<y-size2)
                 {
                  wk[r][WK_UP]=y;
                  wk[r][WK_UP2]=y;
                  break;
                 }
              }
           }
        }
      wk[r][WK_DN]=dn2;

     }
   if(flg==1.0 && c0<up2-size2)
     {
      wk[r][WK_FLG]=0.0;
      if(up2-dn>size4)
        {

         if(up2-up>size3 && up<fmin(l0,c1))
           {
            wk[r][WK_DN] =up;
            wk[r][WK_DN2]=up;
           }
         else
           {
            double y=l0;
            for(int j=0;j<back;j++)
              {
               if(wk[r-j][WK_L]<y) y=wk[r-j][WK_L];
               if(dn>y)break;
               if(up2-y>size2 && wk[r-j][WK_L]>y+size2)
                 {
                  wk[r][WK_DN]=y;
                  wk[r][WK_DN2]=y;
                  break;
                 }
              }
           }
        }
      wk[r][WK_UP]=up2;

     }

   if(up-dn>(max0-min0)*2.0)
     {
      wk[r][WK_UP]=max0;
      wk[r][WK_UP2]=max0;
      wk[r][WK_DN]=min0;
      wk[r][WK_DN2]=min0;
     }

   if(h0>up+size1) { wk[r][WK_FLG] = 1.0;  }
   if(l0<dn-size1) { wk[r][WK_FLG] =-1.0;  }

   reg[r]=up;
   sup[r]=dn;

  }
//+------------------------------------------------------------------+
