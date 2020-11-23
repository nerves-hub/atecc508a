# Changelog

## v0.2.3

* Bug fixes
  * Update serial number check to support the longer serial numbers that can be
    made by `nerves_key`.

## v0.2.2

* Bug fixes
  * Retry if waking up the ATECC doesn't work. The current logic retries 4 times
    with a short pause between retries. This works around some transients and
    reduces unnecessary GenServer crash/restarts.

## v0.2.1

* New features
  * Added `ATECC508A.Transport.info/1` to get information about a previously
    created transport.

## v0.2.0

* New features
  * Requests are serialized to each ATECC508A/608A through a dedicated
    GenServer. Two or more users of the library will no longer collide with each
    other on the same chip.
  * Command completion polling. This shortens the wait time for commands with
    long worst case completion times.
  * Response caching. A trivial response cache was implemented that removes the
    need to query the device for duplicate read requests. It's invalidate on any
    write or unknown command. It works well for the intended use cases of
    read-only use of the device normally and mostly write-only use when
    provisioning.
  * Added `ATECC508A.Transport.detected?/1` to poll whether an ATECC508A is
    present.

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
