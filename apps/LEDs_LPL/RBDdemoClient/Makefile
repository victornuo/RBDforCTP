COMPONENT=RBDdemoClientAppC

CFLAGS += -I%T/lib/net
CFLAGS += -I%T/lib/net/ctp
#CFLAGS += -I%T/lib/net/lqi
CFLAGS += -I%T/lib/net/rbd
CFLAGS += -I%T/lib/net/4bitle
CFLAGS += -I%T/lib/printf/
CFLAGS += -DNEW_PRINTF_SEMANTICS=250

#LPL changes
CFLAGS += -DMAX_LPL_CCA_CHECKS=420


CFLAGS += -I.. -I../RBDdemoClient

#Application parameters

CFLAGS += -DCTP_MSG_PERIOD_BASE=6144
CFLAGS += -DRBD_TABLE_ELEMENTS=16

CFLAGS += -DLOW_POWER_LISTENING
CFLAGS += -DLPL_DEF_LOCAL_WAKEUP=512
CFLAGS += -DLPL_DEF_REMOTE_WAKEUP=512
CFLAGS += -DDELAY_AFTER_RECEIVE=20

include $(MAKERULES)
