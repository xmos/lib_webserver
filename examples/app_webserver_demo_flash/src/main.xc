// Copyright (c) 2012-2016, XMOS Ltd, All rights reserved

#include <platform.h>
#include <xs1.h>
#include <print.h>
#include <stdio.h>
#include <flash.h>
#include "web_server.h"
#include "web_server_flash.h"
#include "web_page_functions.h"
#include "itoa.h"
#include "smi.h"
#include "mii.h"

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

on tile[0] : fl_SPIPorts flash_ports =
{ PORT_SPI_MISO,
  PORT_SPI_SS,
  PORT_SPI_CLK,
  PORT_SPI_MOSI,
  XS1_CLKBLK_1
};

fl_DeviceSpec flash_devices[] =
  {
    FL_DEVICE_NUMONYX_M25P16,
  };


int get_timer_value(char buf[], int x)
{
  timer tmr;
  unsigned time;
  int len;

  tmr :> time;
  len = itoa(time, buf, 10, 0);
  return len;
}

void tcp_handler(chanend c_xtcp, chanend ?c_flash, fl_SPIPorts &?flash_ports) {
  xtcp_connection_t conn;
  web_server_init(c_xtcp, c_flash, flash_ports);
  init_web_state();
  while (1) {
    select
      {
      case xtcp_event(c_xtcp, conn):
        web_server_handle_event(c_xtcp, c_flash, flash_ports, conn);
        break;
#if SEPARATE_FLASH_TASK
      case web_server_flash_response(c_flash):
        web_server_flash_handler(c_flash, c_xtcp);
        break;
#endif
      }
  }
}

#if SEPARATE_FLASH_TASK
void flash_handler(chanend c_flash) {
  web_server_flash_init(flash_ports);
  while (1) {
    select {
    case web_server_flash(c_flash, flash_ports);
    }
  }
}
#endif

#define XTCP_MII_BUFSIZE (4096)
#define ETHERNET_SMI_PHY_ADDRESS (0)

// Program entry point
int main(void) {
  mii_if i_mii;
  smi_if i_smi;
  chan c_xtcp[1];
#if SEPARATE_FLASH_TASK
  chan c_flash;
#endif

  par {
    // MII/ethernet driver
    on tile[1]: mii(i_mii, p_eth_rxclk, p_eth_rxerr, p_eth_rxd, p_eth_rxdv,
                    p_eth_txclk, p_eth_txen, p_eth_txd, p_eth_timing,
                    eth_rxclk, eth_txclk, XTCP_MII_BUFSIZE);

    // SMI/ethernet phy driver
    on tile[1]: smi(i_smi, p_smi_mdio, p_smi_mdc);

    // TCP component
    on tile[1]: xtcp(c_xtcp, 1, i_mii,
                     null, null, null,
                     i_smi, ETHERNET_SMI_PHY_ADDRESS,
                     null, otp_ports, ipconfig);

    on tile[0]: {
        tcp_handler(c_xtcp[0],
#if SEPARATE_FLASH_TASK
                    c_flash,
                    null
#else
                    null,
                    flash_ports
#endif
                    );
    }

#if SEPARATE_FLASH_TASK
      on tile[0]: flash_handler(c_flash);
#endif

    }
  return 0;
}
