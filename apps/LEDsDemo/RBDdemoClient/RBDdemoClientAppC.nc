#include <demoClient.h>
configuration RBDdemoClientAppC {}

implementation
{
  enum {CTP_ID = 16, RBD_ID=17};
  components MainC;
  components ActiveMessageC;
  components CollectionC;
  components RoutebackC;
  components new CtpSenderRbdReceiverC(CTP_ID,RBD_ID) as CtpRbd;
  components new TimerMilliC() as TimerSend;
  //components new TimerMilliC() as TimerLeds;
  components RBDdemoClientC;
  components LedsC;
  components SerialActiveMessageC;
  components PrintfC;
  
  components RandomC;
  
  components CC2420ActiveMessageC as LplRadio;
  RBDdemoClientC.LowPowerListening -> LplRadio;
  

  RBDdemoClientC.Random -> RandomC;
  RBDdemoClientC.SerialControl -> SerialActiveMessageC;
  RBDdemoClientC.Boot -> MainC;
  RBDdemoClientC.RadioSplitControl -> ActiveMessageC;
  RBDdemoClientC.CollectionStdControl -> CollectionC;
 // RBDdemoClientC.ForwardError -> RoutebackC;
  RBDdemoClientC.RoutebackStdControl -> RoutebackC;
  RBDdemoClientC.RbdReceive-> CtpRbd.RbdReceive;
  RBDdemoClientC.CtpSend -> CtpRbd.CtpSend;
  RBDdemoClientC.SendT -> TimerSend;
 // RBDdemoClientC.LedsT -> TimerLeds;
  RBDdemoClientC.Leds-> LedsC;
  RBDdemoClientC.Packet_Rbd->CtpRbd.Packet_Rbd;
  RBDdemoClientC.RoutebackPacket -> RoutebackC.RoutebackPacket;
  
   
  components new PoolC(message_t, 10) as DebugMessagePool;
  components new QueueC(message_t*, 10) as DebugSendQueue;

}
