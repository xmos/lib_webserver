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

