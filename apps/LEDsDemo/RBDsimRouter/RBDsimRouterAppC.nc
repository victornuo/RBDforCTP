/**
 * TestNetworkLplC exercises the basic networking layers, collection and
 * dissemination. The application samples DemoSensorC at a basic rate
 * and sends packets up a collection tree. The rate is configurable
 * through dissemination.
 *
 * See TEP118: Dissemination, TEP 119: Collection, and TEP 123: The
 * Collection Tree Protocol for details.
 * 
 * @author Philip Levis
 * @version $Revision: 1.1 $ $Date: 2009-09-16 00:53:47 $
 */

#include "Ctp.h"
#define NEW_PRINTF_SEMANTICS
#include <demorouter.h>
#include "printf.h"

configuration RBDsimRouterAppC {}
implementation {
   enum {CTP_ID = 16, RBD_ID = 17};
  components RBDsimRouterC;
  components MainC; 
  components LedsC; 
 
  components ActiveMessageC;
  components new RbdSenderC(RBD_ID) as Sender;
  components RoutebackC as Deliver;
  components CollectionC as Collector;
  components new TimerMilliC();
  
  components PrintfC;

    
  RBDsimRouterC.MilliTimer -> TimerMilliC;
  
  
  RBDsimRouterC.Boot -> MainC;
  RBDsimRouterC.RadioControl -> ActiveMessageC;
  RBDsimRouterC.CollectionStdControl -> Collector;
  RBDsimRouterC.RoutebackStdControl -> Deliver;
  RBDsimRouterC.Leds -> LedsC;
  RBDsimRouterC.RbdSend -> Sender.RbdSend;
  RBDsimRouterC.RootControl -> Collector;
  RBDsimRouterC.CtpReceive -> Collector.Receive[CTP_ID];
 
  
  RBDsimRouterC.CtpPacket -> Collector.Packet;
  Deliver.CtpPacket -> Collector.CtpPacket;
 
  RBDsimRouterC.RoutebackTable -> Deliver.RoutebackTable;
  RBDsimRouterC.Rbdmsg -> Deliver.RoutebackPacket;
}
