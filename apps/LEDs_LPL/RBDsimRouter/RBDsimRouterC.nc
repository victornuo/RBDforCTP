#include <Timer.h>
#include <demorouter.h>

/**
 *  Led 0 Toggles before sending a new RBD message
 *  Led 1 Toggles if error sending the RBD message
 *  Led 2 on when RB Table full (all the nodes are in the table)
 * 
 * */
//#include <Rbd.h>
module RBDsimRouterC {
  uses{
  
  interface Boot;
  
  interface Send as RbdSend;
  
  interface SplitControl as RadioControl;
   
  interface StdControl as CollectionStdControl;
  interface StdControl as RoutebackStdControl;
  
  interface Leds;
  interface Timer<TMilli> as MilliTimer;
  
  interface LowPowerListening;
  
  interface RootControl;
  interface Receive as CtpReceive;
 
  interface Packet as CtpPacket;
  interface RoutebackPacket as Rbdmsg;
  interface RoutebackTable;
  }
    
     
}
implementation {
  
  message_t rbdmsg;
  message_t ctpmsg;
  message_t serialmsg;
  
  bool locked;
  bool sendBusy = FALSE;
  bool uartbusy = FALSE;
  
  nx_am_addr_t nodeDestUART;
  uint8_t seqno;
  uint8_t valueUART;
  uint8_t returnValue;
  
  // CTP Payload msgType [1 --> regular msg] [0 --> RBD Error Report]
  typedef nx_struct {
  nx_uint8_t msgType;
  } ctp_p;

  // RBD payload value [1 --> switch on Led0] [0 --> switch off led0]
  typedef nx_struct {
  nx_uint8_t value;
  } rbd_p;

  ctp_p *ctp_payload;
  rbd_p *rbd_payload;
	
  void sendMessageRbd();
    
  event void Boot.booted() {
    ctp_payload = (ctp_p*)call CtpPacket.getPayload (&ctpmsg, sizeof(ctp_p));
    rbd_payload = (rbd_p*)call RbdSend.getPayload (&rbdmsg, sizeof(rbd_p));
    rbd_payload->value = 1;
    
    call Leds.led0Off();
    call Leds.led1Off();
    call Leds.led2Off();
    returnValue = 0;
    nodeDestUART = 2;
    valueUART = 1;
    seqno = 0;
    locked = FALSE;
    call RadioControl.start();
  }
  
  event void RadioControl.startDone(error_t err) {
    if (err != SUCCESS) {
      call RadioControl.start();
    }
    else {
      call CollectionStdControl.start();
      call RoutebackStdControl.start();
      call RootControl.setRoot();
      seqno = 0;
    }
  }
  
  // MilliTimer send a peridic message to the computer using the serial port
  event void MilliTimer.fired() {
    
    if (sendBusy) {
      return;
    }
    else {
        
      sendMessageRbd();
      
      if (valueUART == 1)
	valueUART=0;
      else 
	valueUART=1;
	
	
      }
    }
    
  void sendMessageRbd() {
    error_t error;
    sendBusy = TRUE;   
    if (call RoutebackTable.hasRoute(nodeDestUART)!= RBD_INVALID_ADDR)
    {
      call Leds.led1Toggle();
      rbd_payload->value=valueUART;
      call Rbdmsg.setDestination(&rbdmsg,nodeDestUART);
      call Rbdmsg.setSequenceNumber(&rbdmsg,seqno); 
      seqno++; 
      error = call RbdSend.send(&rbdmsg, sizeof(rbd_p));
      call Leds.led1Toggle();
     }
    else 
      call Leds.led1On();
  }

  event message_t* 
  CtpReceive.receive(message_t* msg, void* payload, uint8_t len) {
  uint8_t count;	  
  
  if (call RoutebackTable.routingTableUpdate(msg))
    call Leds.led0Toggle();
  // If routeback table full all nodes are in the table
  count = call RoutebackTable.getCount();
  printf("\nROOT;%d\n", count);
  printfflush();
  if (count>=MAX_NODES_RBD-1)
  {      
    call MilliTimer.startPeriodic(1000);
    call Leds.led2On();
  }
  else
    call Leds.led2Toggle();
    
  return msg;
  }
  
  
  event void RbdSend.sendDone(message_t* m, error_t err) {sendBusy = FALSE;}

  event void RadioControl.stopDone(error_t err) {}
  
  event message_t* Rbdmsg.forwardingError(message_t* msg) {return msg;}
  
	
	
 
} 
