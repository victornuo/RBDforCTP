COMPONENT=RBDdemoRouterAppC

CFLAGS += -I%T/lib/net
CFLAGS += -I%T/lib/net/ctp
#CFLAGS += -I%T/lib/net/lqi
CFLAGS += -I%T/lib/net/rbd
CFLAGS += -I%T/lib/net/4bitle
CFLAGS += -I%T/lib/printf/
CFLAGS += -DNEW_PRINTF_SEMANTICS=250

#test MIG
BUILD_EXTRA_DEPS += DemoLed.class
CLEAN_EXTRA = *.class DemoLedMsg.java

#CFLAGS += -I$(TOSDIR)/lib/T2Hack

DemoLed.class: $(wildcard *.java) DemoLedMsg.java
	javac -target 1.4 -source 1.4 *.java

DemoLedMsg.java:
	mig java -target=null $(CFLAGS) -java-classname=DemoLedMsg demorouter.h demo_led_msg -o $@

#Changes to LPL
#CFLAGS += -I%T/tos/chips/cc2420/lpl
CFLAGS += -DMAX_LPL_CCA_CHECKS=420

CFLAGS += -I.. -I../RBDdemoRouter

#16 nodes
CFLAGS += -DMAX_NODES_RBD=16


#  16 elements
CFLAGS += -DRBD_TABLE_ELEMENTS=16


#CFLAGS += -DLOW_POWER_LISTENING
#CFLAGS += -DLPL_DEF_LOCAL_WAKEUP=0
#CFLAGS += -DLPL_DEF_REMOTE_WAKEUP=512
#CFLAGS += -DDELAY_AFTER_RECEIVE=20


include $(MAKERULES)
