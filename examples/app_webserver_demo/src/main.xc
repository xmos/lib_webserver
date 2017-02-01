// Copyright (c) 2015-2016, XMOS Ltd, All rights reserved
#include <platform.h>
#include <print.h>
#include "xtcp.h"
#include "smi.h"
#include "otp_board_info.h"
#include "web_server.h"
#include "itoa.h"

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

port p_smi_mdc = on tile[1]: XS1_PORT_1N;
port p_smi_mdio = on tile[1]: XS1_PORT_1M;

otp_ports_t otp_ports = on tile[1]: OTP_PORTS_INITIALIZER;

// IP Config - change this to suit your network.  Leave with all
// 0 values to use DHCP
xtcp_ipconfig_t ipconfig = {
  { 0, 0, 0, 0 }, // ip address (eg 192,168,0,2)
  { 0, 0, 0, 0 }, // netmask (eg 255,255,255,0)
  { 0, 0, 0, 0 }  // gateway (eg 192,168,0,1)
};

// Maximum number of bytes to receive at once
#define RX_BUFFER_SIZE (1518)
#define XTCP_MII_BUFSIZE (4096)
#define ETHERNET_SMI_PHY_ADDRESS (0)

int get_timer_value(char buf[], int x)
{
  timer tmr;
  unsigned time;
  int len;
  tmr :> time;
  len = itoa(time, buf, 10, 0);
  return len;
}

void tcp_handler(client interface xtcp_if i_xtcp) {
  xtcp_connection_t conn;
  char rx_buffer[RX_BUFFER_SIZE];
  unsigned data_len;

  web_server_init(i_xtcp, null, null);
  init_web_state();

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

int main(void) {
  xtcp_if i_xtcp[1];
  mii_if i_mii;
  smi_if i_smi;
  par {

    // MII/ethernet driver
    on tile[1]: mii(i_mii, p_eth_rxclk, p_eth_rxerr, p_eth_rxd, p_eth_rxdv,
                    p_eth_txclk, p_eth_txen, p_eth_txd, p_eth_timing,
                    eth_rxclk, eth_txclk, XTCP_MII_BUFSIZE);

    // SMI/ethernet phy driver
    on tile[1]: smi(i_smi, p_smi_mdio, p_smi_mdc);

    // TCP component
    on tile[1]: xtcp_uip(i_xtcp, 1, i_mii,
                         null, null, null,
                         i_smi, ETHERNET_SMI_PHY_ADDRESS,
                         null, otp_ports, ipconfig);

    // HTTP server application
    on tile[0]: tcp_handler(i_xtcp[0]);

  }
  return 0;
}
