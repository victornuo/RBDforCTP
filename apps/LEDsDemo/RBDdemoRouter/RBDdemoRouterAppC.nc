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
#include <demorouter.h>


configuration RBDdemoRouterAppC {}
implementation {
   enum {CTP_ID = 16, RBD_ID = 17};
  components RBDdemoRouterC;
  components MainC; 
  components LedsC; 
 
  components ActiveMessageC;
  components new RbdSenderC(RBD_ID) as Sender;
  components RoutebackC as Deliver;
  components CollectionC as Collector;
  components new TimerMilliC();

  components SerialActiveMessageC;
    
  RBDdemoRouterC.SerialSend -> SerialActiveMessageC.AMSend[AM_DEMO_LED_MSG];
 
  RBDdemoRouterC.MilliTimer -> TimerMilliC;
  
  RBDdemoRouterC.SerialReceive -> SerialActiveMessageC.Receive[AM_DEMO_LED_MSG];
  	
  RBDdemoRouterC.Boot -> MainC;
  RBDdemoRouterC.RadioControl -> ActiveMessageC;
  RBDdemoRouterC.SerialControl -> SerialActiveMessageC;
  RBDdemoRouterC.CollectionStdControl -> Collector;
  RBDdemoRouterC.RoutebackStdControl -> Deliver;
  RBDdemoRouterC.Leds -> LedsC;
  RBDdemoRouterC.RbdSend -> Sender.RbdSend;
  RBDdemoRouterC.RootControl -> Collector;
  RBDdemoRouterC.CtpReceive -> Collector.Receive[CTP_ID];
 
  
  RBDdemoRouterC.SerialPacket -> SerialActiveMessageC.Packet;
  RBDdemoRouterC.CtpPacket -> Collector.Packet;
  Deliver.CtpPacket -> Collector.CtpPacket;
 
  RBDdemoRouterC.RoutebackTable -> Deliver.RoutebackTable;
  RBDdemoRouterC.Rbdmsg -> Deliver.RoutebackPacket;
}
