
/* $Id: DebugPrintf.nc, $ */

/**
 *  Event Generator to send Strings to the main App in oder to launch printf only from the main component 
 * 
 *
 *  @author Victor Rosello
 *  @date   $Date: 2012-09-13 $
 */

#include <AM.h> 

   
interface DebugPrintf {

  event void debugPrintf(char* msg);
  
  
  }