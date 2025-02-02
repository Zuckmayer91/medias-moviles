//+------------------------------------------------------------------+
//|                              Media Móvil Simple AE Cobertura.mq5 |
//|                          Copyright 2022, José Martínez Hernández |
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| RENUNCIA DE GARANTÍAS                                            |
//+------------------------------------------------------------------+

//EL SOFTWARE SE ENTREGA “TAL CUAL” Y “SEGÚN DISPUESTO”, SIN GARANTÍA DE NINGÚN TIPO.
//USTED RECONOCE Y ACEPTA EXPRESAMENTE QUE TODO EL RIESGO EN CUANTO AL USO, RESULTADOS Y
//EL RENDIMIENTO DEL SOFTWARE LO ASUME EXCLUSIVAMENTE USTED.
//EN LA MEDIDA MÁXIMA PERMITIDA POR LA LEY APLICABLE, EL AUTOR RENUNCIA EXPRESAMENTE DE TODAS
//GARANTÍAS, YA SEAN EXPLÍCITAS O IMPLÍCITAS, INCLUIDAS, ENTRE OTRAS, LAS IMPLÍCITAS
//GARANTÍAS DE COMERCIABILIDAD, IDONEIDAD PARA UN FIN DETERMINADO, TÍTULO Y
//NO INFRACCIÓN O CUALQUIER GARANTÍA DERIVADA DE CUALQUIER PROPUESTA,
//ESPECIFICACION O MUESTRA RESPECTO DEL SOFTWARE, Y GARANTIAS QUE PUEDEN DARSE
//DE LA NEGOCIACIÓN, EJECUCIÓN, USO O PRÁCTICA COMERCIAL.
//SIN LIMITACIÓN DE LO ANTERIOR, EL AUTOR NO OFRECE NINGUNA GARANTÍA O COMPROMISO,
//Y NO HACE NINGUNA PROMESA DE QUE EL SOFTWARE CUMPLIRÁ CON SUS REQUISITOS,
//LOGRARÁ CUALQUIER RESULTADO PREVISTO, SERÁ COMPATIBLE O FUNCIONARÁ CON CUALQUIER OTRO SOFTWARE, SISTEMAS
//O SERVICIOS, OPERARÁ SIN INTERRUPCIONES, CUMPLIRÁ CUALQUIER ESTÁNDAR DE RENDIMIENTO O CONFIABILIDAD
//O ESTARÁ LIBRE DE ERRORES O QUE CUALQUIER ERROR O DEFECTO PODRÁ SER CORREGIDO.
//NINGUNA INFORMACIÓN ORAL O ESCRITA O CONSEJOS O RECOMENDACIONES PROPORCIONADAS POR EL 
//AUTOR DEBERÁN CREAR UNA GARANTÍA O AFECTAR DE CUALQUIER FORMA AL ALCANCE Y FUNCIONAMIENTO DE ESTA RENUNCIA.
//ESTA RENUNCIA DE GARANTÍA CONSTITUYE UNA PARTE ESENCIAL DE ESTA LICENCIA.

//+------------------------------------------------------------------+
//| Información del Asesor                                           |
//+------------------------------------------------------------------+

#property copyright "Copyright 2022, José Martínez Hernández"
#property description "Asesor Experto que aplica el sistema de media móvil simple y es provisto como parte del curso en trading algorítmico" 
#property link      ""
#property version   "1.00"

//+------------------------------------------------------------------+
//| Notas del Asesor                                                 |
//+------------------------------------------------------------------+
// Asesor experto que opera una estrategia de media móvil
// Está diseñado para operar en la dirección de la tendencia, colocando posiciones de compra cuando la última barra cierra por encima de la media móvil y posiciones de venta en corto cuando la última barra cierra por debajo de la media móvil
// Incorpora dos stop loss alternativos diferentes que consisten en puntos fijos por debajo del precio de apertura o media móvil, para operaciones largas, o por encima del precio de apertura o media móvil, para operaciones cortas
// Incorpora configuraciones para colocar take profit, así como break-even y trailing stop loss

//+------------------------------------------------------------------+
//| AE Enumeraciones                                                 |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Variables Input y Globales                                       |
//+------------------------------------------------------------------+

sinput group                              "### AE AJUSTES GENERALES ###"
input ulong                               MagicNumber                      = 101;
input bool                                UsarPoliticaLlenado              = false;
input ENUM_ORDER_TYPE_FILLING             PoliticaLlenado                  = ORDER_FILLING_IOC;

sinput group                              "### AJUSTES MEDIA MÓVIL ###"
input int                                 PeriodoMA                        = 30;
input ENUM_MA_METHOD                      MetodoMA                         = MODE_SMA;
input int                                 ShiftMA                          = 0;
input ENUM_APPLIED_PRICE                  PrecioMA                         = PRICE_CLOSE;

sinput group                              "### GESTIÓN MONETARIA ###"
input double                              VolumenFijo                      = 0.1;

sinput group                              "### GESTIÓN DE POSICIONES ###"
input int                                 SLPuntosFijos                    = 0;
input int                                 SLPuntosFijosMA                  = 0;
input int                                 TPPuntosFijos                    = 0;
input int                                 TSLPuntosFijos                   = 0;
input int                                 BEPuntosFijos                    = 0;

datetime glTiempoBarraApertura;
int      ManejadorMA;

//+------------------------------------------------------------------+
//| Procesadores de Eventos                                          |
//+------------------------------------------------------------------+


int OnInit()
{
   glTiempoBarraApertura = D'1971.01.01 00:00';

   ManejadorMA = MA_Init(PeriodoMA,ShiftMA,MetodoMA,PrecioMA);
   
   if(ManejadorMA == -1){
      return(INIT_FAILED);}
      
   return(INIT_SUCCEEDED);
}
  
void OnDeinit(const int reason)
{
   Print("Asesor eliminado");
}
  
void OnTick()
{  
   //------------------------//
   // CONTROL DE NUEVA BARRA //
   //------------------------//
   
   bool nuevaBarra = false;
   
   //Comprobación de nueva barra
   if(glTiempoBarraApertura != iTime(_Symbol,PERIOD_CURRENT,0))
   {
      nuevaBarra = true;
      glTiempoBarraApertura = iTime(_Symbol,PERIOD_CURRENT,0);
   }
   
   if(nuevaBarra == true)
   {           
      //------------------------//
      // PRECIO E INDICADORES   //
      //------------------------//

      //Precio
      double cierre1 = Close(1);
      double cierre2 = Close(2);
      
      //Normalización a tick size (tamaño del tick)
      double tickSize = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);     
      cierre1 = round(cierre1/tickSize) * tickSize; 
      cierre2 = round(cierre2/tickSize) * tickSize;
      
      //Media Móvil (MA)
      double ma1 = ma(ManejadorMA,1);
      double ma2 = ma(ManejadorMA,2);
                  
      //------------------------//
      // CIERRE DE POSICIONES   //
      //------------------------//

      //Señal de cierre && Cierre de posiciones
      string exitSignal = MA_ExitSignal(cierre1,cierre2,ma1,ma2);
      
      if(exitSignal == "CIERRE_LARGO" || exitSignal == "CIERRE_CORTO"){
         CierrePosiciones(MagicNumber,exitSignal);}
         
      Sleep(1000);   
      
      //------------------------//
      // COLOCACIÓN DE ÓRDENES  //
      //------------------------//   
   
      //Señal de entrada && Colocación de posiciones      
      string entrySignal = MA_EntrySignal(cierre1,cierre2,ma1,ma2);
      Comment("A.E. #", MagicNumber, " | ", exitSignal, " | ",entrySignal, " SEÑALES DETECTADAS");
      
      if((entrySignal == "LARGO" || entrySignal == "CORTO") && RevisionPosicionesColocadas(MagicNumber) == false)
      {
         ulong ticket = AperturaTrades(entrySignal,MagicNumber,VolumenFijo);
      }
                 
      //------------------------//
      // GESTIÓN DE POSICIONES  //
      //------------------------//
      
   }
}


//+------------------------------------------------------------------+
//| AE Funciones                                                     |
//+------------------------------------------------------------------+

//+----------+// Funciones del Precio //+----------+//

double Close(int pShift)
{
   MqlRates barra[];                            //Crea un objeto array del tipo estructura MqlRates
   ArraySetAsSeries(barra,true);                //Configura nuestro array como un array en serie (la vela actual se copiará en índice 0, la vela 1 en índice 1 y sucesivamente)
   CopyRates(_Symbol,PERIOD_CURRENT,0,3,barra); //Copia datos del precio de barras 0, 1 y 2 a nuestro array barra
   
   return barra[pShift].close;                  //Retorna precio de cierre del objeto barra
}

double Open(int pShift)
{
   MqlRates barra[];                            //Crea un objeto array del tipo estructura MqlRates
   ArraySetAsSeries(barra,true);                //Configura nuestro array como un array en serie (la vela actual se copiará en índice 0, la vela 1 en índice 1 y sucesivamente)
   CopyRates(_Symbol,PERIOD_CURRENT,0,3,barra); //Copia datos del precio de barras 0, 1 y 2 a nuestro array barra
   
   return barra[pShift].open;                   //Retorna precio de apertura del objeto barra
}

//+----------+// Funciones de la Media Móvil //+----------+//

int MA_Init(int pPeriodoMA,int pShiftMA,ENUM_MA_METHOD pMetodoMA,ENUM_APPLIED_PRICE pPrecioMA)
{
   //En caso de error al inicializar el MA, GetLastError() nos dará el código del error y lo almacenará en _LastError
   //ResetLastError cambiará el valor de la variable _LastError a 0
   ResetLastError();
   
   //El manejador es un identificador único para el indicador. Se utiliza para todas las acciones relacionadas con este, como obtener datos o eliminarlo
   int Manejador = iMA(_Symbol,PERIOD_CURRENT,pPeriodoMA,pShiftMA,pMetodoMA,pPrecioMA);
   
   if(Manejador == INVALID_HANDLE)
   {
      return -1;
      Print("Ha habido un error creando el manejador del indicador MA: ", GetLastError());
   }
   
   Print("El manejador del indicador MA se ha creado con éxito");
   
   return Manejador;
}

double ma(int pManejadorMA, int pShift)
{
   ResetLastError();
   
   //Creamos un array que llenaremos con los precios del indicador
   double ma[];
   ArraySetAsSeries(ma,true);
   
   //Llenamos el array con los 3 valores más recientes del MA
   bool resultado = CopyBuffer(pManejadorMA,0,0,3,ma);
   if(resultado == false){
      Print("ERROR AL COPIAR DATOS: ", GetLastError());}
      
   //Preguntamos por el valor del indicador almacenado en pShift
   double valorMA = ma[pShift];
   
   //Normalizamos valorMA a los dígitos de nuestro símbolo y lo retornamos
   valorMA = NormalizeDouble(valorMA,_Digits);
   
   return valorMA;   
}

string MA_EntrySignal(double pPrecio1, double pPrecio2, double pMA1, double pMA2)
{
   string str = "";
   string valores;
   
   if(pPrecio1 > pMA1 && pPrecio2 <= pMA2) {str = "LARGO";}
   else if(pPrecio1 < pMA1 && pPrecio2 >= pMA2) {str = "CORTO";}
   else {str = "NO_OPERAR";}
   
   StringConcatenate(valores,"MA 1: ", DoubleToString(pMA1,_Digits), " | ", "MA 2: ", DoubleToString(pMA2,_Digits), " | ",
                     "Cierre 1: ", DoubleToString(pPrecio1,_Digits), " | ", "Cierre 2: ", DoubleToString(pPrecio2,_Digits));
   
   Print("Valores del precio e indicadores: ", valores);
   
   return str;
}

string MA_ExitSignal(double pPrecio1, double pPrecio2, double pMA1, double pMA2)
{
   string str = "";
   string valores;
   
   if(pPrecio1 > pMA1 && pPrecio2 <= pMA2) {str = "CIERRE_CORTO";}
   else if(pPrecio1 < pMA1 && pPrecio2 >= pMA2) {str = "CIERRE_LARGO";}
   else {str = "NO_CIERRE";}
   
   StringConcatenate(valores,"MA 1: ", DoubleToString(pMA1,_Digits), " | ", "MA 2: ", DoubleToString(pMA2,_Digits), " | ",
                     "Cierre 1: ", DoubleToString(pPrecio1,_Digits), " | ", "Cierre 2: ", DoubleToString(pPrecio2,_Digits));
   
   Print("Valores del precio e indicadores: ", valores);
   
   return str;
}

//+----------+// Funciones de las Bandas de Bollinger //+----------+//

int BB_Init(int pPeriodoBB,int pShiftBB,double pDesviacionBB,ENUM_APPLIED_PRICE pPrecioBB)
{
   //En caso de error al inicializar las BB, GetLastError() nos dará el código del error y lo almacenará en _LastError
   //ResetLastError cambiará el valor de la variable _LastError a 0
   ResetLastError();
   
   //El manejador es un identificador único para el indicador. Se utiliza para todas las acciones relacionadas con este, como obtener datos o eliminarlo
   int Manejador = iBands(_Symbol,PERIOD_CURRENT,pPeriodoBB,pShiftBB,pDesviacionBB,pPrecioBB);
   
   if(Manejador == INVALID_HANDLE)
   {
      return -1;
      Print("Ha habido un error creando el manejador del indicador BB: ", GetLastError());
   }
   
   Print("El manejador del indicador BB se ha creado con éxito");
   
   return Manejador;
}

double BB(int pManejadorBB, int pBuffer, int pShift)
{
   ResetLastError();
   
   //Creamos un array que llenaremos con los precios del indicador
   double BB[];
   ArraySetAsSeries(BB,true);
   
   //Llenamos el array con los 3 valores más recientes del BB
   bool resultado = CopyBuffer(pManejadorBB,pBuffer,0,3,BB);
   if(resultado == false){
      Print("ERROR AL COPIAR DATOS: ", GetLastError());}
      
   //Preguntamos por el valor del indicador almacenado en pShift
   double valorBB = BB[pShift];
   
   //Normalizamos valorBB a los dígitos de nuestro símbolo y lo retornamos
   valorBB = NormalizeDouble(valorBB,_Digits);
   
   return valorBB;   
}

//+----------+// Funciones para la Colocación de Órdenes//+----------+//

ulong AperturaTrades(string pEntrySignal, ulong pMagicNumber, double pVolumenFijo)
{
   //Compramos al Ask pero cerramos al Bid
   //Vendemos al Bid pero cerramos al Ask
   
   double precioAsk  = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double precioBid  = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double tickSize   = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   
   //Precio debe ser normalizado a dígitos o tamaño del tick (ticksize)
   precioAsk = round(precioAsk/tickSize) * tickSize;
   precioBid = round(precioBid/tickSize) * tickSize;
   
   string comentario = pEntrySignal + " | " + _Symbol + " | " + string(pMagicNumber);
   
   //Declaración e inicialización de los objetos solicitud y resultado
   MqlTradeRequest solicitud  = {};
   MqlTradeResult resultado   = {}; 
   
   if(pEntrySignal == "LARGO")
   {
      //Parámetros de la solicitud
      solicitud.action     = TRADE_ACTION_DEAL;
      solicitud.symbol     = _Symbol;
      solicitud.volume     = pVolumenFijo;
      solicitud.type       = ORDER_TYPE_BUY;
      solicitud.price      = precioAsk;
      solicitud.deviation  = 30;
      solicitud.magic      = pMagicNumber;
      solicitud.comment    = comentario;
      
      if(UsarPoliticaLlenado == true) solicitud.type_filling = PoliticaLlenado;
      
      //Envío de la solicitud
      if(!OrderSend(solicitud,resultado))
         Print("Error en el envío de la orden: ", GetLastError());      //Si la solicitud no se envía, imprimimos código de error
      
      //Información de la operación
      Print("Abierta ", solicitud.symbol, " ",pEntrySignal," orden #",resultado.order,": ",resultado.retcode,", Volumen: ",resultado.volume,", Precio: ",DoubleToString(precioAsk,_Digits));
         
   }
   else if(pEntrySignal == "CORTO")
   {
      //Parámetros de la solicitud
      solicitud.action     = TRADE_ACTION_DEAL;
      solicitud.symbol     = _Symbol;
      solicitud.volume     = pVolumenFijo;
      solicitud.type       = ORDER_TYPE_SELL;
      solicitud.price      = precioBid;
      solicitud.deviation  = 30;
      solicitud.magic      = pMagicNumber;
      solicitud.comment    = comentario;

      if(UsarPoliticaLlenado == true) solicitud.type_filling = PoliticaLlenado;
      
      //Envío de la solicitud
      if(!OrderSend(solicitud,resultado))
         Print("Error en el envío de la orden: ", GetLastError());      //Si la solicitud no se envía, imprimimos código de error
      
      //Información de la operación
      Print("Abierta ", solicitud.symbol, " ",pEntrySignal," orden #",resultado.order,": ",resultado.retcode,", Volumen: ",resultado.volume,", Precio: ",DoubleToString(precioBid,_Digits));   
   }
   
   if(resultado.retcode == TRADE_RETCODE_DONE || resultado.retcode == TRADE_RETCODE_DONE_PARTIAL || resultado.retcode == TRADE_RETCODE_PLACED || resultado.retcode == TRADE_RETCODE_NO_CHANGES)
   {
      return resultado.order;
   }
   else return 0;      
}

void ModificacionPosiciones(ulong pTicket, ulong pMagicNumber, double pSLPrecio, double pTPPrecio)
{
   double tickSize = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   
   MqlTradeRequest solicitud  = {};
   MqlTradeResult resultado   = {};
   
   solicitud.action = TRADE_ACTION_SLTP;
   solicitud.position = pTicket;
   solicitud.symbol = _Symbol;
   solicitud.sl = round(pSLPrecio/tickSize) * tickSize;
   solicitud.tp = round(pTPPrecio/tickSize) * tickSize;
   solicitud.comment = "MOD. " + " | " + _Symbol + " | " + string(pMagicNumber) + ", SL: " + DoubleToString(solicitud.sl,_Digits) + ", TP: " + DoubleToString(solicitud.tp,_Digits);
   
   if(solicitud.sl > 0 || solicitud.tp > 0)
   {
      Sleep(1000);
      bool sent = OrderSend(solicitud,resultado);
      Print(resultado.comment);
      
      if(!sent)
      {
         Print("Error de modificación OrderSend: ", GetLastError());
         Sleep(3000);
         
         sent = OrderSend(solicitud,resultado);
         Print(resultado.comment);
         if(!sent) Print("2o intento error de modificación OrderSend: ", GetLastError());
      }
   } 
}

bool RevisionPosicionesColocadas(ulong pMagicNumber)
{
   bool posicionColocada = false;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong posicionTicket = PositionGetTicket(i);
      PositionSelectByTicket(posicionTicket);
      
      ulong posicionMagico = PositionGetInteger(POSITION_MAGIC);
      
      if(posicionMagico == pMagicNumber)
      {
         posicionColocada = true;
         break;
      }
   }
   
   return posicionColocada;
}

void CierrePosiciones(ulong pMagicNumber, string pExitSignal)
{
   //Declaración e inicialización de los objetos solicitud y resultado
   MqlTradeRequest solicitud  = {};
   MqlTradeResult resultado   = {};
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      //Reset de los valores de los objetos solicitud y resultado
      ZeroMemory(solicitud);
      ZeroMemory(resultado);
      
      ulong posicionTicket = PositionGetTicket(i);
      PositionSelectByTicket(posicionTicket);
      
      ulong posicionMagico = PositionGetInteger(POSITION_MAGIC);
      ulong posicionTipo = PositionGetInteger(POSITION_TYPE);
      
      if(posicionMagico == pMagicNumber && pExitSignal == "CIERRE_LARGO" && posicionTipo == POSITION_TYPE_BUY)
      {
         solicitud.action = TRADE_ACTION_DEAL;
         solicitud.type = ORDER_TYPE_SELL;
         solicitud.symbol = _Symbol;
         solicitud.position = posicionTicket;
         solicitud.volume = PositionGetDouble(POSITION_VOLUME);
         solicitud.price = SymbolInfoDouble(_Symbol,SYMBOL_BID);
         solicitud.deviation = 30;

         if(UsarPoliticaLlenado == true) solicitud.type_filling = PoliticaLlenado;
         
         bool sent = OrderSend(solicitud,resultado);
         if(sent == true){Print("Posición #",posicionTicket, " cerrada");}
      } 
      else if(posicionMagico == pMagicNumber && pExitSignal == "CIERRE_CORTO" && posicionTipo == POSITION_TYPE_SELL)
      {
         solicitud.action = TRADE_ACTION_DEAL;
         solicitud.type = ORDER_TYPE_BUY;
         solicitud.symbol = _Symbol;
         solicitud.position = posicionTicket;
         solicitud.volume = PositionGetDouble(POSITION_VOLUME);
         solicitud.price = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         solicitud.deviation = 30;

         if(UsarPoliticaLlenado == true) solicitud.type_filling = PoliticaLlenado;
         
         bool sent = OrderSend(solicitud,resultado);
         if(sent == true){Print("Posición #",posicionTicket, " cerrada");}      
      }      
   }      
}