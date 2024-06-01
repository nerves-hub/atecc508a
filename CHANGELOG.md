# Changelog

## v1.3.0

* New features
  * Add ECDH support (Thanks to @sergey-lukianov)

## v1.2.2

This release adds more bulletproofing to the ATECC. If your ATECC is on it's own
I2C bus, these shouldn't be needed. If the ATECC shares an I2C bus with other
devices, communication with other devices could inadvertently wake the ATECC up
(due to it's hold SDA low trigger) and cause it to fall asleep via its watchdog
and unexpected times from this library's point of view.

* Changes
  * Fix potential issue where incorrect responses from the ATECC could be cached.
  * Don't wake the ATECC up for requests that can be satisfied by the cache
  * Retry more kinds of ATECC/I2C failures than just `:watchdog_about_to_expire` ones.

## v1.2.1

* Changes
  * Automatically retry if a request gets a `:watchdog_about_to_expire` error.
    These errors are transient and the code tries to avoid them, but they
    happen, so retry when they do.
  * Allow Circuits.I2C 2.0 to be used by lossening the dependency.

## v1.2.0

* New features
  * Fix warnings for Elixir 1.15. Only Elixir 1.11 and later are supported now.

## v1.1.0

* New features
  * Support for using the Trust & Go variants of the ATECC608B. The Trust & Go
    parts come preloaded with certs and this library knows how to decompress
    them now.

## v1.0.0

This release only updates the version. It has no code changes.

## v0.3.0

* New Features
  * Support signing JWTs for use with the Google Cloud
    Platform's IoT Core MQTT broker. Thanks to Alex McLain for this PR. See
    [Issue 34](https://github.com/nerves-hub/atecc508a/pull/34).
  * Identify the ATECC608B

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
