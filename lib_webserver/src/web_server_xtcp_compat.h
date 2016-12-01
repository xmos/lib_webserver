// Copyright (c) 2012-2016, XMOS Ltd, All rights reserved
#ifndef _WEB_SERVER_XTCP_COMPAT_H_
#define _WEB_SERVER_XTCP_COMPAT_H_

#include <xccompat.h>
#include <xtcp.h>

/* All functions are merely wrappers for XC interface functions,
 * written to be compatible with C code */ 

void xtcp_close_c(CLIENT_INTERFACE(xtcp_if, i_xtcp),
                  REFERENCE_PARAM(xtcp_connection_t, conn));

void xtcp_set_appstate_c(CLIENT_INTERFACE(xtcp_if, i_xtcp),
                         REFERENCE_PARAM(xtcp_connection_t, conn), 
                         unsigned st);

void xtcp_abort_c(CLIENT_INTERFACE(xtcp_if, i_xtcp), 
                  REFERENCE_PARAM(xtcp_connection_t, conn));

void xtcp_send_c(CLIENT_INTERFACE(xtcp_if, i_xtcp),
                 REFERENCE_PARAM(xtcp_connection_t, conn),
                 char data[], unsigned len);

void xtcp_listen_c(CLIENT_INTERFACE(xtcp_if, i_xtcp),
                   unsigned port_number, xtcp_protocol_t protocol);

#endif /* _WEB_SERVER_XTCP_COMPAT_H_ */