/*
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
 * - Neither the name of the   nor the names of
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
 * A routeback  service that uses a tree routing protocol
 * to create routes from roots to distant nodes, based on the CTP of TEP 119.
 *
 * @author Victor Rosello
 */

configuration RbdP {
  provides {
    interface StdControl;
    interface Send[uint8_t client];
    interface Receive[routeback_id_t id];
    interface Receive as Snoop[routeback_id_t];

    interface Packet;
    interface RoutebackPacket;
    interface RoutebackTable;
      /**
     * Pa printfear desde la aplicacion principal
     */
    interface DebugPrintf;
        
  }

  uses {
    interface Intercept[collection_id_t id];
    interface RoutebackId[uint8_t client];
    interface CtpPacket;
    //interface RootControl;
 }
}

implementation {
  enum {
    RBD_CLIENT_COUNT = uniqueCount(UQ_RBD_CLIENT),
    RBD_FORWARD_COUNT = 10,
    ROUTEBACK_TABLE_SIZE = RBD_TABLE_ELEMENTS,
    RBD_QUEUE_SIZE = RBD_CLIENT_COUNT + RBD_FORWARD_COUNT,
    //RBD_CACHE_SIZE = 4,
  };

  components ActiveMessageC;
  components new RoutebackDeliveryP(ROUTEBACK_TABLE_SIZE) as RbdForwarder;
  
  components new AMSnooperC(AM_RBD_DATA);
  
  components MainC, LedsC;
  
  //RootControl=RbdForwarder.RootControl;
  RoutebackTable=RbdForwarder.RoutebackTable;
  Send = RbdForwarder.Send;
  StdControl = RbdForwarder;
  Receive = RbdForwarder.Receive;
  Snoop = RbdForwarder.Snoop;
  Intercept = RbdForwarder;
  Packet = RbdForwarder;
  RoutebackId = RbdForwarder;
  CtpPacket = RbdForwarder;
  RoutebackPacket= RbdForwarder;
  RbdForwarder.SubSnoop -> AMSnooperC;
  
   /**
     * Pa printfear desde la aplicacion principal
     */
  DebugPrintf=RbdForwarder.DebugPrintf;
  
  components new PoolC(message_t, RBD_FORWARD_COUNT) as MessagePoolP;
  components new PoolC(rb_queue_entry_t, RBD_FORWARD_COUNT) as QEntryPoolP;
  
  RbdForwarder.QEntryPool -> QEntryPoolP;
  RbdForwarder.MessagePool -> MessagePoolP;

  components new QueueC(rb_queue_entry_t*, RBD_QUEUE_SIZE) as SendQueueP;
  RbdForwarder.SendQueue -> SendQueueP;

  //components new LruCtpMsgCacheC(RBD_CACHE_SIZE) as SentCacheP;
  //RbdForwarder.SentCache -> SentCacheP;

  //components new TimerMilliC() as RoutingBeaconTimer;
 // components new TimerMilliC() as RouteUpdateTimer;
  //components LinkEstimatorP as Estimator;
  //RbdForwarder.LinkEstimator -> Estimator;

  components new AMSenderC(AM_RBD_DATA);
  components new AMReceiverC(AM_RBD_DATA);
//  components new AMSnooperC(AM_CTP_DATA);

  //components new CtpRoutingEngineP(TREE_ROUTING_TABLE_SIZE, 128, 512000) as Router;

  components new TimerMilliC() as RetxmitTimer;
  RbdForwarder.RetxmitTimer -> RetxmitTimer;

  components RandomC;
  RbdForwarder.Random -> RandomC;

  MainC.SoftwareInit -> RbdForwarder;
  RbdForwarder.SubSend -> AMSenderC;
  RbdForwarder.SubReceive -> AMReceiverC;
//  RbdForwarder.SubSnoop -> AMSnooperC;
  RbdForwarder.SubPacket -> AMSenderC;
  //RbdForwarder.RootControl -> Router;
  //RbdForwarder.UnicastNameFreeRouting -> Router.Routing;
  RbdForwarder.RadioControl -> ActiveMessageC;
  RbdForwarder.PacketAcknowledgements -> AMSenderC.Acks;
  RbdForwarder.AMPacket -> AMSenderC;
  RbdForwarder.Leds -> LedsC;
  
  #if defined(CC2420X)
  components CC2420XActiveMessageC as PlatformActiveMessageC;
#elif defined(PLATFORM_TELOSB) || defined(PLATFORM_MICAZ)
#ifndef TOSSIM
  components CC2420ActiveMessageC as PlatformActiveMessageC;
#else
  components DummyActiveMessageP as PlatformActiveMessageC;
#endif
#elif defined (PLATFORM_MICA2) || defined (PLATFORM_MICA2DOT)
  components CC1000ActiveMessageC as PlatformActiveMessageC;
#elif defined(PLATFORM_EYESIFXV1) || defined(PLATFORM_EYESIFXV2)
  components WhiteBitAccessorC as PlatformActiveMessageC;
#elif defined(PLATFORM_IRIS) || defined(PLATFORM_MESHBEAN)
  components RF230ActiveMessageC as PlatformActiveMessageC;
#elif defined(PLATFORM_MESHBEAN900)
  components RF212ActiveMessageC as PlatformActiveMessageC;
#elif defined(PLATFORM_UCMINI)
  components RFA1ActiveMessageC as PlatformActiveMessageC;
#else
  components DummyActiveMessageP as PlatformActiveMessageC;
#endif

}
