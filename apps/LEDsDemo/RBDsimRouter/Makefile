COMPONENT=RBDsimRouterAppC

CFLAGS += -I%T/lib/net
CFLAGS += -I%T/lib/net/ctp
#CFLAGS += -I%T/lib/net/lqi
CFLAGS += -I%T/lib/net/rbd
CFLAGS += -I%T/lib/net/4bitle
CFLAGS += -I%T/lib/printf/
#CFLAGS += -DNEW_PRINTF_SEMANTICS=250


#CFLAGS += -I$(TOSDIR)/lib/T2Hack

#Changes to LPL
#CFLAGS += -I%T/tos/chips/cc2420/lpl
CFLAGS += -DMAX_LPL_CCA_CHECKS=420

CFLAGS += -I.. -I../RBDsimRouter

#3 nodes
CFLAGS += -DMAX_NODES_RBD=3


# 10 elements
CFLAGS += -DRBD_TABLE_ELEMENTS=10


#CFLAGS += -DLOW_POWER_LISTENING
#CFLAGS += -DLPL_DEF_LOCAL_WAKEUP=0
#CFLAGS += -DLPL_DEF_REMOTE_WAKEUP=512
#CFLAGS += -DDELAY_AFTER_RECEIVE=20


include $(MAKERULES)
