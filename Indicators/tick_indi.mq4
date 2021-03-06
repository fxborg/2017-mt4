//+------------------------------------------------------------------+
//|                                                    tick_indi.mq4 |
//| Tick Indicator                            Copyright 2017, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.0"
#property strict

//---
#property indicator_separate_window
#property indicator_buffers 2

#property indicator_color1 clrRed   // 
#property indicator_type1 DRAW_LINE
#property indicator_width1 1
#property indicator_color2 clrBlue   // 
#property indicator_type2 DRAW_LINE
#property indicator_width2 1

//--- input parameter
#include <socket-library-mt4-mt5.mqh>

input string   Hostname="192.168.179.4";    // Server hostname or IP address
input ushort   ServerPort=8181; // Server port
input string   ServerURI="/api/query"; // URL
input string   TimeFrom="20171027T213000"; // Time From
input string   TimeTo="20171027T220000"; // Time to
input string Instruments ="USDJPY"; // Instruments
double BID[];
double ASK[];
double work[][2];
int WK_BID=0;
int WK_ASK=1;
int WK_SZ=0;
// --------------------------------------------------------------------
// Global variables and constants
// --------------------------------------------------------------------
ClientSocket*glbClientSocket=NULL;

//---
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

   SetIndexBuffer(0,BID);
   SetIndexEmptyValue(0,EMPTY_VALUE);
   SetIndexBuffer(1,ASK);
   SetIndexEmptyValue(0,EMPTY_VALUE);
   
   EventSetTimer(1);
   return(INIT_SUCCEEDED);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
   if(!glbClientSocket)
     {
      glbClientSocket=new ClientSocket(Hostname,ServerPort);
      if(glbClientSocket.IsSocketConnected())
        {
         Print("Client connection succeeded");
        } else {
         Print("Client connection failed");
        }
     }

   if(glbClientSocket.IsSocketConnected())
     {

      MqlTick last_tick;
      //---
      if(SymbolInfoTick(Symbol(),last_tick))
        {
         long from=1000000000*(long(TimeFrom));
         long to=  1000000000*(long(TimeTo));
         string body="";
         StringAdd(body,"{\"join\":[\"tick.bid\",\"tick.ask\"],");
         StringAdd(body,"\"range\": {");
         StringAdd(body,"\"from\": \""+TimeFrom+".000000000\",");
         StringAdd(body,"\"to\":   \""+TimeTo+".000000000\"");
         StringAdd(body,"},");
         StringAdd(body,"\"where\": {");
         StringAdd(body,"\"host\": [\"tradeview\"],");
         StringAdd(body,"\"indicator\": [\"tick\"],");
         StringAdd(body,"\"instruments\": [\""+Instruments+"\"]");
         StringAdd(body,"},");
         StringAdd(body,"\"order-by\": \"series\",");
         StringAdd(body,"\"output\": {\"format\": \"csv\"}}");
         int sz=StringLen(body);
         string req="";
         StringAdd(req,"POST "+ ServerURI +" HTTP/1.1\r\n");
         StringAdd(req,"Host: " + Hostname + ":" +IntegerToString(ServerPort)+"\r\n");
         StringAdd(req,"Content-Type: application/json; charset=utf-8\r\n");
         StringAdd(req,"Content-Length: "+IntegerToString(sz)+"\r\n\r\n");
         StringAdd(req,body+"\r\n");
         if(glbClientSocket.Send(req))
         {
            string result=glbClientSocket.Receive();
            if(StringLen(result)>0)
            {            
               EventKillTimer();
               string lines[];
               int line_sz = StringSplit(result,StringGetCharacter("\n",0),lines);
               ArrayResize(work,0,line_sz);
               int work_sz=0;
               string from_time="";
               string to_time="";
               for(int i=0;i<line_sz;i++)
               {
                  string cols[];
                  int col_sz = StringSplit(lines[i],StringGetCharacter(",",0),cols);
                  if(col_sz==4){
                     if(work_sz==0)from_time = cols[1];
                     to_time = cols[1];
                     work_sz++;
                     ArrayResize(work,work_sz,line_sz);
                     work[work_sz-1][WK_BID]=StringToDouble(cols[2]); //Bid                     
                     work[work_sz-1][WK_ASK]=StringToDouble(cols[3]); //Ask                    
                  }
               }
                  int total=ArraySize(BID);
                  ArrayFill(BID,0,total,EMPTY_VALUE);
                  ArrayFill(ASK,0,total,EMPTY_VALUE);
                  int i=0;
                  
                  for(int w=work_sz-1;w>=0;w--)
                  {
                     if(i>=total-1)break;
                     BID[i]=work[w][WK_BID];
                     ASK[i]=work[w][WK_ASK];
                     i++;
                  }
                  Print("From:",from_time," To:",to_time," (",work_sz," ticks)" );
            }
            
         }    
        }

     }

// If the socket is closed, destroy it, and attempt a new connection
// on the next call to OnTick()

   if(!glbClientSocket.IsSocketConnected())
     {
      // Destroy the server socket. A new connection
      // will be attempted on the next tick
      Print("Client disconnected. Will retry.");
      delete glbClientSocket;
      glbClientSocket=NULL;
  
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
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

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| De-initialization                                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(glbClientSocket)
     {
      delete glbClientSocket;
      glbClientSocket=NULL;
     }
  }
//+------------------------------------------------------------------+
