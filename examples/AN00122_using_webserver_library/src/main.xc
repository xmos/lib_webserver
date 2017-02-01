// Copyright (c) 2015-2016, XMOS Ltd, All rights reserved

#include <platform.h>
#include <xs1.h>
#include <print.h>
#include <xtcp.h>
#include <web_server.h>
#include <stdio.h>
#include <string.h>

#include "otp_board_info.h"
#include "ethernet.h"
#include "smi.h"

enum xtcp_clients {
  XTCP_TO_HTTP,
  NUM_XTCP_CLIENTS
};

#if USE_UIP

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

#elif USE_LWIP

// eXplorerKIT RGMII port map
otp_ports_t otp_ports = on tile[0]: OTP_PORTS_INITIALIZER;

rgmii_ports_t rgmii_ports = on tile[1]: RGMII_PORTS_INITIALIZER;

port p_smi_mdio   = on tile[1]: XS1_PORT_1C;
port p_smi_mdc    = on tile[1]: XS1_PORT_1D;
port p_eth_reset  = on tile[1]: XS1_PORT_1N;

// GPIO port declarations
on tile[0] : port p_button = XS1_PORT_4E;
on tile[0] : port p_led = XS1_PORT_4F;

enum eth_clients {
  ETH_TO_XTCP,
  NUM_ETH_CLIENTS
};

enum cfg_clients {
  CFG_TO_XTCP,
  CFG_TO_PHY_DRIVER,
  NUM_CFG_CLIENTS
};

[[combinable]]
void ar8035_phy_driver(client interface smi_if smi,
                client interface ethernet_cfg_if eth) {
  ethernet_link_state_t link_state = ETHERNET_LINK_DOWN;
  ethernet_speed_t link_speed = LINK_1000_MBPS_FULL_DUPLEX;
  const int phy_reset_delay_ms = 1;
  const int link_poll_period_ms = 1000;
  const int phy_address = 0x4;
  timer tmr;
  int t;
  tmr :> t;
  p_eth_reset <: 0;
  delay_milliseconds(phy_reset_delay_ms);
  p_eth_reset <: 1;

  while (smi_phy_is_powered_down(smi, phy_address));
  //smi_configure(smi, phy_address, LINK_1000_MBPS_FULL_DUPLEX, SMI_ENABLE_AUTONEG);
  smi_configure(smi, phy_address, LINK_100_MBPS_FULL_DUPLEX, SMI_ENABLE_AUTONEG);

  while (1) {
    select {
    case tmr when timerafter(t) :> t:
      ethernet_link_state_t new_state = smi_get_link_state(smi, phy_address);
      // Read AR8035 status register bits 15:14 to get the current link speed
      if (new_state == ETHERNET_LINK_UP) {
        link_speed = (ethernet_speed_t)(smi.read_reg(phy_address, 0x11) >> 14) & 3;
      }
      if (new_state != link_state) {
        link_state = new_state;
        eth.set_link_state(0, new_state, link_speed);
      }
      t += link_poll_period_ms * XS1_TIMER_KHZ;
      break;
    }
  }
}

#else
#error "Must define either USE_UIP=1 or USE_LWIP=1"
#endif

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
  return 0;
}

// Maximum number of bytes to receive at once
#define RX_BUFFER_SIZE (1518)

/* Function to handle the HTTP connections (TCP events)
 * from the TCP server task through 'i_xtcp' interface */
void http_handler(client interface xtcp_if i_xtcp) {
  xtcp_connection_t conn;         /* TCP connection information */
  char rx_buffer[RX_BUFFER_SIZE]; /* Buffer for incoming packet */
  unsigned data_len;              /* Length of packet */

  /* Initialize webserver */
  web_server_init(i_xtcp, null, null);
  /* Initialize web application state */
  init_web_state();
  init_gpio();

  while (1) {
    select
    {
      case i_xtcp.packet_ready():
        i_xtcp.get_packet(conn, rx_buffer, RX_BUFFER_SIZE, data_len);
        /* Handles HTTP connections and other TCP events */
        web_server_handle_event(i_xtcp, null, null, conn, rx_buffer);

        /* Event not handled by web_server_handle_event */
        switch(conn.event) {
          case XTCP_IFUP:
            xtcp_ipconfig_t ipconfig;
            i_xtcp.get_ipconfig(ipconfig);

            printstr("IP Address: ");
            printint(ipconfig.ipaddr[0]);printstr(".");
            printint(ipconfig.ipaddr[1]);printstr(".");
            printint(ipconfig.ipaddr[2]);printstr(".");
            printint(ipconfig.ipaddr[3]);printstr("\n");
            break;
          default:
            break;
        }
        break;
    }
  }
}

#define XTCP_MII_BUFSIZE (4096)
#define ETHERNET_SMI_PHY_ADDRESS (0)

int main(void) {
  xtcp_if i_xtcp[NUM_XTCP_CLIENTS];
  smi_if i_smi;

#if USE_UIP
  mii_if i_mii;
#else
  ethernet_cfg_if i_cfg[NUM_CFG_CLIENTS];
  ethernet_rx_if i_rx[NUM_ETH_CLIENTS];
  ethernet_tx_if i_tx[NUM_ETH_CLIENTS];
  streaming chan c_rgmii_cfg;
#endif

  par {
#if USE_UIP
    // MII ethernet driver
    on tile[1]: mii(i_mii, p_eth_rxclk, p_eth_rxerr, p_eth_rxd, p_eth_rxdv,
                    p_eth_txclk, p_eth_txen, p_eth_txd, p_eth_timing,
                    eth_rxclk, eth_txclk, XTCP_MII_BUFSIZE);

    // TCP component
    on tile[1]: xtcp_uip(i_xtcp, NUM_XTCP_CLIENTS, i_mii,
                         null, null, null,
                         i_smi, ETHERNET_SMI_PHY_ADDRESS,
                         null, otp_ports, ipconfig);

#else /* USE_LWIP */
    // RGMII ethernet driver
    on tile[1]: rgmii_ethernet_mac(i_rx, NUM_ETH_CLIENTS,
                                   i_tx, NUM_ETH_CLIENTS,
                                   null, null,
                                   c_rgmii_cfg,
                                   rgmii_ports,
                                   ETHERNET_DISABLE_SHAPER);

    on tile[1].core[0]: rgmii_ethernet_mac_config(i_cfg, NUM_CFG_CLIENTS, c_rgmii_cfg);
    on tile[1].core[0]: ar8035_phy_driver(i_smi, i_cfg[CFG_TO_PHY_DRIVER]);

    // TCP component
    on tile[0]: xtcp_lwip(i_xtcp, NUM_XTCP_CLIENTS, null,
                          i_cfg[CFG_TO_XTCP], i_rx[ETH_TO_XTCP], i_tx[ETH_TO_XTCP],
                          null, ETHERNET_SMI_PHY_ADDRESS,
                          null, otp_ports, ipconfig);

#endif
    // SMI/ethernet phy driver
    on tile[1]: smi(i_smi, p_smi_mdio, p_smi_mdc);

    /* This function runs in a separate core and handles the TCP events
     * i.e the HTTP connections from the above TCP server task
     * through the interface 'i_xtcp[0]'
     */
    on tile[0]: http_handler(i_xtcp[0]);
  }
  return 0;
}