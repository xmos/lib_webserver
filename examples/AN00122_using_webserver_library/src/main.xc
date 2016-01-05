// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include <platform.h>
#include <xs1.h>
#include <print.h>
#include <xtcp.h>
#include <web_server.h>
#include <stdio.h>
#include <string.h>


// Here are the port definitions required by ethernet. This port assignment
// is for the L16 sliceKIT with the ethernet slice plugged into the
// CIRCLE slot.
port p_eth_rxclk  = on tile[1]: XS1_PORT_1J;
port p_eth_rxd    = on tile[1]: XS1_PORT_4E;
port p_eth_txd    = on tile[1]: XS1_PORT_4F;
port p_eth_rxdv   = on tile[1]: XS1_PORT_1K;
port p_eth_txen   = on tile[1]: XS1_PORT_1L;
port p_eth_txclk  = on tile[1]: XS1_PORT_1I;
port p_eth_int    = on tile[1]: XS1_PORT_1O;
port p_eth_rxerr  = on tile[1]: XS1_PORT_1P;
port p_eth_timing = on tile[1]: XS1_PORT_8C;

clock eth_rxclk   = on tile[1]: XS1_CLKBLK_1;
clock eth_txclk   = on tile[1]: XS1_CLKBLK_2;

port p_smi_mdio = on tile[1]: XS1_PORT_1M;
port p_smi_mdc  = on tile[1]: XS1_PORT_1N;

// These ports are for accessing the OTP memory
otp_ports_t otp_ports = on tile[1]: OTP_PORTS_INITIALIZER;

/* GPIO slice on triangle slot
 * PORT_4E connected to the 4 LEDs and PORT_8D connected to 2 buttons */
on tile[0]: port p_led=XS1_PORT_4E;
on tile[0]: port p_button=XS1_PORT_8D;


/* IP configuration.
 * Change this to suit your network.
 * Leave all as 0 values to use DHCP */
xtcp_ipconfig_t ipconfig = {
  { 0, 0, 0, 0 }, // IP address (eg 192,168,0,2)
  { 0, 0, 0, 0 }, // Netmask (eg 255,255,255,0)
  { 0, 0, 0, 0 }  // Gateway (eg 192,168,0,1)
};

/* Function to get 32-bit timer value as a string */
int get_timer_value(char buf[])
{
  /* Declare a timer resource */
  timer tmr;
  unsigned time;
  int len;
  /* Read the timer value in a variable */
  tmr :> time;
  /* Convert the timer value to string */
  sprintf(buf, "%u", time);
  return len;
}

/* Function to initialize the GPIO */
void init_gpio(void)
{
  /* Set all LEDs to OFF (Active low)*/
  p_led <: 0x0F;
}

/* Function to set LED state - ON/OFF */
void set_led_state(int led_id, int val)
{
  int value;
  /* Read port value into a variable */
  p_led :> value;
  if (!val) {
      p_led <: (value | (1 << led_id));
  } else {
      p_led <: (value & ~(1 << led_id));
  }
}

/* Function to read current button state */
int get_button_state(int button_id)
{
  int value;
  p_button :> value;
  value &= (1 << button_id);
  return (value >> button_id);
}

/* Function to handle the HTTP connections (TCP events)
 * from the TCP server task through 'c_xtcp' channels */
void http_handler(chanend c_xtcp) {

  xtcp_connection_t conn;  /* TCP connection information */

  /* Initialize webserver */
  web_server_init(c_xtcp, null, null);
  /* Initialize web application state */
  init_web_state();
  init_gpio();

  while (1) {
    select
      {
      case xtcp_event(c_xtcp,conn):
        /* Handles HTTP connections and other TCP events */
        web_server_handle_event(c_xtcp, null, null, conn);
        break;
      }
  }
}

#define XTCP_MII_BUFSIZE (4096)
#define ETHERNET_SMI_PHY_ADDRESS (0)


/* The main starts four tasks (functions) in three different logical cores. */
int main(void) {
  chan c_xtcp[1];
  mii_if i_mii;
  smi_if i_smi;
  par {
    // MII/ethernet driver
    on tile[1]: mii(i_mii, p_eth_rxclk, p_eth_rxerr, p_eth_rxd, p_eth_rxdv,
                    p_eth_txclk, p_eth_txen, p_eth_txd, p_eth_timing,
                    eth_rxclk, eth_txclk, XTCP_MII_BUFSIZE)

    // SMI/ethernet phy driver
    on tile[1]: smi(i_smi, p_smi_mdio, p_smi_mdc);

    // TCP component
    on tile[1]: xtcp(c_xtcp, 1, i_mii,
                     null, null, null,
                     i_smi, ETHERNET_SMI_PHY_ADDRESS,
                     null, otp_ports, ipconfig);
    /* This function runs in a separate core and handles the TCP events
     * i.e the HTTP connections from the above TCP server task
     * through the channel 'c_xtcp[0]'
     */
    on tile[0]: http_handler(c_xtcp[0]);

  }
  return 0;
}
