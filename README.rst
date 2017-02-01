Embedded Webserver Library
==========================

Overview
--------

This software library allows you to generate a webserver that
communicates using the XMOS TCP/IP server component.

Features
........

 * Automatically package a file tree of web pages into data that be
   accessed on the device
 * Store web pages in either program memory or on an attached SPI
   flash
 * Call C/XC functions from within web page templates to access
   dynamic content
 * Handle GET and POST HTTP requests
 * Separate the handling of TCP traffic and the access of flash into
   different tasks passing data over XC channels. Allowing you to
   integrate the webserver in other applications that already handle
   TCP or access flash.

Typical Resource Usage
......................

.. resusage::

  * - configuration: Default
    - globals: xtcp_connection_t conn;
    - locals: interface xtcp_if i; char rx_buffer[1518];
    - fn: {web_server_init(i, null, null);web_server_handle_event(i,null,null,conn, rx_buffer);}
    - pins: 0
    - ports: 0

Note that this does not include the TCP/IP stack (which is a separate
library) or any web-pages stored in memory.

Software version and dependencies
.................................

.. libdeps::

Related application notes
.........................

The following application notes use this library:

  * AN00122 - Using the XMOS embedded webserver library
