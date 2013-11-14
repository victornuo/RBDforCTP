
/* $Id: RoutebackTable.nc */
/*
 * Copyright (c) 2006 Stanford University.
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
 *  ADT for Handle the RoutebackTable.
 *
 *  @author Victor Rosello
 *  @date   $Date: 2012-09-13 $
 */

#include "Rbd.h"
   
interface RoutebackTable {
  /**
   * Updates or creates a new route in the routebackTable.
   * @param 'am_addr_t destination' final destination adress of the route to update
   * @param 'am_addr_t neighbor' address of teh nex node in the path to the destination
   * @param 'uint8_t Ttl' remaininf time to live before arriving to destination
   * @return error_t SUCCESS if no error.
   */
  command error_t routingTableUpdateEntry(am_addr_t destination, am_addr_t neighbor, uint8_t Ttl);
  
  /**
   * Updates or creates a new route in the routebackTable by using a Ctp data packet as input paramenter
   *
   * @param 'message_t* msg' the Ctp packet where the route date will be get
   * @return 'error_t' SUCCESS if no error.
   */
  command error_t routingTableUpdate(message_t *msg);
  
  /**
   * Get the AM group of the AM packet. The AM group is a logical
   * identifier that distinguishes sets of nodes which may share
   * a physical communication medium but wish to not communicate.
   * The AM group logically separates the sets of nodes. When
   * a node sends a packet, it fills in its AM group, and typically
   * nodes only receive packets whose AM group field matches their
   * own.
   *
   * @param 'am_addr_t destination' final adress of the packet 
   * @return am_addr_t next hope node adress is route exist.
   */
  command am_addr_t hasRoute(am_addr_t destination);
  
  /**
   * Initialices the routebackTable
   *
   */
  command void routingTableInit();
  
  /**
   * Retunrs the free space in the RoutebackTable
   *
   
   * @return free space in the RoutebackTable
   */
  command uint8_t getCount();
  
  /**
   * Get the hop count of a route. this parameter is sent in Ttl header of a routeback packet
   *
   * @param 'am_addr_t destination' the packet
   * @return the Time to live of the destiantion's route
   */
  command uint8_t getHopCount(am_addr_t destination);
  
  /**
   * Get the busy flag of the routing table, 
   * just in case other module is trying to access the table at the same time
   */
  command bool getbusy();
  
 /**
   * Set the busy flag to TRUE of the routing table, 
   * it must be done before calling the update Function
   */
  command void setbusy();
  
  /**
   * * Set the busy flag to FALSE of the routing table, 
   * it must be done after calling the update Function
   * 
   */
  command void clearbusy();
    
  
  }
