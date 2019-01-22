# Changelog

## v0.1.3

* Enhancements
  * Reduce debug logging

## v0.1.2

* Bug fixes
  * Add support for generalized time to support certificates that expire after
    12/31/2049.
  * Force ATECC508A to sleep on init so that it's in a known state for the first
    request

## v0.1.1

* Enhancements / bug fixes
  * Add support to lock individual slots. This fixes an issue where the private
    key slot could be regenerated.

## v0.1.0

Initial release
