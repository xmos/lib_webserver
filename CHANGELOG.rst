Embedded webserver library change log
=====================================

2.0.1
-----

  * Update to source code license and copyright

2.0.0
-----

  * Rearrange to new file structure
  * Change examples to work with new xtcp and ethernet libraries

  * Changes to dependencies:

    - lib_ethernet: Added dependency 3.0.0

    - lib_gpio: Added dependency 1.0.0

    - lib_locks: Added dependency 2.0.0

    - lib_logging: Added dependency 2.0.0

    - lib_otpinfo: Added dependency 2.0.0

    - lib_xassert: Added dependency 2.0.0

    - lib_xtcp: Added dependency 4.0.0


Legacy release history
----------------------

1.0.3
-----
  * Various documentation updates

  * Changes to dependencies:

    - sc_xtcp: 3.1.3rc0 -> 3.2.1rc0

      + Fixed channel protocol bug that caused crash when xCONNECT is
      + Various documentation updates
      + Fixes to avoid warning in xTIMEcomposer studio version 13.0.0

    - sc_ethernet: 2.2.4rc0 -> 2.3.1rc0

      + Fix invalid inter-frame gaps.
      + Adds AVB-DC support to sc_ethernet
      + Various documentation updates
      + Fixed timing issue in MII rx pins to work across different tools
      + Moved to version 1.0.3 of module_slicekit_support
      + Fixed issue with MII receive buffering that could cause a crash if a packet was dropped

    - sc_slicekit_support: 1.0.3rc0 -> 1.0.4rc0

      + Fix to the metainfo.

    - sc_wifi: 1.0.0rc0 -> 1.1.2rc0

      + Other document updates
      + Document updates conforming to xSOFTip style.
      + Resolve connection to router bug

    - sc_util: 1.0.2rc0 -> 1.0.4rc0

      + module_logging now compiled at -Os
      + debug_printf in module_logging uses a buffer to deliver messages unfragmented
      + Fix thread local storage calculation bug in libtrycatch
      + Fix debug_printf itoa to work for unsigned values > 0x80000000
      + Remove module_slicekit_support (moved to sc_slicekit_support)
      + Update mutual_thread_comm library to avoid communication race conditions

    - sc_spi: 1.3.0rc1 -> 1.4.0rc0

      + Added build option to allow SD card driver compatibility
      + Updated documents
      + Updated documents

1.0.2
-----
  * Update to xtcp v3.1.3

1.0.1
-----
  * Fix content-length handling bug
  * Enable use with WIFI module

1.0.0
-----
  * Initial Version

