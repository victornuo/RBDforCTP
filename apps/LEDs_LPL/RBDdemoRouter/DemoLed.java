/*									tab:4
 * Copyright (c) 2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

/**
 * Java-side application for testing serial port communication.
 * 
 *
 * @author Phil Levis <pal@cs.berkeley.edu>
 * @date August 12 2005
 */

import java.io.*;
import java.lang.Byte.*;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;


public class DemoLed implements MessageListener {

  private MoteIF moteIF;
  static byte startFlag=0;
  static byte rxFlag=0;
  
  

  public DemoLed(MoteIF moteIF) {
    this.moteIF = moteIF;
    this.moteIF.registerListener(new DemoLedMsg(), this);
  }
  
  public void sendIniPackets() 
  {
	DemoLedMsg payload_A = new DemoLedMsg();
	payload_A.set_value((byte)(0));
	payload_A.set_nodeDest((byte)(0));
	try {
		while (startFlag==0)
		{
			System.out.println("HOLA");
			moteIF.send(0, payload_A);
			try {Thread.sleep(1000);}
			catch (InterruptedException exception) {}
		}
	}
	catch (IOException exception) {
		System.err.println("Exception thrown when sending packets. Exiting.");
		System.err.println(exception);
	}
	
   }
    
    public void sendPackets(DemoLedMsg payload) {
		try {
		moteIF.send(0, payload);
		}
		catch (IOException exception) {
			System.err.println("Exception thrown when sending packets. Exiting.");
			System.err.println(exception);
		}
	}
  
  private static void usage() {
    System.err.println("usage: DemoLed [-comm <source>]");
  }
  
   public void messageReceived(int to, Message message) {
    rxFlag = 1;
    DemoLedMsg msg = (DemoLedMsg)message;
    
    if (msg.get_value() == 1)
		startFlag=1;
    System.out.println("Received from mote Dest:" + msg.get_nodeDest() +", Led Status:" + msg.get_value() + "SF:" +startFlag);
	
  }
  
  public static void main(String[] args) throws Exception {
    try{
    BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
    DemoLedMsg payload = new DemoLedMsg();
    String temp=null;
    String source = null;
    byte destination = 0;
    byte ledstatus = 0; 
    byte option = 1;
    
    
    if (args.length == 2) {
      if (!args[0].equals("-comm")) {
	usage();
	System.exit(1);
      }
      source = args[1];
    }
    else if (args.length != 0) {
      usage();
      System.exit(1);
    }
    
    PhoenixSource phoenix = null;
    
    if (source == null) {
      phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
    }
    else {
     phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);
      
    }
	
	 
    MoteIF mif = new MoteIF(phoenix);
   /* try{
		phoenix.awaitStartup();
		 
		}
		catch(IOException exception){System.err.println(exception);}*/
    DemoLed serial = new DemoLed(mif);
    
    while (rxFlag==0){}      
    
    serial.sendIniPackets();
    System.out.println("ADIOS");
		
   do{
		do{
		System.out.println("Destination Address[0:16]?" );
		temp = br.readLine();
		destination = Byte.parseByte(temp);
		if (destination > 15)   
			System.out.println("Wrong Value" );
		}while (destination > 15);
		
		do{
		System.out.println("Led Status[0:1]?" );
		temp = br.readLine(); 
		ledstatus=Byte.parseByte(temp);
		if (ledstatus > 1)   
			System.out.println("Wrong Value" );
		}while (ledstatus > 1);
		
		
		payload.set_value(ledstatus);
		payload.set_nodeDest(destination);
		
			
		System.out.println("RBD msg to send Destination:" + payload.get_nodeDest() +", Led Status:" + payload.get_value());
		
		serial.sendPackets(payload);
		
		System.out.println("Press [0] to quit or other number to send a new message" );
		temp = br.readLine(); 
		option=Byte.parseByte(temp);
	}while (option != 0 );
		System.exit(0);
	}
	catch(Exception exception){System.err.println(exception); System.exit(-1);}
		
  }


}
