
/* $Id: RbdPacket.nc, $ */
/*
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
 * - Neither the name of the nor the names of
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
 *  ADT for RBD data frames.
 *
 *  @author Victor Rosello
 *  @date   $Date: 2012-09-13 $
 */

#include <AM.h> 

#include "Rbd.h"
   
interface RoutebackPacket {

   /**
   * Get the RB group of the RB packet. The RB group is a logical
   * identifier that distinguishes sets of nodes which may share
   * a physical communication medium but wish to not communicate.
   * The RB group logically separates the sets of nodes. When
   * a node sends a packet, it fills in its RB group, and typically
   * nodes only receive packets whose RB group field matches their
   * own.
   *
   * @param 'message_t* msg'  the Routeback packet
   * @return the RB group of this packet
   */
  command uint8_t  getType(message_t* msg);
   
   /**
   * Set the RB group field of a packet. 
   *
   * @param 'message_t* msg'the Routeback packet
   * @param 'routeback_id_t id' the packet's new RB group value
   */
  command void 	 setType(message_t* msg, routeback_id_t id);
  
  /**
   * Get the destinationfiled in the header a Routeback packet
   *
   * @param 'message_t* msg' the Routeback packet
   * @return the address of the destinatio node of the packet
   */
  command am_addr_t getDestination(message_t* msg);
  
  /**
   * Set the destination field in the header a Routeback packet
   *
   * @param 'message_t* msg' the Routeback packet
   * @param 'am_addr_t addr' the packet's new destination value
   */
  command void  setDestination(message_t* msg, am_addr_t addr);
  
   /**
   * Get the sequence number field in the header a Routeback packet
   *
   * @param 'message_t* msg' the Routeback packet
   * @return uint8_t the packet's sequence number value
   */  
  command uint8_t getSequenceNumber(message_t* msg);
  
  /**
   * Set the sequence number field in the header a Routeback packet
   *
   * @param 'message_t* msg' the Routeback packet
   * @param 'uint8_t _seqn' the packet's new  sequence number value
   */   
  command void  setSequenceNumber(message_t* msg, uint8_t _seqn);
  
   /**
   * Get the Time to live (Ttl) field in the header a Routeback packet
   *
   * @param 'message_t* msg' the Routeback packet
   * @return the packet's Time to live value
   */  
  command uint8_t getTtl(message_t* msg);
 
   /**
   * Set the ttl field in the header a Routeback packet
   *
   * @param 'message_t* msg' the Routeback packet
   * @param 'uint8_t ttl'the  packet's new Time to live value
   */ 
  command void setTtl(message_t* msg, uint8_t ttl);
  
   /**
   * Compare two msg
   *
   * @param 'message_t* m1' the msg1
   * @param 'message_t* m2' the msg2
   * @return TRUE if the are the same
   */  
  command bool  matchInstance(message_t* m1, message_t* m2);
   
  /**
   * Compare two msg
   *
   * @param 'message_t* m1' the packet1
   * @param 'message_t* m2' the packet2
   * @return TRUE if the are the same
   */     
  command bool 	matchPacket(message_t* m1, message_t* m2);
  
   /**
   * Signals an error happened while trying to send a routeback message
   *
   * @param 'message_t* msg' Rbd packet that can not be sent
   * @return packet that was not sended
   */     
  event message_t* forwardingError(message_t* msg);
  
  
  }