Using the XMOS embedded webserver library
=========================================

.. version:: 1.0.0

Summary
-------

This application note shows how to use XMOS webserver library to run
an embedded webserver on an XMOS multicore microcontroller.

The code associated with the application note provides an example of
using the XMOS HTTP Webserver library and
the XMOS TCP/IP library to build an embedded webserver that hosts web
pages. This example application relies on an Ethernet interface for
the lower layer communication.

The HTTP Webserver library handles HTTP connections like GET and POST
request methods, creates dynamic web page content and handles HTML
pages as a file system stored in program memory or an external SPI
flash memory device. The Webserver running on an xCORE device can be
visited from a standard web browser of a computer that is connected to
the same network to which the Ethernet interface of the xCORE
development board is connected.

Embedding a web server onto XMOS multicore microcontrollers adds very
flexible and easy-to-use management capabilities to your embedded
systems.


Required tools and libraries
............................

* xTIMEcomposer Tools - Version 13.1
* XMOS Embedded Webserver Library - Version 2.0.0
* XMOS TCP/IP Library - Version 4.0.0
* XMOS Ethernet Library - Version 3.0.0

Required hardware
.................

This application note is designed to run on any XMOS xCORE device.

The example code provided with this application note has been implemented and tested 
on the SliceKIT Core Board (XP-SKC-L2) with Ethernet Slice (XA-SK-E100) and GPIO Slice (XA-SK-GPIO) but there is no dependency on these boards and it can be modified to run on any development board which has an xCORE device connected to an Ethernet PHY device through an MII
(Media Independent Interface) interface.

Prerequisites
.............

  - This document assumes familiarity with the XMOS xCORE architecture, the HTTP protocol, HTML, Webserver, the XMOS tool chain and the xC language. Documentation related to these aspects which are not specific to this application note are linked to in the reference appendix.

  - For descriptions of XMOS related terms found in this document please see the XMOS Glossary (http://www.xmos.com/published/glossary).

  - For the full API listing of the XMOS HTTP Webserver library please see the document Embedded Webserver Library Programming Guide.

    (https://www.xmos.com/published/embedded-webserver-library-programming-guide)
