//+------------------------------------------------------------------+
//|                                               MQLPostRequest.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property strict
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
#define  APIhost "127.0.0.1"
#define  APIport "8008"
#define  APIendpoint "/trades/report/"
#define RequestHeader "Content-Type: application/json"

//---Helper: gnerate ISO timestamp
string BuildISOTimestamp(datetime time)
{
   MqlDateTime dt;
   TimeToStruct(time, dt);
   return StringFormat("%04d-%02d-%02dT%02d:%02d:%02dZ",
                       dt.year, dt.mon, dt.day,
                       dt.hour, dt.min, dt.sec);
}

//---Helper:     
void BuildJson()
{
   
};

//---Main Function: send request
bool SendTradeReport(
   ulong posID,
   ulong ticket,
   string symbol,
   string posType,
   double volume,
   double entry_price,
   datetime dealTime,
   string status,
   double exitPrice = NULL,
   datetime exitTime = NULL,
   double profit = NULL
)
{
   //---set request url
   string url = "http://" + APIhost + ":" + APIport + APIendpoint;
   
   //---construct json payload
   string jsonPayload = StringFormat(
      "{\"position_id\":%d,\"ticket\":%d,\"symbol\":\"%s\",\"order_type\":\"%s\",\"volume\":%.2f,\"entry_price\":%.5f,\"timestamp\":\"%s\"}", 
      posID,
      ticket, 
      symbol,
      posType, //remeber to convert
      volume,
      entry_price,
      BuildISOTimestamp(dealTime)
   );
   
   if(status == "CLOSED")
     {
         jsonPayload = StringFormat(
         "{\"position_id\":%d,\"ticket\":%d,\"symbol\":\"%s\",\"order_type\":\"%s\",\"volume\":%.2f,\"entry_price\":%.5f,\"timestamp\":\"%s\",\"exit_price\":%.5f,\"exit_time\":\"%s\",\"profit\":%.2f,\"status\":\"%s\"}", 
         posID,
         ticket, 
         symbol,
         posType, //remeber to convert
         volume,
         entry_price,
         BuildISOTimestamp(dealTime),
         exitPrice,
         BuildISOTimestamp(exitTime),
         profit,
         status
      );
     }
     
   //---construct Web request 
   char data[], response[];
   uint timeout = 5000; //milliseconds
   
   int dataLength = StringToCharArray(
      jsonPayload, 
      data,
      0,
      StringLen(jsonPayload),
      CP_UTF8   
   );
   
   string responseHeader;
   
   Print("JSON payload: ", jsonPayload);
   int code = WebRequest("POST", url, RequestHeader, "", timeout, data, dataLength, response, responseHeader);
   
   //---verify operation
   if(code == 200)
     {
         Print("Request OK, response: ", CharArrayToString(response));
         return true;
     }
     else
       { 
         Print("Request FAILED, ", GetLastError(), "Response: ", CharArrayToString(response), "\n");
         return false;
       }
   
   
}
