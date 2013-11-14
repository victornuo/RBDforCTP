/* $Id: RoutebackDeliveryP.nc */
/*
 * Copyright (c) 2007 Stanford University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 *  This component contains the forwarding path of Rbd.</p>
 *
 *  <p>The routeback engine is responsible for queueing and
 *  scheduling outgoing packets. It maintains a pool of forwarding
 *  messages and a packet send queue. It is a modified version of the 
 *  <code>ForwardingEngineP.nc</code> by  <i>Philip Levis and Kyle Jamieson</i> with a
 *  forwarding message pool of size <i>F</i> and <i>C</i>
 *  Routeback clients has a send queue of size <i>F +
 *  C</i>. This implementation several configuration constants, which
 *  can be found in <code>Rbd.h</code>.</p>
 *
 *  <p>Packets in the send queue are sent in FIFO order, with
 *  head-of-line blocking. RoutebackDeliveryC clients are sent
 *  identically to forwarded packets: only their buffer handling is
 *  different.</p>
 *
 *  <p>If Routeback is on top of a link layer that supports
 *  synchronous acknowledgments, it enables them and retransmits packets
 *  when they are not acked. It transmits a packet up to RB_MAX_RETRIES times
 *  before giving up and dropping the packet. RB_MAX_RETRIES is typically a
 *  large number (e.g., >20). If the underlying
 *  link layer does not support acknowledgments, ForwardingEngine sends
 *  a packet only once.</p> 
 *
 *  <p> When the Routeback engine sends a packet to the next hop,
 *  the routeback table is updated. If a node runs out space in its table
 *  the less used route will be erased, and the next time a packet comming 
 *  from the erased node arrives a new route will be created again. </p>
 *  
 *  <p>RoutebackEngine times its packet transmissions. It
 *  differentiates between 2 transmission cases: forwarding,
 *  success, ack failure. In each case, the Routeback engine 
 *  waits a randomized period of time before sending
 *  the next packet. This approach assumes that the network is
 *  operating at low utilization; its goal is to prevent correlated
 *  traffic -- such as nodes along a route forwarding packets -- from
 *  interfering with itself.</p>
 *
 *  
 *  @author Victor Rosello
 *  @date   $Date: 2012-09-11 23:27:30 $
 */

#include <Rbd.h>
#include "printf.h"

generic module RoutebackDeliveryP(uint8_t routingTableSize) {
  provides {
    
    interface Init;
    interface StdControl;
    interface Send [uint8_t client]; //  Send para routeback packets
    interface Receive[routeback_id_t id]; //Receive port para routeback packets dudas acerca de routebackId
    //interface Receive as Snoop[collection_id_t id]; 
    interface Receive as Snoop[routeback_id_t id]; /** */
    interface Packet; // no se si haran falta las 2.
    interface RoutebackPacket; //interface RoutebackPacket
    interface RoutebackTable; //interface RoutebackTable
    
    /**
     * Pa printfear desde la aplicacion principal
     */
    interface DebugPrintf;
    
  }
  uses {
    // These five interfaces are used in the forwarding path
    //   SubSend is for sending packets
    //   PacketAcknowledgements is for enabling layer 2 acknowledgments
    //   RetxmitTimer is for timing packet sends for improved performance
    
    interface AMSend as SubSend;
    interface PacketAcknowledgements;
    interface Timer<TMilli> as RetxmitTimer;
    interface Intercept[collection_id_t id];
    interface Packet as SubPacket;
    

    // These four data structures are used to manage packets to forward.
    // SendQueue and QEntryPool are the forwarding queue.
    // MessagePool is the buffer pool for messages to forward.
    interface Queue<rb_queue_entry_t*> as SendQueue;
    interface Pool<rb_queue_entry_t> as QEntryPool;
    interface Pool<message_t> as MessagePool;
        
    interface Receive as SubReceive;
    interface Receive as SubSnoop;
    interface CtpPacket;
    interface AMPacket;
    interface Random;
    interface Leds; 
    interface RoutebackId[uint8_t client];
    
    // The ForwardingEngine monitors whether the underlying
    // radio is on or not in order to start/stop forwarding
    // as appropriate.
    interface SplitControl as RadioControl;
    

       
  }
}
implementation {
  /* Helper functions to start the given timer with a random number
   * masked by the given mask and added to the given offset.
   */
  
  static void startRetxmitTimer(uint16_t mask, uint16_t offset);
  uint8_t routingTableFind(am_addr_t destination);
  char debug_RBD[20];
  
  void clearState(uint8_t state);
  bool hasState(uint8_t state);
  void setState(uint8_t state);
  bool tablebusy;
    
  // RBD state variables. 
  enum {
    ROUTING_ON       = 0x1, // Forwarding running?
    RADIO_ON         = 0x2, // Radio is on?
    ACK_PENDING      = 0x4, // Have an ACK pending?
    SENDING          = 0x8 // Am sending a packet?
  };

   
  // Start with all states false
  uint8_t forwardingState = 0; 
  routingback_table_entry routeback_table[routingTableSize];
  uint8_t routingTableActive;
  /* Network-level sequence number, so that receivers
   * can distinguish retransmissions from different packets. */
  uint8_t seqno;

  enum {
    RB_CLIENT_COUNT = uniqueCount(UQ_RBD_CLIENT) //esto no se lo que es y 
  };

  /* Each sending client has its own reserved queue entry.
     If the client has a packet pending, its queue entry is in the 
     queue, and its clientPtr is NULL. If the client is idle,
     its queue entry is pointed to by clientPtrs. */

  rb_queue_entry_t clientEntries[RB_CLIENT_COUNT];
  rb_queue_entry_t* ONE_NOK clientPtrs[RB_CLIENT_COUNT];

  command error_t Init.init() {
    int i;
    call RoutebackTable.routingTableInit();
    for (i = 0; i < RB_CLIENT_COUNT; i++) {
      clientPtrs[i] = clientEntries + i;
      dbg("Routeback", "clientPtrs[%hhu] = %p\n", i, clientPtrs[i]);
    }
    tablebusy=FALSE;
    seqno = 0;
    
    
    
    return SUCCESS;
  }

  command error_t StdControl.start() {
    setState(ROUTING_ON);
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    clearState(ROUTING_ON);
    return SUCCESS;
  }
  


  /* sendTask is where the first phase of all send logic
   * exists (the second phase is in SubSend.sendDone()). */
  task void sendTask();
  
  /* Routebackdelivery keeps track of whether the underlying
     radio is powered on. If not, it enqueues packets;
     when it turns on, it then starts sending packets. */ 
  event void RadioControl.startDone(error_t err) {
    if (err == SUCCESS) {
      setState(RADIO_ON);
      if (!call SendQueue.empty()) 
      {
	dbg("RBHangBug", "%s posted sendTask.\n", __FUNCTION__);
        post sendTask();
      }
    }
  }

  static void startRetxmitTimer(uint16_t window, uint16_t offset) {
    uint16_t r = call Random.rand16();
    r %= window;
    r += offset;
    call RetxmitTimer.startOneShot(r);
    dbg("Routeback", "Rexmit timer will fire in %hu ms\n", r);
  }
  
  event void RadioControl.stopDone(error_t err) {
    if (err == SUCCESS) {
      clearState(RADIO_ON);
    }
  }

  routeback_header_t* getHeader(message_t* m) {
    return (routeback_header_t*)call SubPacket.getPayload(m, sizeof(routeback_header_t));
  }
 
  /*
   * The send call from a client. Return EBUSY if the client is busy
   * (clientPtrs is NULL), otherwise configure its queue entry
   * and put it in the send queue. If the RoutebackDelivery is not
   * already sending packets (the RetxmitTimer isn't running), post
   * sendTask. It could be that the engine is running and sendTask
   * has already been posted, but the post-once semantics make this
   * not matter. What's important is that you don't post sendTask
   * if the retransmit timer is running; this would circumvent the
   * timer and send a packet before it fires.
   */ 
  
  command error_t Send.send[uint8_t client](message_t* msg, uint8_t len){
    routeback_header_t* hdr;
    rb_queue_entry_t *qe;
    bool flagSend;
    dbg("Routeback", "%s: sending packet from client %hhu: %x, len %hhu\n", __FUNCTION__, client, msg, len);
    if (!hasState(ROUTING_ON)) 
    {
       /**
	* DEBUG
	*/
	sprintf(debug_RBD,"ERROR;Routing");
	signal DebugPrintf.debugPrintf(debug_RBD); 
	/** END DEBUG*/  
      return EOFF;
      
    }
    if (len > call Send.maxPayloadLength[client]()) 
    {
        /**
	* DEBUG
	*/
	sprintf(debug_RBD,"ERROR;SIZE");
	signal DebugPrintf.debugPrintf(debug_RBD); 
	/** END DEBUG*/ 
      return ESIZE;
      
    }
        
    call Packet.setPayloadLength(msg, len);
    hdr = getHeader(msg);
    hdr->originSeqNo  = seqno++;
    hdr->type = call RoutebackId.fetch[client](); // interface creada
    
    hdr->ttl = call RoutebackTable.getHopCount(hdr->destination); 

    if (clientPtrs[client] == NULL) {
      dbg("Routeback", "%s: send failed as client is busy.\n", __FUNCTION__);
      /**
	* DEBUG
	*/
	sprintf(debug_RBD,"ERROR;BUSY");
	signal DebugPrintf.debugPrintf(debug_RBD); 
	/** END DEBUG*/ 
      return EBUSY;
    }

    qe = clientPtrs[client];
    qe->msg = msg;
    qe->client = client;
    qe->retries = RB_MAX_RETRIES;
    dbg("Routeback", "%s: queue entry for %hhu is %hhu deep\n", __FUNCTION__, client, call SendQueue.size());
    if (call SendQueue.enqueue(qe) == SUCCESS) {
      flagSend = FALSE;
      if (hasState(RADIO_ON) && !hasState(SENDING)) {
	flagSend = TRUE;
	
	dbg("RBHangBug", "%s posted sendTask.\n", __FUNCTION__);
	
        post sendTask();
      }
      
	if (flagSend)
	{
	  /**
	    * DEBUG
	    */
	    sprintf(debug_RBD,"SUCCESS"); 
	    signal DebugPrintf.debugPrintf(debug_RBD); 
	    /** END DEBUG*/ 
	}
	else
	{
	   /**
	    * DEBUG
	    */
	    sprintf(debug_RBD,"CLUSTERFUCK"); 
	    signal DebugPrintf.debugPrintf(debug_RBD); 
	    /** END DEBUG*/ 
	  
	}
	  
	
      clientPtrs[client] = NULL;
      return SUCCESS;
    }
    else {
      /**
	* DEBUG
	*/
	sprintf(debug_RBD,"ERROR;FAIL");
	signal DebugPrintf.debugPrintf(debug_RBD); 
	/** END DEBUG*/ 
      dbg("Routeback", 
          "%s: send failed as packet could not be enqueued.\n", 
          __FUNCTION__);
      
      // Return the pool entry, as it's not for me...
      return FAIL;
    }
  }

  
  
  command error_t Send.cancel[uint8_t client](message_t* msg) {
    // cancel not implemented. will require being able
    // to pull entries out of the queue.
    return FAIL;
  }

  command uint8_t Send.maxPayloadLength[uint8_t client]() {
    return call Packet.maxPayloadLength();
  }

  command void* Send.getPayload[uint8_t client](message_t* msg, uint8_t len) {
    return call Packet.getPayload(msg, len);
  }

  
  
  
  
  task void sendTask() {
    dbg("Routeback", "%s: Trying to send a packet. Queue size is %hhu.\n", __FUNCTION__, call SendQueue.size());
    if (hasState(SENDING) || call SendQueue.empty()) {
      	/**
	* DEBUG
	*/
	sprintf(debug_RBD,"SEND TASK DELAYED");
	signal DebugPrintf.debugPrintf(debug_RBD); 
	/** END DEBUG*/  
      return;
    }
   
    else {
      /* We can send a packet.
	 First check if there is a route;
	 if not, try to send/forward. */
      error_t subsendResult;
      rb_queue_entry_t* qe = call SendQueue.head();
      uint8_t payloadLen = call SubPacket.payloadLength(qe->msg);
      
      /*Check if the destination node has a route in the routebackTable*/
      routeback_header_t* header = getHeader(qe->msg);
      am_addr_t next_hop = call RoutebackTable.hasRoute(header->destination);
      
      if (next_hop == RBD_INVALID_ADDR){
	/* If the route does not exist the message is extract from the queue, at this version 
	 * neither mehcanim to create routes or notify route error to sender has been implmented */
	/* Maybe error reports could be sente via CTP to the root node*/
	/**
	* DEBUG
	*/
	sprintf(debug_RBD,"ERROR;Address");
	signal DebugPrintf.debugPrintf(debug_RBD); 
	/** END DEBUG*/ 
	call SendQueue.dequeue();
	post sendTask();
	return;
      }
      
      // Not a duplicate: we've decided we're going to send.

      /* The forwarding/sending case. */
      else {
	/* The basic forwarding/sending case. */
	
	dbg("Routeback", "Sending queue entry %p\n", qe);
	if (call PacketAcknowledgements.requestAck(qe->msg) == SUCCESS) {
	  setState(ACK_PENDING);
	}
	
	subsendResult = call SubSend.send(next_hop, qe->msg, payloadLen);
	if (subsendResult == SUCCESS) {
	  // Successfully submitted to the data-link layer.
	/**
	* DEBUG
	*
	sprintf(debug_RBD,"SUCCESS:msg->data-link");
	signal DebugPrintf.debugPrintf(debug_RBD); 
	/** END DEBUG*/    
	  setState(SENDING);
	  dbg("Routeback", "%s: subsend succeeded with %p.\n", __FUNCTION__, qe->msg);
	  return;
	}
	// The packet is too big: truncate it and retry.
	else if (subsendResult == ESIZE) {
	 /**
	* DEBUG
	*/
	sprintf(debug_RBD,"ERROR;Truncate");
	signal DebugPrintf.debugPrintf(debug_RBD); 
	/** END DEBUG*/  
	  dbg("Routeback", "%s: subsend failed from ESIZE: truncate packet.\n", __FUNCTION__);
	  call Packet.setPayloadLength(qe->msg, call Packet.maxPayloadLength());
	  post sendTask();
	
	}
	else {
	/**
	* DEBUG
	*/
	sprintf(debug_RBD,"ERROR;subsendFail");
	signal DebugPrintf.debugPrintf(debug_RBD); 
	/** END DEBUG*/  
	  dbg("Routeback", "%s: subsend failed from %i\n", __FUNCTION__, (int)subsendResult);
	}
      }
    }
  }


  /*
   * The second phase of a send operation; based on whether the transmission was
   * successful, the RoutebackDelivery either stops sending or starts the
   * RetxmitTimer with an interval based on what has occured. If the send was
   * successful or the maximum number of retransmissions has been reached, then
   * the RoutebackDelivery dequeues the current packet. If the packet is from a
   * client it signals Send.sendDone(); if it is a forwarded packet it returns
   * the packet and queue entry to their respective pools.
   * 
   */

  void packetComplete(rb_queue_entry_t* qe, message_t* msg, bool success) {
    // Four cases:
    // Local packet: success or failure
    // Forwarded packet: success or failure
    if (qe->client < RB_CLIENT_COUNT) { 
      clientPtrs[qe->client] = qe;
      
      //signal Send.sendDone[qe->client](msg, SUCCESS); Modificado el 28 jun 2013 movido al if else 
      // separo si SUCCESS Y FAIL segun packet complete 

      if (success) {
	/**
	* DEBUG
	*
	sprintf(debug_RBD,"SUCCESS:TX");
	signal DebugPrintf.debugPrintf(debug_RBD); 
	/** END DEBUG*/ 
	/*
	// AQUI
	*/
	signal Send.sendDone[qe->client](msg, SUCCESS);
	dbg("Routeback", "%s: packet %hu.%hhu for client %hhu acknowledged.\n", __FUNCTION__, call RoutebackPacket.getOrigin(msg), call RoutebackPacket.getSequenceNumber(msg), qe->client);
	
      } else {
	/**
	* DEBUG
	*/
	sprintf(debug_RBD,"ERROR.msg.%d", call RoutebackPacket.getSequenceNumber(msg));
	signal DebugPrintf.debugPrintf(debug_RBD); 
	/** END DEBUG*/ 
	/*
	// Y AQUI
	*/
	signal Send.sendDone[qe->client](msg, FAIL);
	//signal RoutebackPacket.forwardingError(msg);
	dbg("Routeback", "%s: packet %hu.%hhu for client %hhu dropped.\n", __FUNCTION__, call RoutebackPacket.getOrigin(msg), call RoutebackPacket.getSequenceNumber(msg), qe->client);
	//No collection Packet
	
      }
    }
    else { 
      if (success) {
      /**
	* DEBUG
	*
	sprintf(debug_RBD,"SUCCESS:FWD TX");
	signal DebugPrintf.debugPrintf(debug_RBD); 
	/** END DEBUG*/ 
	dbg("Routeback", "%s: forwarded packet %hu.%hhu acknowledged: insert in transmit queue.\n", __FUNCTION__, call RoutebackPacket.getOrigin(msg), call RoutebackPacket.getSequenceNumber(msg));
}
      else {
	/**
	* DEBUG
	*/
	sprintf(debug_RBD,"ERROR.FWDmsg.%d", call RoutebackPacket.getSequenceNumber(msg));
	signal DebugPrintf.debugPrintf(debug_RBD); 
	/** END DEBUG*/ 
	signal RoutebackPacket.forwardingError(msg);
	dbg("Routeback", "%s: forwarded packet %hu.%hhu dropped.\n", __FUNCTION__, call RoutebackPacket.getOrigin(msg), call RoutebackPacket.getSequenceNumber(msg));
	
      }
    
    call MessagePool.put(qe->msg) ;
    call QEntryPool.put(qe);
	
    }
  }
  
  event void SubSend.sendDone(message_t* msg, error_t error) {
    rb_queue_entry_t *qe = call SendQueue.head();
    routeback_header_t* header = getHeader(qe->msg);
    am_addr_t next_hop = call RoutebackTable.hasRoute(header->destination);

    dbg("Routeback", "%s to %hu and %hhu\n", __FUNCTION__, call AMPacket.destination(msg), error);

    if (error != SUCCESS) {
      /* The radio wasn't able to send the packet: retransmit it. */
      	/**
	* DEBUG
	*/
	sprintf(debug_RBD,"ERROR.RBD.RadioOff");
	signal DebugPrintf.debugPrintf(debug_RBD); 
	/** END DEBUG*/ 
      dbg("Routeback", "%s: send failed\n", __FUNCTION__);
       
      startRetxmitTimer(RB_SENDDONE_FAIL_WINDOW, RB_SENDDONE_FAIL_OFFSET);
    }
    else if (hasState(ACK_PENDING) && !call PacketAcknowledgements.wasAcked(msg)) {
      /* No ack: if countdown is not 0, retransmit, else drop the packet. */
      if (--qe->retries) { 
	/**
	* DEBUG
	*
	sprintf(debug_RBD,"ERROR:NOT ACK");
	signal DebugPrintf.debugPrintf(debug_RBD); 
	/** END DEBUG*/ 
        dbg("Routeback", "%s: not acked, retransmit\n", __FUNCTION__);
        startRetxmitTimer(RB_SENDDONE_NOACK_WINDOW, RB_SENDDONE_NOACK_OFFSET);
	
      } else {
	/* Hit max retransmit threshold: drop the packet. */
	/**
	* DEBUG
	*/
	sprintf(debug_RBD,"ERROR.DROP");
	signal DebugPrintf.debugPrintf(debug_RBD); 
	/** END DEBUG*/ 
	call SendQueue.dequeue();
        clearState(SENDING);
        startRetxmitTimer(RB_SENDDONE_OK_WINDOW, RB_SENDDONE_OK_OFFSET);
	
	packetComplete(qe, msg, FALSE);
      }
    }
    else {
      /* Packet was acknowledged. Updated routebackTable,
	 free the buffer (pool or sendDone), start timer to
	 send next packet. */
     
      /**
	* DEBUG
	*/
	sprintf(debug_RBD,"OK_SEND.%d", RB_MAX_RETRIES-qe->retries);
	signal DebugPrintf.debugPrintf(debug_RBD); 
	/** END DEBUG*/ 
      call SendQueue.dequeue();
      clearState(SENDING);
      startRetxmitTimer(RB_SENDDONE_OK_WINDOW, RB_SENDDONE_OK_OFFSET);
      // If Success Update routebackTable
      if (call RoutebackTable.getbusy() == FALSE)
      {
	call RoutebackTable.setbusy();
	call RoutebackTable.routingTableUpdateEntry (header->destination, next_hop, header->ttl);
	call RoutebackTable.clearbusy();
      }
      else
      { 
	/* In Case routeBack Table update can not been acomplished */
      }
      packetComplete(qe, msg, TRUE);
    }
  }

  /*
   * Function for preparing a packet for forwarding. Performs
   * a buffer swap from the message pool. If there are no free
   * message in the pool, it returns the passed message and does not
   * put it on the send queue.
   */
  message_t* ONE forward(message_t* ONE m) {
        
    if (call MessagePool.empty()) {
      /**
	* DEBUG
	*/
	sprintf(debug_RBD,"ERROR.polEmpty");
	signal DebugPrintf.debugPrintf(debug_RBD); 
	/** END DEBUG*/
      dbg("Routeback", "%s cannot forward, message pool empty.\n", __FUNCTION__);
    
    }
    
    else if (call QEntryPool.empty()) {
      /**
	* DEBUG
	*/
	sprintf(debug_RBD,"ERROR.qeEmpty");
	signal DebugPrintf.debugPrintf(debug_RBD); 
	/** END DEBUG*/
      dbg("Routeback", "%s cannot forward, queue entry pool empty.\n", 
          __FUNCTION__);
    }
    
    else 
    {
      
      message_t* newMsg;
      rb_queue_entry_t *qe;
      qe = call QEntryPool.get();
      
      if (qe == NULL) {
      /**
	* DEBUG
	*/
	sprintf(debug_RBD,"ERROR;qeNULL");
	signal DebugPrintf.debugPrintf(debug_RBD); 
	/** END DEBUG*/
        return m;
      }

      newMsg = call MessagePool.get();
      
      if (newMsg == NULL) {
	/**
	* DEBUG
	*/
	sprintf(debug_RBD,"ERROR;msgNULL");
	signal DebugPrintf.debugPrintf(debug_RBD); 
	/** END DEBUG*/	
	
        return m;
      }

      memset(newMsg, 0, sizeof(message_t));
      memset(m->metadata, 0, sizeof(message_metadata_t));
      
      qe->msg = m;
      qe->client = 0xff;
      qe->retries = RB_MAX_RETRIES;

      
      if (call SendQueue.enqueue(qe) == SUCCESS) 
      {
	/**
	* DEBUG
	*
	sprintf(debug_RBD,"SUCCESS:msg->SendQUEUE");
	signal DebugPrintf.debugPrintf(debug_RBD); 
	/** END DEBUG*/        
	dbg("Routeback,Route", "%s forwarding packet %p with queue size %hhu\n", __FUNCTION__, m, call SendQueue.size());
        if (!call RetxmitTimer.isRunning()) {
        /**
	* DEBUG
	*
	sprintf(debug_RBD,"SUCCESS:Tasked");
	signal DebugPrintf.debugPrintf(debug_RBD); 
	/** END DEBUG*/
	  dbg("RBHangBug", "%s: posted sendTask.\n", __FUNCTION__);
	  post sendTask();
        }
        
        return newMsg;
      }
      
      else 
      {
	/**
	* DEBUG
	*
	sprintf(debug_RBD,"MSGdelayed");
	signal DebugPrintf.debugPrintf(debug_RBD); 
	/** END DEBUG*/    
	call MessagePool.put(qe->msg);
	call QEntryPool.put(qe);
      }
         
    }
    
    return m;
  }
      
  /* 
   * Received a message to forward. Check whether it is a duplicate by
   * checking the packets currently in the queue. 
   * If this node is <destination>, signal receive.
   */ 
  
  event message_t*  SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
    
    routeback_id_t routebackid; 
    bool duplicate = FALSE;
    rb_queue_entry_t* qe;
    uint8_t i, ttl;
   /**
    *
    * Intento obtener la direccion del nodo q me envia el mensaje
    */
    am_addr_t sender;
    am_addr_t destination;
    sender = call AMPacket.source (msg);
    destination = call AMPacket.destination(msg);
    /** */
    
    
    routebackid = call RoutebackPacket.getType(msg);

    // Update the Ttl here, since it has lived another hop, and so
    // that the node sees the correct Ttl.
     
    ttl = call RoutebackPacket.getTtl(msg);
    ttl--;
    call RoutebackPacket.setTtl(msg, ttl);
        
    if (len > call SubSend.maxPayloadLength()) {
      /**
       * DEBUG
       *
      sprintf(debug_RBD,"ERROR:Payload");
      signal DebugPrintf.debugPrintf(debug_RBD); 
      /** END DEBUG*/
      
      return msg;
    }
    
     //We look in the queue for duplicates
    
    if (call SendQueue.size() > 0) {
      for (i = call SendQueue.size(); i >0; i--) {
	qe = call SendQueue.element(i-1);
	  if (call RoutebackPacket.matchInstance(qe->msg, msg)) 
	  {
	    duplicate = TRUE;
	    break;
	  }
	}
      }
    
    if (duplicate) 
    {
      /**
       * DEBUG
       */
      sprintf(debug_RBD,"ERROR.RBD.Duplic");
      signal DebugPrintf.debugPrintf(debug_RBD); 
      /** END DEBUG*/
	return msg;
    }
    
     // If I'm the destination, signal receive. 
     else if (getHeader(msg)->destination==TOS_NODE_ID)
     {
	/**
	* DEBUG
	*/
	sprintf(debug_RBD,"DELIVER.RBD.F%d",sender);
	signal DebugPrintf.debugPrintf(debug_RBD); 
	/** END DEBUG*/
	return signal Receive.receive[routebackid](msg,
					call Packet.getPayload(msg, call Packet.payloadLength(msg)), 
					call Packet.payloadLength(msg));
      }
    
      // Else if ttl is not 0 forward messagge to the next hop. 
      else if (ttl >= 0) 
      {
	/**
	* DEBUG
	*/
	am_addr_t nex_hop= call RoutebackTable.hasRoute(getHeader(msg)->destination); 
	sprintf(debug_RBD,"FWD->%d->%d",nex_hop, getHeader(msg)->destination);
	signal DebugPrintf.debugPrintf(debug_RBD); 
	/** END DEBUG*/
	dbg("Route", "Forwarding packet to %hu.\n", getHeader(msg)->destination);
	return forward(msg);
      }
     else{
       /**
	* DEBUG
	*/
	sprintf(debug_RBD,"ERROR.RBD.TTL");
	signal DebugPrintf.debugPrintf(debug_RBD); 
	/** END DEBUG*/
	dbg("Route", "TTL ends whitout reaching destination%hu.\n", getHeader(msg)->destination);
	return msg;
    }
  }
 
 /*
  * CTP forwarding engine received a data packet, the information in this packet is used to update the routeBack table
  * Once the table has been updated a TRUE is returned to teh CTP forwarding engine and continues its regular operation.
  */
  event bool Intercept.forward[collection_id_t collectid](message_t* msg, void* payload, uint8_t len) {
    /* aqui tengo q leer el mensaje completo y el CTP packet para añadir a la tabla*/
    am_addr_t origin;
    uint8_t Thl;
    error_t error;
    am_addr_t neighbor;
  
    neighbor = call AMPacket.source (msg);
    origin = call CtpPacket.getOrigin(msg);
    Thl = call CtpPacket.getThl(msg);
     
    dbg("RoutingbackTable","%s\n",__FUNCTION__);
    
    if (call RoutebackTable.getbusy()==FALSE){
      call RoutebackTable.setbusy();
      error=call RoutebackTable.routingTableUpdateEntry(origin,neighbor, Thl);
      call RoutebackTable.clearbusy();  
    }
    else
    {
     /* In case of routing talbe update can not be accomplished */      
    }
      
    return TRUE;
  }
  
  event message_t* 
  SubSnoop.receive(message_t* msg, void *payload, uint8_t len) {

    return signal Snoop.receive[call RoutebackPacket.getType(msg)] 
      (msg, payload + sizeof(routeback_header_t), 
       len - sizeof(routeback_header_t));
  }
  
  event void RetxmitTimer.fired() {
    clearState(SENDING);
    dbg("RBHangBug", "%s posted sendTask.\n", __FUNCTION__);
    post sendTask();
  }
  
  void clearState(uint8_t state) {
    forwardingState = forwardingState & ~state;
  }
  
  bool hasState(uint8_t state) {
    return forwardingState & state;
  }
  
  void setState(uint8_t state) {
    forwardingState = forwardingState | state;
  }
  
  /* Returns the index of parent in the table or
   * routingTableActive if not found */
  uint8_t routingTableFind(am_addr_t destination) {
    uint8_t i;
    if (destination == RBD_INVALID_ADDR)
	return routingTableActive;
    for (i = 0; i < routingTableActive; i++) {
	if (routeback_table[i].destination == destination)
	    break;
    }
    return i;
  }
  
  // Packet ADT commands
  command void Packet.clear(message_t* msg) {
    call SubPacket.clear(msg);
  }

  command uint8_t Packet.payloadLength(message_t* msg) {
    return call SubPacket.payloadLength(msg) - sizeof(routeback_header_t);
  }

  command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
    call SubPacket.setPayloadLength(msg, len + sizeof(routeback_header_t));
  }
  
  command uint8_t Packet.maxPayloadLength() {
    return call SubPacket.maxPayloadLength() - sizeof(routeback_header_t);
  }

  command void* Packet.getPayload(message_t* msg, uint8_t len) {
    uint8_t* payload = call SubPacket.getPayload(msg, len + sizeof(routeback_header_t));
    if (payload != NULL) {
      payload += sizeof(routeback_header_t);
    }
    return payload;
  }

  // RoutebackPacket commands
  command am_addr_t    	RoutebackPacket.getDestination(message_t* msg) {return getHeader(msg)->destination;}
  command uint8_t 	RoutebackPacket.getType(message_t* msg) {return getHeader(msg)->type;}
  command uint8_t      	RoutebackPacket.getSequenceNumber(message_t* msg) {return getHeader(msg)->originSeqNo;}
  command void 		RoutebackPacket.setDestination(message_t* msg, am_addr_t addr) {getHeader(msg)->destination = addr;}
  command void 		RoutebackPacket.setType(message_t* msg, routeback_id_t id) {getHeader(msg)->type = id;}
  command void 		RoutebackPacket.setSequenceNumber(message_t* msg, uint8_t _seqno) {getHeader(msg)->originSeqNo = _seqno;}
  command uint8_t      	RoutebackPacket.getTtl(message_t* msg) {return getHeader(msg)->ttl;}
  command void 		RoutebackPacket.setTtl(message_t* msg, uint8_t ttl) {getHeader(msg)->ttl = ttl;}
  
  command bool RoutebackPacket.matchInstance(message_t* m1, message_t* m2) {
    return (call RoutebackPacket.getDestination(m1) == call RoutebackPacket.getDestination(m2) &&
	    call RoutebackPacket.getSequenceNumber(m1) == call RoutebackPacket.getSequenceNumber(m2) &&
	    call RoutebackPacket.getTtl(m1) == call RoutebackPacket.getTtl(m2) &&
	    call RoutebackPacket.getType(m1) == call RoutebackPacket.getType(m2));
  }

  command bool RoutebackPacket.matchPacket(message_t* m1, message_t* m2) {
    return (call RoutebackPacket.getDestination(m1) == call RoutebackPacket.getDestination(m2) &&
	    call RoutebackPacket.getSequenceNumber(m1) == call RoutebackPacket.getSequenceNumber(m2) &&
	    call RoutebackPacket.getType(m1) == call RoutebackPacket.getType(m2));
  }
  

  
  
  command am_addr_t RoutebackTable.hasRoute(am_addr_t destination)
  {
    routingback_table_entry temp;
    uint8_t i;
    for (i=0; i<routingTableSize; i++){
      if (routeback_table[i].destination==destination){
	temp = routeback_table[i]; 
	return (temp.info.neighbor);
      }
    }
    return(RBD_INVALID_ADDR);
  }
  
  command uint8_t RoutebackTable.getHopCount(am_addr_t destination)
  {
    routingback_info_t info;
    uint8_t i;
    for (i=0; i<routingTableSize; i++){
      if (routeback_table[i].destination==destination){
	info = routeback_table[i].info; 
	return (info.hopCount);
      }
    }
    return(0);
  }
  
  command void RoutebackTable.routingTableInit() {
    routingTableActive = 0;
  }

  /*
   * Table update
   * If table full, first element (index 0) is deleted
   * If space available insert new element at the end and incremente the point to the firts free place
   * If destination exist, extract the element, and copy at the end of the table (routingTableActive - 1)
   * But first the following elementes (idx+1 to routingTableActive - 1) are copied to (idx to routingTableActive - 2)
   * 
   */
  command error_t  RoutebackTable.routingTableUpdate(message_t *msg) 
  {
    am_addr_t neighbor;
    am_addr_t origin;
    uint8_t hopCount;
    error_t error;
    
    neighbor = call AMPacket.source (msg);
    origin = call CtpPacket.getOrigin(msg);
    hopCount = call CtpPacket.getThl(msg);
  
     
    if (call RoutebackTable.getbusy() == FALSE)
    {
      call RoutebackTable.setbusy();
      call RoutebackTable.routingTableUpdateEntry(origin, neighbor, hopCount);
      call RoutebackTable.clearbusy();
      return (TRUE);
    }
    
    return (FALSE);
    
  }
  
  command error_t  RoutebackTable.routingTableUpdateEntry(am_addr_t origin, am_addr_t neighbor, uint8_t hopCount)
  {
    uint8_t idx;
    uint8_t idxu;
    error_t error = SUCCESS;
    routingback_table_entry temp;
    idx = routingTableFind(origin);
    
    // If table Full move elements to free the last place and overwrithe the first
    if (idx == routingTableSize) {
      //memmove (routeback_table[0],routeback_table[idx+1], sizeof(routingback_table_entry)*(routingTableActive-1));
      idxu=0;
      error=ENOMEM; 
      /**
	* DEBUG
	*/
	sprintf(debug_RBD,"T.FULL.O%d;N%d", routeback_table[0].destination, origin );
		/** END DEBUG*/  
      // use this error code because looks the most suitable, the element has ben added but maybe in future version other operations can be done
      for (idx=idxu+1; idx<routingTableActive; idx++){
	    routeback_table[idxu]=routeback_table[idx];
	    idxu++;
      }
      idx = routingTableActive;
      /**
	* DEBUG
	*/
      signal DebugPrintf.debugPrintf(debug_RBD); 
      /** END DEBUG*/  
    }
    
    //not found and there is space insert at the end
    if (idx == routingTableActive) {
	  routeback_table[idx].destination = origin;
	  routeback_table[idx].info.neighbor= neighbor;
	  routeback_table[idx].info.hopCount = hopCount;
	  routeback_table[idx].info.routedMsgs = 0;
	  routingTableActive++;
	  dbg("RoutingBackTable", "%s OK, new entry\n", __FUNCTION__);
	
    } else {
	//found, update, move the table in order to have the last used element in the last place in the table
	  //call Leds.led0Toggle();
	  temp=routeback_table[idx];
	  if (temp.info.neighbor != neighbor || temp.info.hopCount != hopCount) 
	  {
	    /**DEBUG
	     * 
	     */
	    sprintf(debug_RBD,"T.UPDT.O%dN%d;O%d,N%d",temp.info.neighbor, neighbor, temp.info.hopCount, hopCount);
	    signal DebugPrintf.debugPrintf(debug_RBD);
	    /**
	     */
	    temp.info.neighbor=neighbor;
	    temp.info.hopCount=hopCount;
	    temp.info.routedMsgs = 0;// if the route changed reset the counter of msgs
	    
	    
	  }
	  else
	    temp.info.routedMsgs ++; 
	  for (idxu=idx+1; idxu<routingTableActive; idxu++){
	    routeback_table[idx]=routeback_table[idxu];
	    idx++;
	  }
	  
	  //memmove (routeback_table[idx],routeback_table[idx+1], sizeof(routingback_table_entry)*(routingTableActive-idx-1));
	  routeback_table[(routingTableActive-1)]=temp;
		  
	  dbg("RoutingBackTable", "%s OK, updated entry\n", __FUNCTION__);
    }
       
    return error;
    }
	 
	 command uint8_t RoutebackTable.getCount()
	 {
		uint8_t idx; 
		idx = routingTableFind(RBD_INVALID_ADDR);
		return (idx);
	 }
	 
	command bool RoutebackTable.getbusy() {return (tablebusy);}
	command void RoutebackTable.setbusy() {tablebusy=TRUE;}
	command void RoutebackTable.clearbusy() {tablebusy=FALSE;}
  
  /******** Defaults. **************/
   
  default event void Send.sendDone[uint8_t client](message_t *msg, error_t error) { }

  default event message_t *
      Receive.receive[routeback_id_t routebackid](message_t *msg, void *payload, uint8_t len) { return msg; }

  default event message_t *
      Snoop.receive[collection_id_t collectid](message_t *msg, void *payload, uint8_t len) { return msg; }
  
  default command routeback_id_t RoutebackId.fetch[uint8_t client]() { return 0;}
   
  default event message_t* RoutebackPacket.forwardingError(message_t* msg) { return msg;}
  
  default event void DebugPrintf.debugPrintf(char* debug) {}
}

