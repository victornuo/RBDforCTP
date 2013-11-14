/*
 * CTP-RBD Client
 * Standard CTP, a CTP message is sent every (CTP_MSG_PERIOD_BASE) average
 * Led1 toggle every time a SUCCES CTP messagge is sent 
 * Led0 is command with RBD messages value (1 to switch on, 0 to switch off) 
 * 
 */ 


#include <demoClient.h>

module RBDdemoClientC
{
  uses {
    interface Boot;
    interface SplitControl as RadioSplitControl;
    interface SplitControl as SerialControl;
    interface StdControl as CollectionStdControl;
    interface StdControl as RoutebackStdControl;
    
    interface Random;
    interface LowPowerListening;
    interface Send as CtpSend;
    interface Receive as RbdReceive;
    interface Packet as Packet_Rbd;
    interface RoutebackPacket;
    interface Timer<TMilli> as SendT;
   
    interface Leds;
    
    }
}

implementation
{
    
    message_t ctpmsg;
    message_t rbdmsg;
    
    // CTP Payload msgType [1 --> regular msg] [0 --> RBD Error Report]
    typedef nx_struct {
    nx_uint8_t msgType;
    } ctp_p_t;

    // RBD payload value [1 --> switch on Led0] [0 --> switch off led0]
    typedef nx_struct {
    nx_uint8_t value;
    } rbd_p_t;

    ctp_p_t *ctp_m;
    rbd_p_t *rbd_m;
    
    event void Boot.booted ()
    {
      ctp_m = call CtpSend.getPayload (&ctpmsg, sizeof(ctp_p_t));
      ctp_m->msgType=1;
      call Leds.led0Off();
      call Leds.led2Off();
      call SerialControl.start();
	}
  
    event void SerialControl.startDone(error_t err) {
      call RadioSplitControl.start();
    }
    
    event void RadioSplitControl.startDone(error_t error)
    {
      uint16_t nextInt;
      // nextInt is CTP_MSG_PERIOD_BASE +/- (CTP_MSG_PERIOD_BASE/4)   
      nextInt = call Random.rand16() % CTP_MSG_PERIOD_BASE;
      nextInt = (nextInt + CTP_MSG_PERIOD_BASE)/2;
      nextInt = nextInt + (CTP_MSG_PERIOD_BASE / 4);

      call CollectionStdControl.start();
      call RoutebackStdControl.start();
      call SendT.startOneShot(nextInt);
    }
    
   
    /**
      * Every Random(CTP_MSG_PERIOD_BASE +/- (CTP_MSG_PERIOD_BASE/4)) a CTP msg is sent to the root
      */
    event void SendT.fired ()
    {
	    uint16_t nextInt;
	    ctp_m -> msgType=1;

	    // nextInt is CTP_MSG_PERIOD_BASE +/- (CTP_MSG_PERIOD_BASE/4)   
	    nextInt = call Random.rand16() % CTP_MSG_PERIOD_BASE;
	    nextInt = (nextInt + CTP_MSG_PERIOD_BASE)/2;
	    nextInt = nextInt + (CTP_MSG_PERIOD_BASE / 4);
	    call SendT.startOneShot(nextInt);

	    call CtpSend.send (&ctpmsg, sizeof(ctp_p_t)); 

    }
    
    event void SerialControl.stopDone(error_t err) {}	
    
    
    event message_t* RbdReceive.receive(message_t *msg, void *payload, uint8_t len)
    {
	rbd_p_t* rbd_m_rx;
	rbd_m_rx = call Packet_Rbd.getPayload(msg,sizeof(rbd_p_t));
	
	if (rbd_m_rx != NULL)
	{
	  if (rbd_m_rx->value == 0)
		  call Leds.led0Off();
	  else
		  call Leds.led0On();
	}    
	return msg;
    }
    
   event message_t* RoutebackPacket.forwardingError(message_t* msg)
   {
      ctp_m->msgType = 0;
      call CtpSend.send (&ctpmsg, sizeof(ctp_p_t)); 
      
      return (msg);
     
    }
          
   event void CtpSend.sendDone (message_t* msg, error_t error) 
   {
     if (error == SUCCESS)
          call Leds.led2Toggle();
   } 

  //Nothing to do with stopDone Event
    event void RadioSplitControl.stopDone (error_t error){}
      
}
