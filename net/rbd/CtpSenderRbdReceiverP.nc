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

#include <Collection.h>
#include <Rbd.h>

generic configuration 
CtpSenderRbdReceiverP(collection_id_t collectid, routeback_id_t routebackid, uint8_t clientidCtp){ 
// Cambios realizados el 27 jun 2013, se quita --> uint8_t clientidRbd de la cabecera {
  provides {
    interface Send as CtpSend;
    interface Receive as RbdReceive;
    interface Packet as Packet_Ctp;
    interface Packet as Packet_Rbd;
  }  
}

implementation {
  components CollectionC as Collector;
  components RoutebackC as Forwarder;
  components new CollectionIdP(collectid);
  //components new RoutebackIdP(routebackid); 
  
  CtpSend = Collector.Send[clientidCtp];
  Collector.CollectionId[clientidCtp] -> CollectionIdP;
  /**
   * Cambios realizados el 27 jun 2013
   */
  /*RbdReceive = Forwarder.Receive[clientidRbd]; 
  Forwarder.RoutebackId[clientidRbd] -> RoutebackIdP;*/
  Packet_Ctp = Collector.Packet;
  Packet_Rbd=Forwarder.Packet;
  RbdReceive = Forwarder.Receive[routebackid];
  Forwarder.Intercept->Collector.Intercept;
  Forwarder.CtpPacket->Collector.CtpPacket;
     
}