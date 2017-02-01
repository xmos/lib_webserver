// Copyright (c) 2012-2016, XMOS Ltd, All rights reserved
#include <xccompat.h>
#include <xtcp.h>

void xtcp_close_c(CLIENT_INTERFACE(xtcp_if, i_xtcp),
                  REFERENCE_PARAM(xtcp_connection_t, conn))
{
  i_xtcp.close(conn);
}

void xtcp_set_appstate_c(CLIENT_INTERFACE(xtcp_if, i_xtcp),
                         REFERENCE_PARAM(xtcp_connection_t, conn), 
                         unsigned st)
{
  i_xtcp.set_appstate(conn, st);
}

void xtcp_abort_c(CLIENT_INTERFACE(xtcp_if, i_xtcp), 
                  REFERENCE_PARAM(xtcp_connection_t, conn))
{
  i_xtcp.abort(conn);
}

void xtcp_send_c(CLIENT_INTERFACE(xtcp_if, i_xtcp),
                 REFERENCE_PARAM(xtcp_connection_t, conn),
                 char data[], unsigned len)
{
  i_xtcp.send(conn, data, len);
}

void xtcp_listen_c(CLIENT_INTERFACE(xtcp_if, i_xtcp),
                   unsigned port_number, xtcp_protocol_t protocol)
{
  i_xtcp.listen(port_number, protocol);
}