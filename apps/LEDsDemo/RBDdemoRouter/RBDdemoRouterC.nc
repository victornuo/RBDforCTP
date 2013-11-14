#include <Timer.h>
//#include "printf.h"
#include <demorouter.h>

/**
 *  Led 0 Toggles bon serial port reception
 *  Led 1 flash while sending RBD (on at send, off when sendDone
 *  Led 2 Toggles CTP reception and remains on when  (MAX-NODES - 1) are in the table the router do not have RBDroute to itself.
 * 
 * */
//#include <Rbd.h>
module RBDdemoRouterC {
  uses{
  
  interface Boot;
  
  interface AMSend as SerialSend;
  interface Send as RbdSend;
  
  interface SplitControl as RadioControl;
  interface SplitControl as SerialControl;
  
  interface StdControl as CollectionStdControl;
  interface StdControl as RoutebackStdControl;
  
  interface Leds;
  interface Timer<TMilli> as MilliTimer;
  
  
  interface RootControl;
  interface Receive as CtpReceive;
  interface Receive as SerialReceive;
 
  interface Packet as SerialPacket; //??
  //interface Packet as RbdPacket;
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
	
  task void sendMessageRbd();
    
  event void Boot.booted() {
    ctp_payload = (ctp_p*)call CtpPacket.getPayload (&ctpmsg, sizeof(ctp_p));
    rbd_payload = (rbd_p*)call RbdSend.getPayload (&rbdmsg, sizeof(rbd_p));
    rbd_payload->value = 1;
    
    call Leds.led1On();
    call Leds.led1On();
    call Leds.led2On();
    returnValue = 0;
    nodeDestUART = 0;
    seqno = 0;
    locked = FALSE;
    call SerialControl.start();
  }
  
  event void SerialControl.startDone(error_t err) {
     if (err != SUCCESS) 
     {
      call SerialControl.start();
    }
    else
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
      call MilliTimer.startPeriodic(1000);
      call Leds.led1Off();
      call Leds.led1Off();
      call Leds.led2Off();
      
      seqno = 0;
    }
  }
  
  // MilliTimer send a peridic message to the computer using the serial port
  event void MilliTimer.fired() {
    
    if (locked) {
      return;
    }
    else {
      demo_led_msg_t* rcm = (demo_led_msg_t*)call SerialPacket.getPayload(&serialmsg, sizeof(demo_led_msg_t));
      if (rcm == NULL) {return;}
      if (call SerialPacket.maxPayloadLength() < sizeof(demo_led_msg_t)) {
	return;
      }

      rcm->value = returnValue;
      rcm->nodeDest = 255;
      if (call SerialSend.send(AM_BROADCAST_ADDR, &serialmsg, sizeof(demo_led_msg_t)) == SUCCESS) {
	locked = TRUE;
      }
    }
  }
  
  // Once the Serial Msg was sent if the vule sent was 1, it stops the TimerMilli
  event void SerialSend.sendDone(message_t* bufPtr, error_t error) {
    if (returnValue == 1)
	call MilliTimer.stop();
    
    locked = FALSE;
     
  }

  task void sendMessageRbd() {
    error_t error;
    if ( sendBusy == TRUE)
      return;
    else{
    sendBusy = TRUE;
       
    if (call RoutebackTable.hasRoute(nodeDestUART)!= RBD_INVALID_ADDR)
    {
      rbd_payload->value=valueUART;
      call Rbdmsg.setDestination(&rbdmsg,nodeDestUART);
      call Rbdmsg.setSequenceNumber(&rbdmsg,seqno); 
      seqno++; 
      error = call RbdSend.send(&rbdmsg, sizeof(rbd_p));
      call Leds.led1On(); 
     }
   
    }
  }
  
 event message_t* 
  CtpReceive.receive(message_t* msg, void* payload, uint8_t len) {
	  
  call RoutebackTable.routingTableUpdate(msg);
  
  if (call RoutebackTable.getCount()>=MAX_NODES_RBD-1)
    call Leds.led2On();
  else
    call Leds.led2Toggle();
    
  return msg;
  }
  
  event message_t* SerialReceive.receive(message_t* bufPtr, void* payload, uint8_t len) {
	 demo_led_msg_t* rcm;
	 call Leds.led0Toggle();
	 if (len != sizeof(demo_led_msg_t)) {
		  returnValue = 0; 
		  return bufPtr;
	  }
		  
	  else {
		rcm = call SerialPacket.getPayload(bufPtr,sizeof(demo_led_msg_t));  
	    //When the node gets a messagge via UART led0 toggles before sending the message
		  
		  
		  switch (rcm->nodeDest)
		  {
			  case 0:
				  if (rcm->value == 0)
					  returnValue = 1;
			  break;
			  
			  default:
				  if (rcm->nodeDest<=MAX_NODES_RBD) 
				  {
					nodeDestUART=(nx_am_addr_t)rcm->nodeDest;
					valueUART = rcm->value;
					post sendMessageRbd();
				   }
			  break;				
		  }
	  }
	  return (bufPtr);
  }

  event void RbdSend.sendDone(message_t* m, error_t err) 
  {
    call Leds.led1Off(); 
    sendBusy = FALSE;
    
  }

  event void RadioControl.stopDone(error_t err) {}
  
  event void SerialControl.stopDone(error_t err) {}	
  
  event message_t* Rbdmsg.forwardingError(message_t* msg) {return msg;}
  
	
	
 
} 
