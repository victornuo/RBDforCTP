#ifndef DEMO_ROUTER_H
#define DEMO_ROUTER_H


#ifndef MAX_NODES_RBD
#define MAX_NODES_RBD 2
#endif

#ifndef RBD_MSG_PERIOD_BASE
#define RBD_MSG_PERIOD_BASE 60*1024U
#endif

enum {
  AM_DEMO_LED_MSG = 0x89,
};

typedef nx_struct demo_led_msg{
  nx_uint8_t nodeDest;
  nx_uint8_t value;
} demo_led_msg_t;

#endif
